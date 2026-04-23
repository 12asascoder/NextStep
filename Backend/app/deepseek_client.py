"""
DeepSeek R1 client — thin wrapper around the OpenAI-compatible API.
"""

import logging
from openai import AsyncOpenAI

from app.config import DEEPSEEK_API_KEY, DEEPSEEK_BASE_URL, DEEPSEEK_MODEL

logger = logging.getLogger(__name__)

# Initialise client once at module level
_client = AsyncOpenAI(
    api_key=DEEPSEEK_API_KEY,
    base_url=DEEPSEEK_BASE_URL,
)


async def chat_completion(
    messages: list[dict],
    temperature: float = 0.7,
    max_tokens: int = 2048,
) -> tuple[str, str | None]:
    """
    Send a chat completion request to DeepSeek R1.

    Returns
    -------
    (content, reasoning_content)
        content  – the final assistant reply.
        reasoning_content – the R1 chain-of-thought, or None if not present.
    """
    try:
        response = await _client.chat.completions.create(
            model=DEEPSEEK_MODEL,
            messages=messages,
            max_tokens=max_tokens,
        )

        choice = response.choices[0].message
        content = choice.content or ""

        # DeepSeek R1 may expose its reasoning in `reasoning_content`
        reasoning = getattr(choice, "reasoning_content", None)

        logger.info("DeepSeek R1 responded (%d chars)", len(content))
        return content, reasoning

    except Exception as exc:
        logger.exception("DeepSeek API call failed")
        raise exc
