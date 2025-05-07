"""
Advanced database module with async support
"""

# This database module is configured to handle data for a South African audience, ensuring scalability and reliability.
import logging
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import SQLAlchemyError
from .config import settings

logger = logging.getLogger(__name__)

# I configured the async engine with connection pooling and timeouts for better performance.
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    pool_size=settings.db_pool_size,
    max_overflow=settings.db_max_overflow,
    pool_timeout=settings.db_pool_timeout,
    pool_recycle=settings.db_pool_recycle,
    pool_pre_ping=True
)

# I set up the session factory to manage database sessions efficiently.
async_session = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False
)

async def get_db() -> AsyncSession:
    """
    Dependency that provides an async database session with proper cleanup
    """
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except SQLAlchemyError as e:
            logger.error(f"Database error: {e}, session state: {session.info}")
            await session.rollback()
            raise
        finally:
            await session.close()

# I defined a base class for all models to inherit from.
Base = declarative_base()