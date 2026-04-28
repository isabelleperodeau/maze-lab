from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from db.database import get_db
from models.models import Completion as CompletionModel
from schemas.schemas import Completion, CompletionCreate
from auth import get_current_user

router = APIRouter(prefix="/completions", tags=["completions"])


@router.post("/", response_model=Completion)
def record_completion(completion: CompletionCreate, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    db_completion = CompletionModel(
        user_id=current_user["user_id"],
        path_id=completion.path_id,
        puzzle_id=completion.puzzle_id,
        time_taken=completion.time_taken,
    )
    db.add(db_completion)
    db.commit()
    db.refresh(db_completion)
    return db_completion


@router.get("/user/{user_id}")
def get_user_completions(user_id: int, db: Session = Depends(get_db)):
    completions = db.query(CompletionModel).filter(CompletionModel.user_id == user_id).all()
    return completions


@router.get("/path/{path_id}")
def get_path_completions(path_id: int, db: Session = Depends(get_db)):
    completions = db.query(CompletionModel).filter(CompletionModel.path_id == path_id).all()
    return completions


@router.get("/")
def get_completions(path_id: int = None, user_id: int = None, db: Session = Depends(get_db)):
    query = db.query(CompletionModel)
    if path_id:
        query = query.filter(CompletionModel.path_id == path_id)
    if user_id:
        query = query.filter(CompletionModel.user_id == user_id)
    return query.all()
