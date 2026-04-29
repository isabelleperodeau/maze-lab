"""Nonogram puzzle generator."""
import random
from typing import List, Set, Tuple


def get_size_for_difficulty(difficulty: str) -> int:
    """Get grid size based on difficulty."""
    sizes = {
        "easy": 6,
        "medium": 8,
        "hard": 10,
    }
    return sizes.get(difficulty, 8)


def get_fill_probability(difficulty: str) -> float:
    """Get fill probability based on difficulty."""
    probabilities = {
        "easy": 0.3,      # Sparse (fewer filled cells)
        "medium": 0.4,    # Moderate
        "hard": 0.5,      # Dense (more filled cells)
    }
    return probabilities.get(difficulty, 0.4)


def generate_random_grid(size: int, fill_probability: float) -> List[List[int]]:
    """Generate a random nonogram grid (0 = empty, 1 = filled)."""
    return [[1 if random.random() < fill_probability else 0 for _ in range(size)] for _ in range(size)]


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


def calculate_grid_hints(grid: List[List[int]]) -> Tuple[List[List[int]], List[List[int]]]:
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


def generate_line_possibilities(length: int, hints: List[int]) -> List[List[int]]:
    """Generate all possible valid arrangements for a line given hints."""
    if not hints or hints == [0]:
        return [[0] * length]

    possibilities = []

    def backtrack(pos: int, hint_idx: int, current: List[int]) -> None:
        """Recursively build valid line arrangements."""
        if hint_idx == len(hints):
            # All hints placed, fill rest with zeros
            possibilities.append(current + [0] * (length - pos))
            return

        hint_size = hints[hint_idx]
        remaining_hints = hints[hint_idx + 1:]
        min_space_needed = sum(remaining_hints) + len(remaining_hints)

        # Try placing the current hint at different positions
        for start in range(pos, length - hint_size - min_space_needed + 1):
            # Add zeros before this hint
            new_line = current + [0] * (start - pos) + [1] * hint_size

            if hint_idx < len(hints) - 1:
                # Add at least one zero after this hint
                new_line += [0]
                backtrack(start + hint_size + 1, hint_idx + 1, new_line)
            else:
                backtrack(start + hint_size, hint_idx + 1, new_line)

    backtrack(0, 0, [])
    return possibilities


def solve_line(line: List[int], hints: List[int]) -> List[int]:
    """Try to solve a single line using constraint satisfaction."""
    length = len(line)
    possibilities = generate_line_possibilities(length, hints)

    if not possibilities:
        return line  # No valid solution

    # Filter possibilities that match known cells
    valid = []
    for poss in possibilities:
        matches = True
        for i in range(length):
            if line[i] != -1 and line[i] != poss[i]:
                matches = False
                break
        if matches:
            valid.append(poss)

    if not valid:
        return line

    # Find cells that are the same in all valid possibilities
    result = list(line)
    for i in range(length):
        if result[i] == -1:
            first_val = valid[0][i]
            if all(p[i] == first_val for p in valid):
                result[i] = first_val

    return result


def is_solvable(grid: List[List[int]]) -> bool:
    """Check if a nonogram puzzle is uniquely solvable from hints alone."""
    size = len(grid)
    row_hints, col_hints = calculate_grid_hints(grid)

    # Start with empty board (-1 = unknown)
    board = [[-1] * size for _ in range(size)]

    max_iterations = 100
    iteration = 0
    changed = True

    while changed and iteration < max_iterations:
        changed = False
        iteration += 1

        # Solve rows
        for i in range(size):
            old_row = board[i][:]
            board[i] = solve_line(board[i], row_hints[i])
            if board[i] != old_row:
                changed = True

        # Solve columns
        for j in range(size):
            column = [board[i][j] for i in range(size)]
            new_col = solve_line(column, col_hints[j])
            if new_col != column:
                changed = True
                for i in range(size):
                    board[i][j] = new_col[i]

    # Check if solved and matches original
    for i in range(size):
        for j in range(size):
            if board[i][j] == -1:
                return False  # Not fully solved
            if board[i][j] != grid[i][j]:
                return False  # Solution doesn't match

    return True


def generate_nonogram(difficulty: str = "easy") -> dict:
    """Generate a complete, solvable nonogram puzzle.

    Returns dict with:
    - grid: the solution
    - row_hints: list of hint lists for each row
    - col_hints: list of hint lists for each column
    """
    size = get_size_for_difficulty(difficulty)
    fill_prob = get_fill_probability(difficulty)

    # Keep trying until we get a solvable puzzle
    max_attempts = 50
    for _ in range(max_attempts):
        grid = generate_random_grid(size, fill_prob)

        # Validate that this puzzle is actually solvable
        if is_solvable(grid):
            row_hints, col_hints = calculate_grid_hints(grid)
            return {
                "grid": grid,
                "row_hints": row_hints,
                "col_hints": col_hints,
            }

    # Fallback: return whatever we have (shouldn't reach here often)
    row_hints, col_hints = calculate_grid_hints(grid)
    return {
        "grid": grid,
        "row_hints": row_hints,
        "col_hints": col_hints,
    }
