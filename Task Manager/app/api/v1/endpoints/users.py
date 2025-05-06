"""
Advanced user endpoints with JWT authentication
"""

from fastapi import APIRouter, Depends, HTTPException, status, Security
from fastapi.security import OAuth2PasswordRequestForm, HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.services.auth import (
    authenticate_user,
    create_access_token,
    get_current_active_user,
    get_password_hash
)
from app.schemas.user import (
    UserRead,
    UserCreate,
    UserUpdate,
    Token,
    UserScope
)
from app.models.user import User
from app.database import get_db
from app.services.task_service import UserService

router = APIRouter()
security = HTTPBearer()

@router.post("/token", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    user = await authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(
        data={"sub": user.username, "scopes": user.scopes}
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/users", response_model=UserRead, status_code=status.HTTP_201_CREATED)
async def create_user(
    user: UserCreate,
    db: AsyncSession = Depends(get_db),
    credentials: HTTPAuthorizationCredentials = Security(security),
    current_user: UserRead = Depends(get_current_active_user)
):
    if UserScope.USERS_WRITE not in current_user.scopes:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    return await UserService(db).create_user(user)

@router.get("/users/me", response_model=UserRead)
async def read_users_me(current_user: UserRead = Depends(get_current_active_user)):
    return current_user

@router.get("/users", response_model=List[UserRead])
async def read_users(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    if UserScope.USERS_READ not in current_user.scopes:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return await UserService(db).get_users(skip, limit)

@router.get("/users/{user_id}", response_model=UserRead)
async def read_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    if UserScope.USERS_READ not in current_user.scopes:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    user = await UserService(db).get_user(user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.put("/users/{user_id}", response_model=UserRead)
async def update_user(
    user_id: int,
    user_update: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    if UserScope.USERS_WRITE not in current_user.scopes:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return await UserService(db).update_user(user_id, user_update)

@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    if UserScope.USERS_WRITE not in current_user.scopes:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    await UserService(db).delete_user(user_id)
    return None