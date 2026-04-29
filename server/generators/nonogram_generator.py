"""Nonogram puzzle generator."""
import random
from typing import List


def generate_random_grid(width: int = 10, height: int = 10, fill_probability: float = 0.4) -> List[List[int]]:
    """Generate a random nonogram grid (0 = empty, 1 = filled)."""
    return [[1 if random.random() < fill_probability else 0 for _ in range(width)] for _ in range(height)]


def calculate_line_hints(line: List[int]) -> List[int]:
    """Calculate hints for a single line (row or column).

    Returns list of consecutive filled cell counts.
    E.g., [1, 1, 0, 1, 1, 1] -> [2, 3]
    """
    hints = []
    consecutive = 0

    for cell in line:
        if cell == 1:
            consecutive += 1
        elif consecutive > 0:
            hints.append(consecutive)
            consecutive = 0

    if consecutive > 0:
        hints.append(consecutive)

    return hints if hints else [0]


def calculate_grid_hints(grid: List[List[int]]) -> tuple[List[List[int]], List[List[int]]]:
    """Calculate row and column hints for a grid.

    Returns (row_hints, col_hints) where each is a list of hint lists.
    """
    height = len(grid)
    width = len(grid[0]) if height > 0 else 0

    # Row hints
    row_hints = [calculate_line_hints(grid[i]) for i in range(height)]

    # Column hints
    col_hints = []
    for j in range(width):
        column = [grid[i][j] for i in range(height)]
        col_hints.append(calculate_line_hints(column))

    return row_hints, col_hints


def generate_nonogram(difficulty: str = "easy", width: int = 10, height: int = 10) -> dict:
    """Generate a complete nonogram puzzle with hints.

    Returns dict with:
    - grid: the solution (10x10 filled with 0s and 1s)
    - row_hints: list of hint lists for each row
    - col_hints: list of hint lists for each column
    """
    # Adjust fill probability by difficulty
    probabilities = {
        "easy": 0.3,      # Sparse (fewer filled cells)
        "medium": 0.4,    # Moderate
        "hard": 0.5,      # Dense (more filled cells)
    }

    fill_prob = probabilities.get(difficulty, 0.4)

    # Generate random grid
    grid = generate_random_grid(width, height, fill_prob)

    # Calculate hints
    row_hints, col_hints = calculate_grid_hints(grid)

    return {
        "grid": grid,
        "row_hints": row_hints,
        "col_hints": col_hints,
    }
