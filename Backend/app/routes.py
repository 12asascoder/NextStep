"""
API route definitions for the NextStep AI backend.
"""

import json
import logging
from fastapi import APIRouter, HTTPException

from app.models import (
    HintRequest,
    ValidateStepsRequest,
    FullSolutionRequest,
    AIResponse,
    HealthResponse,
    BatchAIResponse,
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


# ── Validate a sequence of solution steps ───────────────────────────────

@router.post("/validate", response_model=BatchAIResponse)
async def validate_steps(req: ValidateStepsRequest):
    """
    Checks whether a sequence of student solution steps is mathematically correct.
    Returns a batch array of correctness and textual feedback.
    """
    messages = build_validate_messages(
        problem=req.problem,
        steps=req.steps,
        difficulty=req.difficulty or "10th Grade",
        topic=req.topic,
    )

    try:
        content, reasoning = await chat_completion(messages)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"DeepSeek API error: {exc}")

    # Try to parse structured JSON array from the response
    import re
    results = []
    try:
        # Strip markdown json block if present
        clean_content = re.sub(r'^```(?:json)?\s*(.*?)\s*```$', r'\1', content.strip(), flags=re.DOTALL | re.MULTILINE).strip()
        parsed_array = json.loads(clean_content)
        
        if isinstance(parsed_array, list):
            for item in parsed_array:
                results.append({
                    "step_index": item.get("step_index", 0),
                    "is_correct": item.get("is_correct", False),
                    "feedback": item.get("feedback", "")
                })
    except (json.JSONDecodeError, TypeError):
        # Model didn't return strict JSON — fallback or empty array
        pass

    return BatchAIResponse(
        results=results,
        reasoning=reasoning,
        hint_type="validate"
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
