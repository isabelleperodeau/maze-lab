"""Seed test puzzles into the database for development."""
import sys
from sqlalchemy.orm import Session
from db.database import SessionLocal, engine
from models.models import Base, Puzzle
from generators.nonogram_generator import generate_nonogram

def seed_puzzles():
    """Create test puzzles in the database."""
    db = SessionLocal()

    try:
        # Check if puzzles already exist
        existing = db.query(Puzzle).count()
        if existing > 0:
            print(f"Database already has {existing} puzzles, skipping seed")
            return

        test_puzzles = [
            # Sudoku puzzles
            Puzzle(
                type="sudoku",
                difficulty="easy",
                data={"grid": [[0]*9 for _ in range(9)]},
                solution={"grid": [[i]*9 for i in range(1, 10)]},
            ),
            Puzzle(
                type="sudoku",
                difficulty="medium",
                data={"grid": [[0]*9 for _ in range(9)]},
                solution={"grid": [[i]*9 for i in range(1, 10)]},
            ),
            Puzzle(
                type="sudoku",
                difficulty="hard",
                data={"grid": [[0]*9 for _ in range(9)]},
                solution={"grid": [[i]*9 for i in range(1, 10)]},
            ),
            # Kakuro puzzles
            Puzzle(
                type="kakuro",
                difficulty="easy",
                data={"board": [[0]*7 for _ in range(7)]},
                solution={"board": [[i]*7 for i in range(1, 8)]},
            ),
            Puzzle(
                type="kakuro",
                difficulty="medium",
                data={"board": [[0]*7 for _ in range(7)]},
                solution={"board": [[i]*7 for i in range(1, 8)]},
            ),
            Puzzle(
                type="kakuro",
                difficulty="hard",
                data={"board": [[0]*7 for _ in range(7)]},
                solution={"board": [[i]*7 for i in range(1, 8)]},
            ),
            # Nonogram puzzles (generated)
            *[
                (lambda puzzle: Puzzle(
                    type="nonogram",
                    difficulty=difficulty,
                    data={
                        "row_hints": puzzle["row_hints"],
                        "col_hints": puzzle["col_hints"],
                    },
                    solution={"grid": puzzle["grid"]},
                ))(generate_nonogram(difficulty))
                for difficulty in ["easy", "medium", "hard"]
            ],
            # 2048 puzzles - difficulty determines target tile
            Puzzle(
                type="2048",
                difficulty="easy",
                data={"board": [[2, 0], [0, 2]]},
                solution={"target": 2048},
            ),
            Puzzle(
                type="2048",
                difficulty="medium",
                data={"board": [[4, 2], [2, 4]]},
                solution={"target": 4096},
            ),
            Puzzle(
                type="2048",
                difficulty="hard",
                data={"board": [[8, 4], [4, 8]]},
                solution={"target": 8192},
            ),
        ]

        db.add_all(test_puzzles)
        db.commit()
        print(f"✅ Seeded {len(test_puzzles)} test puzzles")
    except Exception as e:
        db.rollback()
        print(f"❌ Error seeding puzzles: {e}")
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    seed_puzzles()
