from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from db.database import Base, engine
from routes import users, puzzles, paths, completions

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Maze Lab API",
    description="API for the Maze Lab puzzle platform",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router)
app.include_router(puzzles.router)
app.include_router(paths.router)
app.include_router(completions.router)


@app.get("/health")
def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    import os
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
