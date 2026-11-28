"""Validate and upsert lesson JSON files into PostgreSQL.

    cd nhom11-65ktpm/src/server
    python -m scripts.load_content
    python -m scripts.load_content --data-dir ../../data/lessons
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_session_factory
from app.models.content import Course, Lesson, Word
from app.schemas.content import LessonContent

DATA_DIR = Path(__file__).resolve().parents[3] / "data" / "lessons"

COURSE_META: dict[str, tuple[str, str, int]] = {
    "PINYIN": ("Pinyin", "Khóa học nền tảng phát âm tiếng Trung.", 0),
    "HSK1": ("HSK 1", "Giáo trình HSK cấp 1 và các mẫu câu cơ bản.", 1),
    "HSK2": ("HSK 2", "Giáo trình HSK cấp 2 và các mẫu câu cơ bản.", 2),
}


def read_lesson_files(data_dir: Path = DATA_DIR) -> list[LessonContent]:
    """Read and Pydantic-validate every lesson JSON file before touching the database."""
    files = sorted(data_dir.glob("**/lesson-*.json"))
    if not files:
        raise ValueError(f"Không tìm thấy file lesson-*.json trong {data_dir}")

    lessons: list[LessonContent] = []
    seen_codes: set[str] = set()
    seen_orders: set[tuple[str, int]] = set()
    for path in files:
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ValueError(f"{path}: không đọc được JSON: {exc}") from exc

        try:
            lesson = LessonContent.model_validate(raw)
        except ValidationError as exc:
            raise ValueError(f"{path}: dữ liệu bài học không hợp lệ:\n{exc}") from exc

        if lesson.id in seen_codes:
            raise ValueError(f"{path}: mã bài học '{lesson.id}' bị trùng")
        seen_codes.add(lesson.id)

        order_key = (lesson.level, lesson.order)
        if order_key in seen_orders:
            raise ValueError(
                f"{path}: thứ tự bài học order={lesson.order} bị trùng trong cấp {lesson.level}"
            )
        seen_orders.add(order_key)
        lessons.append(lesson)

    return sorted(
        lessons,
        key=lambda item: (COURSE_META.get(item.level, ("", "", 99))[2], item.order, item.id),
    )


def _topics_by_level(specs: list[LessonContent]) -> dict[str, list[str]]:
    topics_by_level: dict[str, list[str]] = {}
    for spec in specs:
        if spec.topic:
            topics = topics_by_level.setdefault(spec.level, [])
            if spec.topic not in topics:
                topics.append(spec.topic)
    return topics_by_level


def _upsert_course(
    db: Session,
    level: str,
    topics: list[str],
) -> Course:
    course = db.scalar(select(Course).where(Course.code == level))
    title, default_desc, order_index = COURSE_META.get(level, (level, f"Khóa học {level}.", 99))
    if course is None:
        course = Course(code=level, title=title)
        db.add(course)
    course.title = title
    course.description = (
        f"Từ vựng sơ cấp theo chủ đề: {', '.join(topics)}." if topics else default_desc
    )
    course.order_index = order_index
    db.flush()
    return course


def _upsert_lesson(db: Session, course: Course, spec: LessonContent) -> Lesson:
    lesson = db.scalar(select(Lesson).where(Lesson.code == spec.id))
    if lesson is None:
        lesson = Lesson(code=spec.id, course_id=course.id)
        db.add(lesson)
    lesson.course_id = course.id
    lesson.order_index = spec.order
    lesson.title = spec.title
    lesson.description = spec.description
    lesson.topic = spec.topic
    lesson.grammar_points = [
        point.model_dump(by_alias=True) for point in spec.grammar_points
    ]
    lesson.ai_scenario = spec.ai_scenario.model_dump(by_alias=True)
    lesson.schema_version = spec.schema_version
    lesson.content_version = spec.content_version
    db.flush()

    existing_words = {word.code: word for word in lesson.words}
    wanted_word_ids = {word.id for word in spec.vocabulary}
    hsk_level = int(spec.level[3:]) if spec.level.startswith("HSK") and spec.level[3:].isdigit() else None

    for stale_code in existing_words.keys() - wanted_word_ids:
        lesson.words.remove(existing_words[stale_code])

    for order_index, word_spec in enumerate(spec.vocabulary):
        word = existing_words.get(word_spec.id)
        if word is None:
            word = Word(lesson_id=lesson.id, code=word_spec.id)
            lesson.words.append(word)
        word.order_index = order_index
        word.hanzi = word_spec.hanzi
        word.pinyin = word_spec.pinyin
        word.han_viet = word_spec.han_viet
        word.meaning_vi = word_spec.meaning_vi
        word.example = (
            word_spec.example.model_dump(by_alias=True)
            if word_spec.example is not None
            else None
        )
        word.hsk_level = hsk_level
        word.content_version = spec.content_version

    return lesson


def load_content(db: Session, data_dir: Path = DATA_DIR) -> list[Lesson]:
    """Validate all lesson JSON files, then idempotently upsert courses, lessons, and words."""
    specs = read_lesson_files(data_dir)
    topics_by_level = _topics_by_level(specs)
    courses: dict[str, Course] = {}
    lessons: list[Lesson] = []

    for spec in specs:
        course = courses.get(spec.level)
        if course is None:
            course = _upsert_course(db, spec.level, topics_by_level.get(spec.level, []))
            courses[spec.level] = course
        lessons.append(_upsert_lesson(db, course, spec))

    db.flush()
    return lessons


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Nạp nội dung bài học từ file JSON.")
    parser.add_argument("--data-dir", type=Path, default=DATA_DIR)
    args = parser.parse_args(argv)

    try:
        with get_session_factory()() as db:
            lessons = load_content(db, args.data_dir)
            db.commit()
    except ValueError as exc:
        print(f"Lỗi kiểm tra dữ liệu bài học: {exc}", file=sys.stderr)
        return 1

    word_count = sum(len(lesson.words) for lesson in lessons)
    print(f"Đã nạp {len(lessons)} bài học ({word_count} từ vựng) từ {args.data_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
