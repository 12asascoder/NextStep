"""
API route definitions for the NextStep AI backend.
"""

import json
import logging
from fastapi import APIRouter, HTTPException

from app.models import (
    HintRequest,
    ValidateStepRequest,
    FullSolutionRequest,
    AIResponse,
    HealthResponse,
)
from app.prompts import (
    build_hint_messages,
    build_validate_messages,
    build_solution_messages,
)
from app.deepseek_client import chat_completion
from app.config import DEEPSEEK_MODEL

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ai", tags=["AI Tutor"])


# ── Health check ─────────────────────────────────────────────────────

@router.get("/health", response_model=HealthResponse)
async def health():
    return HealthResponse(status="ok", model=DEEPSEEK_MODEL)


# ── Hint / Next Step / Reflect ───────────────────────────────────────

@router.post("/hint", response_model=AIResponse)
async def get_hint(req: HintRequest):
    """
    Returns an AI-generated hint, next-step guide, or reflective question
    depending on `hint_type`.
    """
    messages = build_hint_messages(
        problem=req.problem,
        hint_type=req.hint_type,
        student_work=req.student_work,
        conversation_history=req.conversation_history,
        difficulty=req.difficulty or "10th Grade",
        topic=req.topic,
    )

    try:
        content, reasoning = await chat_completion(messages)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"DeepSeek API error: {exc}")

    return AIResponse(
        response=content,
        reasoning=reasoning,
        hint_type=req.hint_type,
    )


# ── Validate a single solution step ─────────────────────────────────

@router.post("/validate", response_model=AIResponse)
async def validate_step(req: ValidateStepRequest):
    """
    Checks whether a student's solution step is mathematically correct.
    Returns is_correct boolean + textual feedback.
    """
    messages = build_validate_messages(
        problem=req.problem,
        step_text=req.step_text,
        previous_steps=req.previous_steps,
        difficulty=req.difficulty or "10th Grade",
        topic=req.topic,
    )

    try:
        content, reasoning = await chat_completion(messages)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"DeepSeek API error: {exc}")

    # Try to parse structured JSON from the response
    is_correct = None
    feedback = content
    try:
        parsed = json.loads(content)
        is_correct = parsed.get("is_correct")
        feedback = parsed.get("feedback", content)
    except (json.JSONDecodeError, TypeError):
        # Model didn't return strict JSON — use raw text as feedback
        pass

    return AIResponse(
        response=feedback,
        reasoning=reasoning,
        is_correct=is_correct,
        hint_type="validate",
    )


# ── Full solution ───────────────────────────────────────────────────

@router.post("/solution", response_model=AIResponse)
async def full_solution(req: FullSolutionRequest):
    """
    Returns a complete, step-by-step solution for the problem.
    Only used when the student explicitly requests it.
    """
    messages = build_solution_messages(
        problem=req.problem,
        difficulty=req.difficulty or "10th Grade",
        topic=req.topic,
    )

    try:
        content, reasoning = await chat_completion(messages)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"DeepSeek API error: {exc}")

    return AIResponse(
        response=content,
        reasoning=reasoning,
        hint_type="solution",
    )
