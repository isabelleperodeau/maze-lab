"""Seed test puzzles into the database for development."""
import sys
from sqlalchemy.orm import Session
from db.database import SessionLocal, engine
from models.models import Base, Puzzle

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
            # Nonogram puzzles
            Puzzle(
                type="nonogram",
                difficulty="easy",
                data={"grid": [[0]*10 for _ in range(10)]},
                solution={"grid": [[1]*10 for _ in range(10)]},
            ),
            Puzzle(
                type="nonogram",
                difficulty="medium",
                data={"grid": [[0]*10 for _ in range(10)]},
                solution={"grid": [[1]*10 for _ in range(10)]},
            ),
            Puzzle(
                type="nonogram",
                difficulty="hard",
                data={"grid": [[0]*10 for _ in range(10)]},
                solution={"grid": [[1]*10 for _ in range(10)]},
            ),
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
