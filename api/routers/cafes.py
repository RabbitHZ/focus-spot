from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.db.database import get_db
from api.models.cafe import Cafe
from api.models.health_data import HealthData
from api.routers.deps import get_current_user
from api.services.cafe_recommender import score_cafe
from api.services.condition import CONDITION_CAFE_HINTS, analyze_condition

router = APIRouter()


class CafeCard(BaseModel):
    id: int
    name: str
    address: str
    distance_m: int
    noise_level: str | None
    lighting: str | None
    work_tags: list[str]
    kakao_url: str | None
    recommendation_reason: str
    score: float


class RecommendResponse(BaseModel):
    mode: str
    mode_label: str
    cafes: list[CafeCard]


@router.get("/recommend", response_model=RecommendResponse)
async def recommend_cafes(
    lat: float = Query(..., description="사용자 위도"),
    lng: float = Query(..., description="사용자 경도"),
    radius_km: float = Query(1.0, description="검색 반경 (km)"),
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    latest = await db.scalar(
        select(HealthData)
        .where(HealthData.user_id == user_id)
        .order_by(HealthData.recorded_at.desc())
        .limit(1)
    )
    if not latest:
        raise HTTPException(status_code=404, detail="건강 데이터가 없습니다.")

    mode, _ = analyze_condition(latest)

    cafes = list(
        await db.scalars(
            select(Cafe).limit(200)  # MVP: 전체 풀에서 스코어링
        )
    )

    scored = sorted(
        [(cafe, score_cafe(cafe, mode, lat, lng, radius_km)) for cafe in cafes],
        key=lambda x: x[1],
        reverse=True,
    )[:5]

    from api.services.condition import CONDITION_LABELS
    import math

    def dist_m(cafe: Cafe) -> int:
        from api.services.cafe_recommender import _haversine
        return int(_haversine(lat, lng, cafe.latitude, cafe.longitude) * 1000)

    return RecommendResponse(
        mode=mode,
        mode_label=CONDITION_LABELS[mode],
        cafes=[
            CafeCard(
                id=cafe.id,
                name=cafe.name,
                address=cafe.address,
                distance_m=dist_m(cafe),
                noise_level=cafe.noise_level,
                lighting=cafe.lighting,
                work_tags=cafe.work_tags or [],
                kakao_url=cafe.kakao_url,
                recommendation_reason=CONDITION_CAFE_HINTS[mode],
                score=round(s, 3),
            )
            for cafe, s in scored
        ],
    )


@router.get("/{cafe_id}", response_model=CafeCard)
async def get_cafe(cafe_id: int, db: AsyncSession = Depends(get_db)):
    cafe = await db.get(Cafe, cafe_id)
    if not cafe:
        raise HTTPException(status_code=404, detail="카페를 찾을 수 없습니다.")
    return CafeCard(
        id=cafe.id,
        name=cafe.name,
        address=cafe.address,
        distance_m=0,
        noise_level=cafe.noise_level,
        lighting=cafe.lighting,
        work_tags=cafe.work_tags or [],
        kakao_url=cafe.kakao_url,
        recommendation_reason="",
        score=0,
    )
