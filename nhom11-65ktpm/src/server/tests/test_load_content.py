import json
import shutil
from pathlib import Path

import pytest
from sqlalchemy import func, select

from app.models.content import Course, Lesson, Word
from scripts.load_content import DATA_DIR, _default_data_dir, load_content, read_lesson_files


def _copy_lessons(target: Path) -> Path:
    data_dir = target / "lessons"
    shutil.copytree(DATA_DIR, data_dir)
    return data_dir


def test_default_data_dir_uses_lessons_data_dir_environment(monkeypatch, tmp_path):
    monkeypatch.setenv("LESSONS_DATA_DIR", str(tmp_path))

    assert _default_data_dir() == tmp_path


def test_load_content_is_idempotent_and_updates_version_and_words(db_session, tmp_path):
    data_dir = _copy_lessons(tmp_path)
    expected_specs = read_lesson_files(data_dir)
    expected_levels = {spec.level for spec in expected_specs}

    first_load = load_content(db_session, data_dir)
    db_session.commit()
    initial_word_count = db_session.scalar(select(func.count()).select_from(Word))
    assert len(first_load) == len(expected_specs)
    assert db_session.scalar(select(func.count()).select_from(Course)) == len(expected_levels)

    target_file = data_dir / "hsk1" / "lesson-01.json"
    updated_json = json.loads(target_file.read_text(encoding="utf-8"))
    updated_json["contentVersion"] = 2
    updated_json["vocabulary"].pop()
    target_file.write_text(json.dumps(updated_json, ensure_ascii=False), encoding="utf-8")

    load_content(db_session, data_dir)
    db_session.commit()
    load_content(db_session, data_dir)
    db_session.commit()

    assert db_session.scalar(select(func.count()).select_from(Lesson)) == len(expected_specs)
    assert db_session.scalar(select(func.count()).select_from(Word)) == initial_word_count - 1
    assert (
        db_session.scalar(
            select(Lesson.content_version).where(Lesson.code == "hsk1-greetings-01")
        )
        == 2
    )
    assert (
        db_session.scalar(
            select(Lesson.content_version).where(Lesson.code == "hsk1-family-02")
        )
        == 1
    )


def test_load_content_rejects_invalid_schema_before_database_changes(db_session, tmp_path):
    data_dir = _copy_lessons(tmp_path)
    invalid_file = data_dir / "hsk1" / "lesson-01.json"
    content = json.loads(invalid_file.read_text(encoding="utf-8"))
    content["vocabulary"][0]["meaningVi"] = ""
    invalid_file.write_text(json.dumps(content, ensure_ascii=False), encoding="utf-8")

    with pytest.raises(ValueError, match="dữ liệu bài học không hợp lệ"):
        load_content(db_session, data_dir)

    assert db_session.scalar(select(func.count()).select_from(Course)) == 0
    assert db_session.scalar(select(func.count()).select_from(Lesson)) == 0


def test_load_content_rejects_malformed_json_and_duplicates(db_session, tmp_path):
    data_dir = _copy_lessons(tmp_path)
    bad_json_file = data_dir / "hsk1" / "lesson-02.json"
    bad_json_file.write_text("{not valid json", encoding="utf-8")

    with pytest.raises(ValueError, match="không đọc được JSON"):
        load_content(db_session, data_dir)

    assert db_session.scalar(select(func.count()).select_from(Lesson)) == 0

    data_dir_dup = _copy_lessons(tmp_path / "dup")
    lesson_1 = json.loads((data_dir_dup / "hsk1" / "lesson-01.json").read_text(encoding="utf-8"))
    lesson_2_path = data_dir_dup / "hsk1" / "lesson-02.json"
    lesson_2 = json.loads(lesson_2_path.read_text(encoding="utf-8"))
    lesson_2["id"] = lesson_1["id"]
    lesson_2_path.write_text(json.dumps(lesson_2, ensure_ascii=False), encoding="utf-8")

    with pytest.raises(ValueError, match="bị trùng"):
        load_content(db_session, data_dir_dup)

    assert db_session.scalar(select(func.count()).select_from(Lesson)) == 0
