"""
Advanced Pydantic schemas for users
"""

# These schemas are designed to validate user data for a South African audience, ensuring compliance with local standards.

from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field, validator
from enum import Enum

class UserScope(str, Enum):
    TASKS_READ = "tasks:read"
    TASKS_WRITE = "tasks:write"
    USERS_READ = "users:read"
    USERS_WRITE = "users:write"
    ADMIN = "admin"

class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50, regex="^[a-zA-Z0-9_-]+$")
    
    @validator("username")
    def username_must_be_valid(cls, v):
        if "admin" in v.lower():
            raise ValueError("Username cannot contain 'admin'")
        return v

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    full_name: Optional[str] = Field(None, max_length=100)  # Full name, e.g., "Sipho Nkosi"

class UserUpdate(BaseModel):
    email: Optional[EmailStr]
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    full_name: Optional[str] = Field(None, max_length=100)
    is_active: Optional[bool]
    
    @validator("username")
    def username_must_be_valid(cls, v):
        if v and "admin" in v.lower():
            raise ValueError("Username cannot contain 'admin'")
        return v

class UserRead(UserBase):
    id: int
    full_name: Optional[str]
    is_active: bool
    is_superuser: bool
    last_login: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    scopes: List[UserScope] = []
    
    class Config:
        orm_mode = True

class UserInDB(UserRead):
    hashed_password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None
    scopes: List[str] = []