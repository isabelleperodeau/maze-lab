from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from db.database import get_db
from models.models import Path as PathModel, PathPuzzle, Puzzle
from schemas.schemas import Path, PathCreate, PathWithPuzzles
from auth import get_current_user

router = APIRouter(prefix="/paths", tags=["paths"])


@router.post("/", response_model=Path)
def create_path(path: PathCreate, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    db_path = PathModel(
        name=path.name,
        description=path.description,
        creator_id=current_user["user_id"],
        is_public=path.is_public,
    )
    db.add(db_path)
    db.commit()
    db.refresh(db_path)

    for puzzle_spec in path.puzzles or []:
        path_puzzle = PathPuzzle(
            path_id=db_path.id,
            puzzle_id=puzzle_spec.puzzle_id,
            order=puzzle_spec.order,
        )
        db.add(path_puzzle)
    db.commit()

    return db_path


@router.get("/{path_id}", response_model=PathWithPuzzles)
def get_path(path_id: int, db: Session = Depends(get_db)):
    db_path = db.query(PathModel).filter(PathModel.id == path_id).first()
    if not db_path:
        raise HTTPException(status_code=404, detail="Path not found")

    puzzles = db.query(Puzzle).join(PathPuzzle).filter(PathPuzzle.path_id == path_id).all()
    return PathWithPuzzles(**db_path.__dict__, puzzles=puzzles)


@router.get("/user/{user_id}")
def get_user_paths(user_id: int, db: Session = Depends(get_db)):
    paths = db.query(PathModel).filter(PathModel.creator_id == user_id).all()
    return paths
