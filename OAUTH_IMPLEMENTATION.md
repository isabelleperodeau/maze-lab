# OAuth Implementation Guide - Google & Apple Sign-In

This document provides step-by-step instructions for implementing Google and Apple OAuth authentication in the Maze Lab backend.

## Overview

The Flutter frontend now sends OAuth ID tokens to the backend for verification. The backend must:
1. Verify tokens with Google/Apple
2. Create or link user accounts based on OAuth identity
3. Return a JWT token for session management

## Prerequisites

### 1. Install Dependencies

```bash
pip install google-auth
```

Ensure your `requirements.txt` includes:
- `google-auth` (for Google token verification)
- `PyJWT` (already included, for Apple token verification)
- `python-jose` (already included)

### 2. Update `.env` with OAuth Credentials

Add the following to your `.env` file:

```env
# Google OAuth
GOOGLE_CLIENT_ID=<your-google-client-id>

# Apple Sign In
APPLE_TEAM_ID=<your-apple-team-id>
APPLE_SERVICE_ID=<your-apple-service-id>
APPLE_KEY_ID=<your-apple-key-id>
APPLE_PRIVATE_KEY=<your-apple-private-key>
```

**How to obtain these credentials:**

#### Google OAuth Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Enable the "Google+ API"
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
5. Select "Web application" (and optionally "Android" / "iOS" if deploying to mobile)
6. Copy the `Client ID` to `GOOGLE_CLIENT_ID` in `.env`
7. Note: For mobile OAuth, the client secret is not needed (handled by the SDK)

#### Apple Sign In Credentials
1. Go to [Apple Developer](https://developer.apple.com)
2. Sign in with your Apple Developer account
3. Go to "Identifiers" and create a new "Service ID" for your app
4. Configure "Sign in with Apple" for this Service ID
5. Go to "Keys" and create a new key with "Sign in with Apple" capability
6. Download the `.p8` file (contains the private key)
7. Extract and record:
   - `APPLE_TEAM_ID` - Found in top-right of Apple Developer account
   - `APPLE_SERVICE_ID` - The Service ID identifier (e.g., `com.example.maze-lab`)
   - `APPLE_KEY_ID` - The key identifier shown in the key details
   - `APPLE_PRIVATE_KEY` - Content of the downloaded `.p8` file

---

## Database Schema Changes

### 1. Update User Model

Edit `server/models/models.py` and add these fields to the `User` class:

```python
from typing import Optional

class User(Base):
    __tablename__ = "users"
    
    # ... existing fields ...
    
    # OAuth fields (NEW)
    oauth_provider = Column(String, nullable=True)  # 'google', 'apple', or None
    oauth_sub = Column(String, nullable=True, index=True)  # OAuth provider's unique ID
```

### 2. Create Database Migration

```bash
alembic revision --autogenerate -m "Add OAuth fields to User model"
```

Review the generated migration file in `alembic/versions/`, then apply it:

```bash
alembic upgrade head
```

---

## Backend Implementation

### 1. Create `server/oauth.py`

Create a new file `server/oauth.py` with OAuth token verification functions:

```python
import os
from datetime import datetime, timedelta
from typing import Dict, Optional
import jwt
from google.auth.transport import requests
from google.oauth2 import id_token
from db.database import SessionLocal
from models.models import User
from auth import create_access_token
from sqlalchemy.orm import Session

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
APPLE_TEAM_ID = os.getenv("APPLE_TEAM_ID")
APPLE_SERVICE_ID = os.getenv("APPLE_SERVICE_ID")
APPLE_KEY_ID = os.getenv("APPLE_KEY_ID")
APPLE_PRIVATE_KEY = os.getenv("APPLE_PRIVATE_KEY")


def verify_google_token(token_str: str) -> Dict:
    """
    Verify a Google token (ID token or access token) and return user information.
    
    Args:
        token_str: The token from Google Sign-In (ID token or access token)
        
    Returns:
        Dictionary with 'sub' (unique ID), 'email', 'name', 'picture'
        
    Raises:
        ValueError: If token is invalid or verification fails
        
    Note:
        - On Android/iOS: Receives ID token
        - On Web: Receives access token (google_sign_in web SDK returns access token)
    """
    try:
        # First, try to verify as ID token
        try:
            idinfo = id_token.verify_oauth2_token(
                token_str, requests.Request(), GOOGLE_CLIENT_ID
            )
            return {
                'sub': idinfo['sub'],
                'email': idinfo.get('email'),
                'name': idinfo.get('name'),
                'picture': idinfo.get('picture'),
                'provider': 'google',
            }
        except Exception:
            # If ID token verification fails, try treating it as an access token
            # Call Google's userinfo API to get user information
            userinfo_response = requests.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {token_str}'},
                timeout=5
            )
            
            if userinfo_response.status_code != 200:
                raise ValueError("Invalid access token")
            
            userinfo = userinfo_response.json()
            return {
                'sub': userinfo.get('id'),
                'email': userinfo.get('email'),
                'name': userinfo.get('name'),
                'picture': userinfo.get('picture'),
                'provider': 'google',
            }
    except Exception as e:
        raise ValueError(f"Invalid Google token: {str(e)}")


def verify_apple_token(id_token_str: str) -> Dict:
    """
    Verify an Apple ID token and return user information.
    
    Args:
        id_token_str: The ID token from Sign in with Apple
        
    Returns:
        Dictionary with 'sub' (unique ID), 'email'
        
    Raises:
        ValueError: If token is invalid or verification fails
    """
    try:
        # Decode without verification first (Apple tokens are self-issued)
        # In production, you should verify the signature using Apple's public key
        payload = jwt.decode(
            id_token_str, 
            options={"verify_signature": False}  # TODO: Verify signature in production
        )
        
        # Verify issuer and audience
        if payload.get('iss') != 'https://appleid.apple.com':
            raise ValueError("Invalid issuer")
        
        if payload.get('aud') != APPLE_SERVICE_ID:
            raise ValueError(f"Invalid audience. Expected {APPLE_SERVICE_ID}")
        
        # Verify expiration
        if payload.get('exp', 0) < datetime.utcnow().timestamp():
            raise ValueError("Token expired")
        
        return {
            'sub': payload.get('sub'),  # Unique identifier from Apple
            'email': payload.get('email'),
            'email_verified': payload.get('email_verified', False),
            'provider': 'apple',
        }
    except Exception as e:
        raise ValueError(f"Invalid Apple token: {str(e)}")


def get_or_create_oauth_user(
    db: Session, 
    provider: str, 
    user_info: Dict
) -> tuple[User, str]:
    """
    Find or create a user based on OAuth identity. Auto-links by email.
    
    Args:
        db: Database session
        provider: 'google' or 'apple'
        user_info: Dictionary from verify_*_token() with 'sub', 'email', 'name'
        
    Returns:
        Tuple of (User object, JWT token)
        
    Raises:
        ValueError: If required fields are missing
    """
    oauth_sub = user_info.get('sub')
    email = user_info.get('email')
    name = user_info.get('name', email.split('@')[0] if email else 'OAuth User')
    
    if not oauth_sub:
        raise ValueError("Missing 'sub' in OAuth token")
    
    if not email:
        raise ValueError("Missing 'email' in OAuth token")
    
    # Try to find existing user by oauth_sub (exact match)
    user = db.query(User).filter(User.oauth_sub == oauth_sub).first()
    
    if user:
        # User already exists with this OAuth provider
        return user, create_access_token({'sub': user.id})
    
    # Try to find existing user by email (auto-link)
    user = db.query(User).filter(User.email == email).first()
    
    if user:
        # Link existing user to this OAuth provider
        user.oauth_provider = provider
        user.oauth_sub = oauth_sub
        db.commit()
        return user, create_access_token({'sub': user.id})
    
    # Create new user
    user = User(
        email=email,
        username=email.split('@')[0],  # Use email prefix as username
        display_name=name,
        hashed_password='',  # No password for OAuth users
        oauth_provider=provider,
        oauth_sub=oauth_sub,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return user, create_access_token({'sub': user.id})
```

### 2. Update `server/routes/users.py`

Add these endpoints to `server/routes/users.py`:

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from db.database import get_db
from schemas.schemas import TokenResponse, OAuthLoginRequest
from oauth import verify_google_token, verify_apple_token, get_or_create_oauth_user
import models.models as models

router = APIRouter(prefix="/users", tags=["users"])

# ... existing endpoints ...

@router.post("/oauth/google", response_model=TokenResponse)
def oauth_google(
    request: OAuthLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Verify Google ID token and return JWT for session management.
    
    Request body:
    {
      "id_token": "<google-id-token>"
    }
    """
    try:
        # Verify token and extract user info
        user_info = verify_google_token(request.id_token)
        
        # Find or create user, get JWT
        user, token = get_or_create_oauth_user(db, 'google', user_info)
        
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            user={
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "display_name": user.display_name,
                "avatar_url": user.avatar_url,
            }
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OAuth verification failed"
        )


@router.post("/oauth/apple", response_model=TokenResponse)
def oauth_apple(
    request: OAuthLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Verify Apple ID token and return JWT for session management.
    
    Request body:
    {
      "id_token": "<apple-id-token>"
    }
    """
    try:
        # Verify token and extract user info
        user_info = verify_apple_token(request.id_token)
        
        # Find or create user, get JWT
        user, token = get_or_create_oauth_user(db, 'apple', user_info)
        
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            user={
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "display_name": user.display_name,
                "avatar_url": user.avatar_url,
            }
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OAuth verification failed"
        )
```

### 3. Update `server/schemas/schemas.py`

Add this schema for OAuth requests:

```python
class OAuthLoginRequest(BaseModel):
    """OAuth ID token from frontend"""
    id_token: str
```

### 4. Update `server/requirements.txt`

Add `google-auth` if not already present:

```
google-auth==2.25.2
```

---

## Testing

### 1. Test with cURL

Once the endpoints are deployed, test with valid OAuth ID tokens:

```bash
# Replace with actual Google ID token from frontend
curl -X POST http://192.168.101.18:8000/oauth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "<actual-google-id-token>"}'

# Should return:
# {
#   "access_token": "<jwt-token>",
#   "token_type": "bearer",
#   "user": { ... }
# }
```

### 2. Test Invalid Tokens

```bash
# Test with invalid token
curl -X POST http://192.168.101.18:8000/oauth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "invalid-token"}'

# Should return 401 Unauthorized
```

### 3. End-to-End Test

1. Start the Flutter app on the user's machine
2. Tap "Sign in with Google"
3. Complete Google OAuth flow
4. App should navigate to home screen
5. Check database: new user created with `oauth_provider='google'`, `oauth_sub=<google-id>`

---

## Notes

### Apple Token Signature Verification (Production)

The current `verify_apple_token()` implementation skips signature verification (`verify_signature=False`). For production, you should:

1. Download Apple's public keys from `https://appleid.apple.com/auth/keys`
2. Cache them locally (they change infrequently)
3. Verify the token signature using the appropriate key

Example:

```python
import requests
from cryptography.hazmat.primitives import serialization

# Download Apple's public keys
response = requests.get('https://appleid.apple.com/auth/keys')
keys = response.json()['keys']

# Find the key matching the token's 'kid' header
token_header = jwt.get_unverified_header(id_token_str)
kid = token_header['kid']

matching_key = next((k for k in keys if k['kid'] == kid), None)
if not matching_key:
    raise ValueError("Key not found")

# Convert JWK to PEM and verify
public_key = convert_jwk_to_pem(matching_key)
payload = jwt.decode(id_token_str, public_key, algorithms=['RS256'], audience=APPLE_SERVICE_ID)
```

### CORS & Origin Verification

Ensure your FastAPI CORS configuration allows requests from the Flutter app:

```python
# Already configured in main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### User Account Linking

The current implementation **auto-links by email**. This means:
- If a user signs up with Google using `user@example.com`
- Then signs in with Apple using the same email
- The system recognizes them as the same user and links the Apple provider

To change this behavior, modify the `get_or_create_oauth_user()` function in `oauth.py`.

---

## Deployment Checklist

- [ ] Install `google-auth` dependency
- [ ] Update `.env` with Google and Apple credentials
- [ ] Create database migration and apply it
- [ ] Create `server/oauth.py` with verification functions
- [ ] Add OAuth endpoints to `server/routes/users.py`
- [ ] Add `OAuthLoginRequest` schema to `server/schemas/schemas.py`
- [ ] Test endpoints with cURL
- [ ] Deploy to 192.168.101.18:8000
- [ ] Test end-to-end with Flutter app

---

## Troubleshooting

**Issue: "Invalid Google token"**
- Check that `GOOGLE_CLIENT_ID` matches the client ID from Google Cloud Console
- Ensure the token is fresh (not expired)

**Issue: "Invalid audience" for Apple token**
- Verify `APPLE_SERVICE_ID` matches the Service ID in Apple Developer account
- Check that the frontend is passing the correct Service ID to SignInWithApple

**Issue: User not created**
- Check database logs for constraint violations (e.g., duplicate email)
- Ensure `oauth_sub` and `oauth_provider` are not null for OAuth users

---

For questions or updates, refer to this guide or the Maze Lab CLAUDE.md file.
