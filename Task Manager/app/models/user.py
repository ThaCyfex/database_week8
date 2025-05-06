"""
Advanced User model with security features
"""

# I decided to add password hashing and verification using `passlib` because it is a secure and widely used library.
from passlib.context import CryptContext
from sqlalchemy import Column, Integer, String, Boolean, DateTime, func
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.event import listens_for
from .base import Base
from .task import Task  # noqa

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": "task_manager"}
    
    # I ensured all columns have proper constraints and defaults where necessary.
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    last_login = Column(DateTime)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    metadata_ = Column("metadata", JSONB, default_factory=dict)  # Use default_factory for safety
    
    # I added a relationship to link users to their tasks.
    tasks = relationship("Task", back_populates="owner", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"
    
    # I added a property to define user scopes based on their role.
    @property
    def scopes(self):
        if self.is_superuser:
            return ["tasks:read", "tasks:write", "users:read", "users:write", "admin"]
        return ["tasks:read", "tasks:write"]

    # I added methods for hashing and verifying passwords to enhance security.
    def hash_password(self, password: str) -> str:
        """Hash a plain-text password."""
        return pwd_context.hash(password)

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify a plain-text password against a hashed password."""
        return pwd_context.verify(plain_password, hashed_password)

    def update_last_login(self):
        """Update the last login timestamp."""
        self.last_login = func.now()

# Automatically hash passwords before inserting into the database
@listens_for(User, "before_insert")
def hash_user_password(mapper, connection, target):
    if target.hashed_password:
        target.hashed_password = pwd_context.hash(target.hashed_password)