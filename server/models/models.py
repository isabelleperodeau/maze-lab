from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from db.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    display_name = Column(String)
    avatar_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    paths = relationship("Path", back_populates="creator")
    completions = relationship("Completion", back_populates="user")
    friendships = relationship("Friendship", foreign_keys="Friendship.user_id", back_populates="user")


class Puzzle(Base):
    __tablename__ = "puzzles"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String, index=True)  # sudoku, kakuro, nonogram, 2048, etc.
    difficulty = Column(String)  # easy, medium, hard
    data = Column(JSON)  # puzzle-specific data
    solution = Column(JSON)  # puzzle-specific solution
    created_at = Column(DateTime, default=datetime.utcnow)

    path_puzzles = relationship("PathPuzzle", back_populates="puzzle")


class Path(Base):
    __tablename__ = "paths"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String, nullable=True)
    creator_id = Column(Integer, ForeignKey("users.id"))
    is_public = Column(Boolean, default=False)
    is_challenge = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    creator = relationship("User", back_populates="paths")
    puzzles = relationship("PathPuzzle", back_populates="path")
    completions = relationship("Completion", back_populates="path")


class PathPuzzle(Base):
    __tablename__ = "path_puzzles"

    id = Column(Integer, primary_key=True, index=True)
    path_id = Column(Integer, ForeignKey("paths.id"))
    puzzle_id = Column(Integer, ForeignKey("puzzles.id"))
    order = Column(Integer)

    path = relationship("Path", back_populates="puzzles")
    puzzle = relationship("Puzzle", back_populates="path_puzzles")


class Completion(Base):
    __tablename__ = "completions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    path_id = Column(Integer, ForeignKey("paths.id"))
    puzzle_id = Column(Integer, ForeignKey("puzzles.id"))
    time_taken = Column(Integer, nullable=True)  # milliseconds
    completed_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="completions")
    path = relationship("Path", back_populates="completions")


class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    friend_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", foreign_keys=[user_id], back_populates="friendships")
