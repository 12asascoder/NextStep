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


class ValidateStepsRequest(BaseModel):
    """Request body for /ai/validate endpoint — checks a sequence of solution steps."""
    problem: str = Field(..., description="The full math problem statement")
    steps: List[str] = Field(..., description="The sequence of steps written by the student so far")
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


class StepValidationResult(BaseModel):
    step_index: int = Field(..., description="Index of the step in the submitted array")
    is_correct: bool = Field(..., description="Whether the step is correct")
    feedback: str = Field(..., description="Feedback for this specific step")


class BatchAIResponse(BaseModel):
    """Batch AI response payload for validating multiple steps."""
    results: List[StepValidationResult] = Field(..., description="Validation result for each step")
    reasoning: Optional[str] = Field(None, description="DeepSeek R1 chain-of-thought reasoning")
    hint_type: str = Field("validate", description="Echo of the requested hint type")


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "ok"
    model: str = ""
