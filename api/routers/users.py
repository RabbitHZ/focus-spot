from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from api.db.database import get_db
from api.db.redis import get_cached_preferences, invalidate_preferences, set_cached_preferences
from api.models.user import User
from api.routers.deps import get_current_user

router = APIRouter()


class PreferencesRequest(BaseModel):
    preferred_noise: str | None = None
    preferred_space: str | None = None
    required_tags: list[str] | None = None
    radius_km: float | None = None


class PreferencesResponse(BaseModel):
    preferred_noise: str | None
    preferred_space: str | None
    required_tags: list[str]
    radius_km: float


def _to_dict(user: User) -> dict:
    return {
        "preferred_noise": user.preferred_noise,
        "preferred_space": user.preferred_space,
        "required_tags": user.required_tags or [],
        "radius_km": user.radius_km or 1.0,
    }


@router.get("/me/preferences", response_model=PreferencesResponse)
async def get_preferences(
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    cached = await get_cached_preferences(user_id)
    if cached:
        return PreferencesResponse(**cached)

    user = await db.get(User, user_id)
    prefs = _to_dict(user)
    await set_cached_preferences(user_id, prefs)
    return PreferencesResponse(**prefs)


@router.patch("/me/preferences", response_model=PreferencesResponse)
async def update_preferences(
    body: PreferencesRequest,
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    user = await db.get(User, user_id)
    if body.preferred_noise is not None:
        user.preferred_noise = body.preferred_noise
    if body.preferred_space is not None:
        user.preferred_space = body.preferred_space
    if body.required_tags is not None:
        user.required_tags = body.required_tags
    if body.radius_km is not None:
        user.radius_km = body.radius_km
    await db.commit()
    await db.refresh(user)

    prefs = _to_dict(user)
    # DB 저장 후 캐시 즉시 갱신 — 다음 추천 요청부터 바로 반영
    await set_cached_preferences(user_id, prefs)
    return PreferencesResponse(**prefs)
