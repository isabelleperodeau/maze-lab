from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from db.database import get_db
from models.models import Puzzle as PuzzleModel
from schemas.schemas import Puzzle, PuzzleCreate

router = APIRouter(prefix="/puzzles", tags=["puzzles"])


@router.post("/", response_model=Puzzle)
def create_puzzle(puzzle: PuzzleCreate, db: Session = Depends(get_db)):
    db_puzzle = PuzzleModel(
        type=puzzle.type,
        difficulty=puzzle.difficulty,
        data=puzzle.data,
        solution=puzzle.solution,
    )
    db.add(db_puzzle)
    db.commit()
    db.refresh(db_puzzle)
    return db_puzzle


@router.get("/{puzzle_id}", response_model=Puzzle)
def get_puzzle(puzzle_id: int, db: Session = Depends(get_db)):
    puzzle = db.query(PuzzleModel).filter(PuzzleModel.id == puzzle_id).first()
    if not puzzle:
        raise HTTPException(status_code=404, detail="Puzzle not found")
    return puzzle


@router.get("/type/{puzzle_type}")
def get_puzzles_by_type(puzzle_type: str, db: Session = Depends(get_db)):
    puzzles = db.query(PuzzleModel).filter(PuzzleModel.type == puzzle_type).all()
    return puzzles


@router.get("/random/{puzzle_type}")
def get_random_puzzle(puzzle_type: str, difficulty: str = "easy", db: Session = Depends(get_db)):
    from sqlalchemy import func
    puzzle = (
        db.query(PuzzleModel)
        .filter(PuzzleModel.type == puzzle_type)
        .filter(PuzzleModel.difficulty == difficulty)
        .order_by(func.random())
        .first()
    )
    if not puzzle:
        raise HTTPException(
            status_code=404,
            detail=f"No puzzles of type {puzzle_type} with difficulty {difficulty} found"
        )
    return puzzle
