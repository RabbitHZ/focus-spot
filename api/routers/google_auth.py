import asyncio

from fastapi import APIRouter, Depends, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.config import settings
from api.db.database import get_db
from api.models.user import User
from api.routers.auth import TokenResponse, create_token

router = APIRouter()


class GoogleTokenRequest(BaseModel):
    id_token: str


async def _verify_google_token(token: str) -> dict:
    """Google id_token 검증 — 웹/iOS 클라이언트 ID 모두 허용."""
    allowed = [settings.google_client_id]
    if settings.google_ios_client_id:
        allowed.append(settings.google_ios_client_id)

    loop = asyncio.get_event_loop()

    import logging

    for client_id in allowed:
        try:
            return await loop.run_in_executor(
                None,
                lambda cid=client_id: google_id_token.verify_oauth2_token(
                    token,
                    google_requests.Request(),
                    cid,
                    clock_skew_in_seconds=10,
                ),
            )
        except Exception as e:
            logging.warning(f"[google_auth] client_id={client_id} error={type(e).__name__}: {e}")
            continue

    raise ValueError("No matching client_id")


@router.post("/google", response_model=TokenResponse)
async def google_login(body: GoogleTokenRequest, db: AsyncSession = Depends(get_db)):
    try:
        idinfo = await _verify_google_token(body.id_token)
    except ValueError:
        raise HTTPException(status_code=401, detail="유효하지 않은 Google 토큰입니다.")

    email = idinfo["email"]

    user = await db.scalar(select(User).where(User.email == email))
    if not user:
        user = User(email=email, hashed_password=None)
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return TokenResponse(access_token=create_token(user.id))
