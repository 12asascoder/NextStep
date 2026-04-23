"""
Pydantic models for request / response payloads between the iOS app and backend.
"""

from pydantic import BaseModel, Field
from typing import Optional, List


# ── Incoming request from the Swift app ──────────────────────────────

class HintRequest(BaseModel):
    """Request body for /ai/hint endpoint."""
    problem: str = Field(..., description="The full math problem statement")
    student_work: Optional[str] = Field(
        None, description="What the student has written so far (OCR text or typed)"
    )
    hint_type: str = Field(
        "hint",
        description="Type of help requested: hint | next | reflect | validate | solution",
    )
    conversation_history: Optional[List[dict]] = Field(
        None,
        description="Previous conversation turns for context continuity",
    )
    difficulty: Optional[str] = Field(
        "10th Grade", description="Difficulty level of the problem"
    )
    topic: Optional[str] = Field(None, description="Math topic, e.g. Algebra, Geometry")


class ValidateStepRequest(BaseModel):
    """Request body for /ai/validate endpoint — checks a single solution step."""
    problem: str = Field(..., description="The full math problem statement")
    step_text: str = Field(..., description="The single line / step the student wrote")
    previous_steps: Optional[List[str]] = Field(
        None, description="All prior solution steps for context"
    )
    difficulty: Optional[str] = Field("10th Grade")
    topic: Optional[str] = Field(None)


class FullSolutionRequest(BaseModel):
    """Request body for /ai/solution endpoint."""
    problem: str = Field(..., description="The full math problem statement")
    difficulty: Optional[str] = Field("10th Grade")
    topic: Optional[str] = Field(None)


# ── Outgoing response to the Swift app ───────────────────────────────

class AIResponse(BaseModel):
    """Standard AI response payload."""
    response: str = Field(..., description="AI-generated text to display")
    reasoning: Optional[str] = Field(
        None, description="DeepSeek R1 chain-of-thought reasoning (if available)"
    )
    is_correct: Optional[bool] = Field(
        None, description="For validation — whether the step is correct"
    )
    hint_type: str = Field("hint", description="Echo of the requested hint type")


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "ok"
    model: str = ""
