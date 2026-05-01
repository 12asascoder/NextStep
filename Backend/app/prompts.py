"""
Prompt engineering for the DeepSeek R1 math tutor.

Builds system + user messages for each request type so that the model
behaves as a *collaborative tutor*, never just giving the answer away.
"""

from typing import Optional, List


# ── The pedagogical system prompt ────────────────────────────────────

SYSTEM_PROMPT = """You are **NextStep AI**, an expert and patient math tutor for students.

## Your Teaching Philosophy
- **Never** give the full answer outright unless the student explicitly asks for the complete solution.
- Guide students step-by-step so they *learn* rather than just copy.
- Celebrate correct steps and gently redirect incorrect ones.
- Use clear, concise language appropriate for the student's difficulty level.
- When giving hints, be specific enough to be helpful but vague enough that the student still has to think.
- Use proper mathematical notation in your responses.

## Response Formatting
- Keep responses concise — ideally 2-4 sentences for hints.
- Use line breaks for readability.
- When showing math, use standard notation (e.g., x², √, ±, ∞).
- For multi-step guidance, number your steps.

## Difficulty Awareness
- Adapt your vocabulary and explanation depth to the stated difficulty level.
- For younger students, use simpler language and more encouragement.
- For advanced students, you may reference theorems by name.
"""


def build_hint_messages(
    problem: str,
    hint_type: str,
    student_work: Optional[str] = None,
    conversation_history: Optional[List[dict]] = None,
    difficulty: str = "10th Grade",
    topic: Optional[str] = None,
) -> list[dict]:
    """Return the messages list for a hint / next-step / reflect request."""
    messages: list[dict] = [{"role": "system", "content": SYSTEM_PROMPT}]

    # Carry forward prior conversation turns if provided
    if conversation_history:
        messages.extend(conversation_history)

    # Build user prompt based on type
    context_block = f"**Problem ({difficulty}{', ' + topic if topic else ''}):**\n{problem}"
    if student_work:
        context_block += f"\n\n**Student's work so far:**\n{student_work}"

    if hint_type == "hint":
        user_prompt = (
            f"{context_block}\n\n"
            "The student is stuck. Give a helpful hint that nudges them toward "
            "the next logical step WITHOUT revealing the answer. "
            "Be encouraging and concise (2-3 sentences max)."
        )
    elif hint_type == "next":
        user_prompt = (
            f"{context_block}\n\n"
            "Show the student exactly what the next step should be, "
            "explaining *why* that step makes sense. Keep it to one clear step."
        )
    elif hint_type == "reflect":
        user_prompt = (
            f"{context_block}\n\n"
            "Ask the student a thought-provoking question that helps them "
            "discover the next insight on their own. Do NOT give any part of the answer."
        )
    else:
        user_prompt = (
            f"{context_block}\n\n"
            "Provide guidance for this problem. Be helpful but let the student think."
        )

    messages.append({"role": "user", "content": user_prompt})
    return messages


def build_validate_messages(
    problem: str,
    steps: List[str],
    difficulty: str = "10th Grade",
    topic: Optional[str] = None,
) -> list[dict]:
    """Return the messages list for a batch step-validation request."""
    messages: list[dict] = [{"role": "system", "content": SYSTEM_PROMPT}]

    steps_text = "\n".join(f"Step {i}: {s}" for i, s in enumerate(steps))

    user_prompt = (
        f"**Problem ({difficulty}{', ' + topic if topic else ''}):**\n{problem}\n\n"
        f"**Student's sequence of steps (OCR Text):**\n{steps_text}\n\n"
        "Note: The steps were extracted via handwriting OCR and might contain visual "
        "misreadings (e.g., confusing '5' with 'S', '+' with 't', '2' with 'z', '1' with 'I'). "
        "Please evaluate the most likely mathematical intent behind the text.\n\n"
        "Evaluate the sequence of steps. Each step should logically follow from the previous ones. "
        "Respond in EXACTLY this JSON format, providing an array of results:\n"
        '[\n'
        '  {"step_index": 0, "is_correct": true, "feedback": "Good start"},\n'
        '  {"step_index": 1, "is_correct": false, "feedback": "Check your sign here"}\n'
        ']\n\n'
        "ONLY output the JSON array, nothing else."
    )

    messages.append({"role": "user", "content": user_prompt})
    return messages


def build_solution_messages(
    problem: str,
    difficulty: str = "10th Grade",
    topic: Optional[str] = None,
) -> list[dict]:
    """Return the messages list for a full-solution request."""
    messages: list[dict] = [{"role": "system", "content": SYSTEM_PROMPT}]

    user_prompt = (
        f"**Problem ({difficulty}{', ' + topic if topic else ''}):**\n{problem}\n\n"
        "The student has explicitly requested the full solution. "
        "Provide a clear, step-by-step solution with explanations for each step. "
        "Number every step and show your working."
    )

    messages.append({"role": "user", "content": user_prompt})
    return messages
