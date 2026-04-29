"""Seed test puzzles into the database for development."""
import sys
from sqlalchemy.orm import Session
from db.database import SessionLocal, engine
from models.models import Base, Puzzle
from generators.nonogram_generator import generate_nonogram
from generators.kakuro_generator import generate_kakuro

def seed_puzzles():
    """Create test puzzles in the database."""
    db = SessionLocal()

    try:
        # Delete existing puzzles to reseed
        existing = db.query(Puzzle).count()
        if existing > 0:
            print(f"Deleting {existing} existing puzzles...")
            db.query(Puzzle).delete()
            db.commit()

        # Generate nonogram puzzles
        nonogram_puzzles = []
        for difficulty in ["easy", "medium", "hard"]:
            puzzle_data = generate_nonogram(difficulty)
            nonogram_puzzles.append(
                Puzzle(
                    type="nonogram",
                    difficulty=difficulty,
                    data={
                        "row_hints": puzzle_data["row_hints"],
                        "col_hints": puzzle_data["col_hints"],
                    },
                    solution={"grid": puzzle_data["grid"]},
                )
            )

        # Generate Kakuro puzzles
        kakuro_puzzles = []
        for difficulty in ["easy", "medium", "hard"]:
            puzzle_data = generate_kakuro(difficulty)
            kakuro_puzzles.append(
                Puzzle(
                    type="kakuro",
                    difficulty=difficulty,
                    data={"board": puzzle_data["board"]},
                    solution={"board": puzzle_data["solution"]},
                )
            )

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
            # Nonogram puzzles (generated)
            *nonogram_puzzles,
            # Kakuro puzzles (generated)
            *kakuro_puzzles,
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
