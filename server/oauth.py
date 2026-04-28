import os
from datetime import datetime
from typing import Dict, Tuple

import jwt
import requests
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy.orm import Session

from auth import create_access_token
from models.models import User

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
APPLE_TEAM_ID = os.getenv("APPLE_TEAM_ID")
APPLE_SERVICE_ID = os.getenv("APPLE_SERVICE_ID")
APPLE_KEY_ID = os.getenv("APPLE_KEY_ID")
APPLE_PRIVATE_KEY = os.getenv("APPLE_PRIVATE_KEY")


def verify_google_token(token_str: str) -> Dict:
    """Verify a Google token (ID token or access token) and return user info.

    Android/iOS return an ID token; the google_sign_in web SDK returns an
    access token. Try ID-token verification first, then fall back to the
    userinfo endpoint for access tokens.
    """
    try:
        try:
            idinfo = google_id_token.verify_oauth2_token(
                token_str, google_requests.Request(), GOOGLE_CLIENT_ID
            )
            return {
                'sub': idinfo['sub'],
                'email': idinfo.get('email'),
                'name': idinfo.get('name'),
                'picture': idinfo.get('picture'),
                'provider': 'google',
            }
        except Exception:
            userinfo_response = requests.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {token_str}'},
                timeout=5,
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
    """Verify an Apple ID token and return user information."""
    try:
        # TODO: Verify signature against Apple's public keys in production.
        payload = jwt.decode(
            id_token_str,
            options={"verify_signature": False},
        )

        if payload.get('iss') != 'https://appleid.apple.com':
            raise ValueError("Invalid issuer")

        if payload.get('aud') != APPLE_SERVICE_ID:
            raise ValueError(f"Invalid audience. Expected {APPLE_SERVICE_ID}")

        if payload.get('exp', 0) < datetime.utcnow().timestamp():
            raise ValueError("Token expired")

        return {
            'sub': payload.get('sub'),
            'email': payload.get('email'),
            'email_verified': payload.get('email_verified', False),
            'provider': 'apple',
        }
    except ValueError:
        raise
    except Exception as e:
        raise ValueError(f"Invalid Apple token: {str(e)}")


def get_or_create_oauth_user(
    db: Session,
    provider: str,
    user_info: Dict,
) -> Tuple[User, str]:
    """Find or create a user from an OAuth identity. Auto-links by email."""
    oauth_sub = user_info.get('sub')
    email = user_info.get('email')
    name = user_info.get('name') or (email.split('@')[0] if email else 'OAuth User')

    if not oauth_sub:
        raise ValueError("Missing 'sub' in OAuth token")
    if not email:
        raise ValueError("Missing 'email' in OAuth token")

    user = db.query(User).filter(User.oauth_sub == oauth_sub).first()
    if user:
        return user, create_access_token({'sub': user.id})

    user = db.query(User).filter(User.email == email).first()
    if user:
        user.oauth_provider = provider
        user.oauth_sub = oauth_sub
        db.commit()
        db.refresh(user)
        return user, create_access_token({'sub': user.id})

    user = User(
        email=email,
        username=email.split('@')[0],
        display_name=name,
        hashed_password='',
        oauth_provider=provider,
        oauth_sub=oauth_sub,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return user, create_access_token({'sub': user.id})
