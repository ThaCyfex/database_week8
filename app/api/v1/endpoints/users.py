"""
Advanced user endpoints with JWT authentication
"""

# These endpoints are designed to manage user data for a South African audience, ensuring compliance with local standards.

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
from app.services.task_service import UserService, TaskService
from app.services.category_service import CategoryService
from app.schemas.task import TaskRead, TaskCreate, TaskUpdate
from app.schemas.category import CategoryRead, CategoryCreate, CategoryUpdate

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
    """
    Create a new user. This endpoint ensures proper validation and permissions.
    """
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

@router.post("/tasks", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
async def create_task(
    task: TaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Create a new task. This endpoint ensures proper validation and permissions.
    """
    return await TaskService(db).create_task(task, current_user.id)

@router.get("/tasks", response_model=List[TaskRead])
async def read_tasks(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Retrieve tasks for the current user.
    """
    return await TaskService(db).get_tasks(skip, limit, current_user.id)

@router.get("/tasks/{task_id}", response_model=TaskRead)
async def read_task(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Retrieve a specific task by ID.
    """
    task = await TaskService(db).get_task(task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@router.put("/tasks/{task_id}", response_model=TaskRead)
async def update_task(
    task_id: int,
    task_update: TaskUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Update a task by ID.
    """
    return await TaskService(db).update_task(task_id, task_update, current_user.id)

@router.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Delete a task by ID.
    """
    await TaskService(db).delete_task(task_id, current_user.id)
    return None

@router.post("/categories", response_model=CategoryRead, status_code=status.HTTP_201_CREATED)
async def create_category(
    category: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Create a new category.
    """
    return await CategoryService(db).create_category(category, current_user.id)

@router.get("/categories", response_model=List[CategoryRead])
async def read_categories(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Retrieve categories for the current user.
    """
    return await CategoryService(db).get_categories(skip, limit, current_user.id)

@router.get("/categories/{category_id}", response_model=CategoryRead)
async def read_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Retrieve a specific category by ID.
    """
    category = await CategoryService(db).get_category(category_id, current_user.id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category

@router.put("/categories/{category_id}", response_model=CategoryRead)
async def update_category(
    category_id: int,
    category_update: CategoryUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Update a category by ID.
    """
    return await CategoryService(db).update_category(category_id, category_update, current_user.id)

@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: UserRead = Depends(get_current_active_user)
):
    """
    Delete a category by ID.
    """
    await CategoryService(db).delete_category(category_id, current_user.id)
    return None