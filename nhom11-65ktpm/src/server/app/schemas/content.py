"""Pydantic contracts for lesson content JSON files and API responses."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ContentModel(BaseModel):
    """Base schema enforcing contract field names and clean whitespace."""

    model_config = ConfigDict(
        extra="forbid",
        populate_by_name=True,
        str_strip_whitespace=True,
    )


class WordExampleContent(ContentModel):
    """Example sentence attached to a vocabulary word."""

    hanzi: str = Field(min_length=1)
    pinyin: str = Field(min_length=1)
    meaning_vi: str = Field(alias="meaningVi", min_length=1)


class VocabularyContent(ContentModel):
    """Vocabulary item inside a lesson JSON file."""

    id: str = Field(min_length=1, max_length=64)
    hanzi: str = Field(min_length=1, max_length=32)
    pinyin: str = Field(min_length=1, max_length=100)
    han_viet: str | None = Field(default=None, alias="hanViet", max_length=100)
    meaning_vi: str = Field(alias="meaningVi", min_length=1, max_length=255)
    example: WordExampleContent | None = None


class GrammarPointContent(ContentModel):
    """Grammar note inside a lesson JSON file."""

    id: str = Field(min_length=1, max_length=64)
    pattern: str = Field(min_length=1)
    explanation_vi: str = Field(alias="explanationVi", min_length=1)
    examples: list[str] = Field(default_factory=list)


class AiScenarioContent(ContentModel):
    """Roleplay scenario consumed by the AI assistant."""

    ai_role: str = Field(alias="aiRole", min_length=1)
    learner_role: str = Field(alias="learnerRole", min_length=1)
    situation: str = Field(min_length=1)
    opening_line: str = Field(alias="openingLine", min_length=1)


class LessonContent(ContentModel):
    """Validated lesson JSON matching section 2 of docs/hop-dong-du-lieu.md."""

    schema_version: int = Field(alias="schemaVersion", ge=1)
    content_version: int = Field(alias="contentVersion", ge=1)
    id: str = Field(min_length=1, max_length=64)
    level: Literal["PINYIN", "HSK1", "HSK2"]
    order: int = Field(ge=1)
    title: str = Field(min_length=1, max_length=200)
    topic: str | None = Field(default=None, max_length=100)
    description: str | None = None
    vocabulary: list[VocabularyContent] = Field(min_length=1)
    grammar_points: list[GrammarPointContent] = Field(alias="grammarPoints")
    ai_scenario: AiScenarioContent = Field(alias="aiScenario")

    @model_validator(mode="after")
    def validate_unique_ids(self) -> "LessonContent":
        word_ids = [word.id for word in self.vocabulary]
        if len(word_ids) != len(set(word_ids)):
            raise ValueError("vocabulary ids must be unique within a lesson")
        grammar_ids = [point.id for point in self.grammar_points]
        if len(grammar_ids) != len(set(grammar_ids)):
            raise ValueError("grammar point ids must be unique within a lesson")
        return self


class LessonOut(LessonContent):
    """Lesson API response preserving the JSON file structure plus serverId."""

    server_id: int = Field(serialization_alias="serverId")
