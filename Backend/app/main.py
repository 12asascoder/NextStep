"""
NextStep AI Backend — FastAPI application entry point.

Run with:
    cd Backend && poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
"""

import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes import router
from app.config import DEEPSEEK_API_KEY, DEEPSEEK_MODEL

# ── Logging ──────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

# ── FastAPI App ──────────────────────────────────────────────────────

app = FastAPI(
    title="NextStep AI Backend",
    description="DeepSeek R1-powered math tutoring API for the NextStep iPad app",
    version="1.0.0",
)

# Allow the iOS app (and the Simulator) to connect from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(router)


@app.on_event("startup")
async def startup_event():
    if not DEEPSEEK_API_KEY:
        logger.warning("⚠️  DEEPSEEK_API_KEY is not set — AI calls will fail!")
    else:
        logger.info("✅ DeepSeek API key loaded (model: %s)", DEEPSEEK_MODEL)
    logger.info("🚀 NextStep AI Backend is running")


# ── Root redirect ────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {
        "app": "NextStep AI Backend",
        "docs": "/docs",
        "health": "/ai/health",
    }
