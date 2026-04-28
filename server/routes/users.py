from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from db.database import get_db
from models.models import User as UserModel
from schemas.schemas import User, UserCreate, TokenResponse, LoginRequest, OAuthLoginRequest
from auth import get_password_hash, verify_password, create_access_token, get_current_user
from oauth import verify_google_token, verify_apple_token, get_or_create_oauth_user

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/register", response_model=TokenResponse)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = get_password_hash(user.password)
    db_user = UserModel(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,
        display_name=user.display_name,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    access_token = create_access_token(data={"sub": db_user.id})
    return TokenResponse(access_token=access_token, token_type="bearer", user=User.model_validate(db_user))


@router.post("/login", response_model=TokenResponse)
def login_user(credentials: LoginRequest, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.email == credentials.email).first()
    if not db_user or not verify_password(credentials.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    access_token = create_access_token(data={"sub": db_user.id})
    return TokenResponse(access_token=access_token, token_type="bearer", user=User.model_validate(db_user))


@router.get("/me", response_model=User)
def get_current_user_profile(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == current_user["user_id"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/{user_id}", response_model=User)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("/oauth/google", response_model=TokenResponse)
def oauth_google(request: OAuthLoginRequest, db: Session = Depends(get_db)):
    try:
        user_info = verify_google_token(request.id_token)
        user, token = get_or_create_oauth_user(db, 'google', user_info)
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            user=User.model_validate(user),
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OAuth verification failed",
        )


@router.post("/oauth/apple", response_model=TokenResponse)
def oauth_apple(request: OAuthLoginRequest, db: Session = Depends(get_db)):
    try:
        user_info = verify_apple_token(request.id_token)
        user, token = get_or_create_oauth_user(db, 'apple', user_info)
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            user=User.model_validate(user),
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OAuth verification failed",
        )
