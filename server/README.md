# Maze Lab API Server

FastAPI-based backend for the Maze Lab puzzle platform.

## Setup

1. Create a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # on Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Copy environment variables:
```bash
cp .env.example .env
```

4. Run database migrations:
```bash
alembic upgrade head
```

5. Run the server:
```bash
python main.py
```

The API will be available at `http://localhost:8000`.
- Docs: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Database Migrations

Create a new migration after schema changes:
```bash
alembic revision --autogenerate -m "description of changes"
alembic upgrade head
```

## Project Structure

- `main.py` — FastAPI application entry point
- `auth.py` — JWT token creation and verification
- `db/database.py` — SQLAlchemy setup
- `models/models.py` — Database models (User, Puzzle, Path, Completion, Friendship)
- `schemas/schemas.py` — Pydantic request/response schemas
- `routes/` — API endpoint routers
- `alembic/` — Database migration files

## API Routes

### Authentication
- `POST /users/register` — Register new user, returns access token
- `POST /users/login` — Login user, returns access token
- `GET /users/me` — Get current user profile (requires auth)

### Puzzles
- `POST /puzzles` — Create puzzle
- `GET /puzzles/{puzzle_id}` — Get puzzle by ID
- `GET /puzzles/type/{puzzle_type}` — Get all puzzles of a type
- `GET /puzzles/random/{puzzle_type}` — Get random puzzle of a type

### Paths
- `POST /paths` — Create path (requires auth)
- `GET /paths/{path_id}` — Get path with puzzles
- `GET /paths/user/{user_id}` — Get user's paths

### Completions
- `POST /completions` — Record puzzle completion (requires auth)
- `GET /completions/user/{user_id}` — Get user's completions
- `GET /completions/path/{path_id}` — Get path completions

## Authentication

Routes marked with "requires auth" expect a Bearer token in the Authorization header:
```
Authorization: Bearer <access_token>
```

Tokens expire after 30 days. Get a new token by logging in or registering.
