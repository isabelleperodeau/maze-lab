from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class LoginRequest(BaseModel):
    email: str
    password: str


class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    display_name: str


class User(BaseModel):
    id: int
    username: str
    email: str
    display_name: str
    avatar_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: User


class PuzzleCreate(BaseModel):
    type: str
    difficulty: str
    data: dict
    solution: dict


class Puzzle(BaseModel):
    id: int
    type: str
    difficulty: str
    data: dict
    created_at: datetime

    class Config:
        from_attributes = True


class PathPuzzleCreate(BaseModel):
    puzzle_id: int
    order: int


class PathCreate(BaseModel):
    name: str
    description: Optional[str] = None
    is_public: bool = False
    puzzles: Optional[List[PathPuzzleCreate]] = []


class Path(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    creator_id: int
    is_public: bool
    is_challenge: bool
    created_at: datetime

    class Config:
        from_attributes = True


class PathWithPuzzles(Path):
    puzzles: List[Puzzle] = []


class CompletionCreate(BaseModel):
    path_id: Optional[int] = None
    puzzle_id: int
    time_taken: Optional[int] = None


class Completion(BaseModel):
    id: int
    user_id: int
    path_id: Optional[int] = None
    puzzle_id: int
    time_taken: Optional[int] = None
    completed_at: datetime

    class Config:
        from_attributes = True
