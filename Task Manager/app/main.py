"""
Advanced Task Manager API
Author: Thembelani Bukali
Date: 2025 May 05

Features:
- Proper application factory pattern
- Dependency injection
- Async database support
- JWT authentication
- Advanced error handling
- Comprehensive logging
- API versioning
- Rate limiting
- Background tasks
- CORS middleware
- Configuration management
- Database migrations
- Unit testing support
"""

import logging
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.depends import RateLimiter
import redis.asyncio as redis
from contextlib import asynccontextmanager
from typing import AsyncGenerator
from tenacity import retry, stop_after_attempt, wait_fixed

from .config import settings
from .database import engine, Base, async_session
from .models.base import Base
from .api.v1.routers import api_router
from .services.auth import get_current_active_user
from .schemas.user import UserRead

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

@retry(stop=stop_after_attempt(3), wait=wait_fixed(2))
async def init_redis():
    """Initialize Redis with retries."""
    return redis.from_url(
        f"redis://{settings.redis_host}:{settings.redis_port}",
        encoding="utf-8",
        decode_responses=True
    )

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    # Startup events
    logger.info("Starting up...")
    
    # Initialize Redis for rate limiting
    try:
        redis_connection = await init_redis()
        await FastAPILimiter.init(redis_connection)
    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")
        raise

    # Create database tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield
    
    # Shutdown events
    logger.info("Shutting down...")
    await FastAPILimiter.close()

def create_application() -> FastAPI:
    application = FastAPI(
        title=settings.project_name,
        description="Advanced Task Manager API",
        version=settings.version,
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json",
        lifespan=lifespan
    )
    
    # Set up CORS
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_hosts,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include routers
    application.include_router(
        api_router,
        prefix="/api/v1",
        dependencies=[Depends(RateLimiter(times=100, minutes=1))]
    )
    
    # Mount static files
    static_dir = settings.static_files_dir or "static"
    application.mount("/static", StaticFiles(directory=static_dir), name="static")
    
    return application

app = create_application()

@app.get("/")
async def root():
    return {"message": "Advanced Task Manager API"}

@app.get("/api/me", response_model=UserRead)
async def read_current_user(
    current_user: UserRead = Depends(get_current_active_user)
):
    return current_user

@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint."""
    try:
        return {"status": "ok"}
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=500, detail="Health check failed")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host=settings.host,
        port=settings.port,
        log_level=settings.log_level.lower(),
        reload=settings.debug
    )