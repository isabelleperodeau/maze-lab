"""Kakuro puzzle generator."""
import random
from typing import List, Tuple, Optional


# Cell types
CELL_BLACK = -1  # Black cell (non-playable)
CELL_EMPTY = 0   # Empty answer cell


class KakuroClue:
    """Represents a clue cell with horizontal and/or vertical sums."""

    def __init__(self, horizontal: Optional[int] = None, vertical: Optional[int] = None):
        self.horizontal = horizontal
        self.vertical = vertical

    def __repr__(self):
        return f"Clue(h={self.horizontal},v={self.vertical})"


def generate_grid_structure(size: int = 7) -> List[List]:
    """Generate a random Kakuro grid structure with black and clue cells."""
    grid = [[CELL_EMPTY for _ in range(size)] for _ in range(size)]

    # Randomly place black cells and clues to create structure
    for i in range(size):
        for j in range(size):
            # Corners and edges often have black cells
            if i == 0 or j == 0:
                if random.random() < 0.3:
                    grid[i][j] = CELL_BLACK
            elif random.random() < 0.2:  # Random black cells
                grid[i][j] = CELL_BLACK

    return grid


def get_horizontal_block(grid: List[List], row: int, col: int) -> List[Tuple[int, int]]:
    """Get all answer cells in the horizontal block starting after this cell."""
    cells = []
    for c in range(col + 1, len(grid[0])):
        if grid[row][c] == CELL_BLACK or isinstance(grid[row][c], KakuroClue):
            break
        cells.append((row, c))
    return cells


def get_vertical_block(grid: List[List], row: int, col: int) -> List[Tuple[int, int]]:
    """Get all answer cells in the vertical block starting after this cell."""
    cells = []
    for r in range(row + 1, len(grid)):
        if grid[r][col] == CELL_BLACK or isinstance(grid[r][col], KakuroClue):
            break
        cells.append((r, col))
    return cells


def fill_with_solution(grid: List[List]) -> Tuple[List[List], List[List], dict]:
    """Fill grid with valid numbers and generate clues.

    Returns:
    - solution grid (with answer cells filled)
    - clue grid (with KakuroClue objects)
    - clue details (for validation)
    """
    size = len(grid)
    solution = [row[:] for row in grid]  # Deep copy

    # Fill empty cells with random numbers 1-9
    for i in range(size):
        for j in range(size):
            if solution[i][j] == CELL_EMPTY:
                solution[i][j] = random.randint(1, 9)

    # Generate clues based on filled numbers
    clues = [[None for _ in range(size)] for _ in range(size)]
    clue_details = {}

    for i in range(size):
        for j in range(size):
            if solution[i][j] == CELL_BLACK:
                clues[i][j] = CELL_BLACK
            elif isinstance(solution[i][j], KakuroClue):
                clues[i][j] = solution[i][j]
            else:
                continue  # Regular answer cell

            # Create clue if this could be a clue cell
            if i < size - 1 or j < size - 1:
                h_sum = None
                v_sum = None

                # Calculate horizontal sum
                h_cells = get_horizontal_block(solution, i, j)
                if h_cells:
                    h_sum = sum(solution[r][c] for r, c in h_cells)

                # Calculate vertical sum
                v_cells = get_vertical_block(solution, i, j)
                if v_cells:
                    v_sum = sum(solution[r][c] for r, c in v_cells)

                if h_sum is not None or v_sum is not None:
                    clue = KakuroClue(horizontal=h_sum, vertical=v_sum)
                    clues[i][j] = clue
                    clue_details[(i, j)] = (h_cells, v_cells)

    return solution, clues, clue_details


def serialize_grid(grid: List[List]) -> List[List]:
    """Convert grid to JSON-serializable format."""
    result = []
    for row in grid:
        serialized_row = []
        for cell in row:
            if cell == CELL_BLACK:
                serialized_row.append(-1)
            elif cell == CELL_EMPTY:
                serialized_row.append(0)
            elif isinstance(cell, KakuroClue):
                serialized_row.append({
                    "h": cell.horizontal,
                    "v": cell.vertical
                })
            else:
                serialized_row.append(cell)
        result.append(serialized_row)
    return result


def generate_kakuro(difficulty: str = "easy", size: int = 7) -> dict:
    """Generate a complete Kakuro puzzle.

    Args:
        difficulty: "easy", "medium", or "hard"
        size: Grid size (default 7x7)

    Returns:
        dict with:
        - board: the puzzle (with clues and empty answer cells)
        - solution: the complete grid with all answers filled
    """
    # Generate grid structure
    grid = generate_grid_structure(size)

    # Fill with solution and generate clues
    solution, clues, clue_details = fill_with_solution(grid)

    # Create puzzle board (clues visible, answers empty)
    board = [[CELL_BLACK if cell == CELL_BLACK else (clues[i][j] if isinstance(clues[i][j], KakuroClue) else CELL_EMPTY)
              for j, cell in enumerate(row)]
             for i, row in enumerate(clues)]

    return {
        "board": serialize_grid(board),
        "solution": serialize_grid(solution),
    }
