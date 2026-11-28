"""Read lesson content from the validated server catalogue."""

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import joinedload, selectinload

from app.api.deps import DbSession
from app.models.content import Course, Lesson
from app.schemas.content import LessonOut

router = APIRouter(prefix="/lessons", tags=["lessons"])


def _lesson_response(lesson: Lesson) -> LessonOut:
    return LessonOut(
        server_id=lesson.id,
        schema_version=lesson.schema_version,
        content_version=lesson.content_version,
        id=lesson.code,
        level=lesson.course.code,
        order=lesson.order_index,
        title=lesson.title,
        topic=lesson.topic,
        description=lesson.description,
        vocabulary=[
            {
                "id": word.code,
                "hanzi": word.hanzi,
                "pinyin": word.pinyin,
                "hanViet": word.han_viet,
                "meaningVi": word.meaning_vi,
                "example": word.example,
            }
            for word in lesson.words
        ],
        grammar_points=lesson.grammar_points or [],
        ai_scenario=lesson.ai_scenario,
    )


@router.get(
    "",
    response_model=list[LessonOut],
    summary="Danh sách bài học, có thể lọc theo phiên bản nội dung",
)
def list_lessons(
    db: DbSession,
    since_version: int = Query(default=0, ge=0),
) -> list[LessonOut]:
    statement = (
        select(Lesson)
        .join(Lesson.course)
        .where(Lesson.content_version > since_version)
        .options(joinedload(Lesson.course), selectinload(Lesson.words))
        .order_by(Course.order_index, Lesson.order_index, Lesson.id)
    )
    return [_lesson_response(lesson) for lesson in db.scalars(statement).all()]


@router.get(
    "/{lesson_id}",
    response_model=LessonOut,
    summary="Chi tiết bài học",
)
def get_lesson(lesson_id: int, db: DbSession) -> LessonOut:
    statement = (
        select(Lesson)
        .where(Lesson.id == lesson_id)
        .options(joinedload(Lesson.course), selectinload(Lesson.words))
    )
    lesson = db.scalar(statement)
    if lesson is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy bài học",
        )
    return _lesson_response(lesson)
