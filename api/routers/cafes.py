import asyncio

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.db.database import get_db
from api.models.cafe import Cafe
from api.models.health_data import HealthData
from api.routers.deps import get_current_user
from api.services.cafe_recommender import score_cafe
from api.services.condition import CONDITION_CAFE_HINTS, CONDITION_LABELS, analyze_condition
from api.services.kakao import parse_kakao_cafe, search_cafes_nearby
from api.services.review_scraper import infer_tags_from_reviews

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
    match_pct: int  # 0–100, 컨디션 매치율 %
    tag_source: str  # "review" | "ai_infer" | "cached"


class RecommendResponse(BaseModel):
    mode: str
    mode_label: str
    cafes: list[CafeCard]


async def _scrape_tags(kakao_data: dict) -> tuple[dict, str]:
    """네트워크 I/O만 담당 — DB 접근 없음. 병렬 실행용."""
    tags = await infer_tags_from_reviews(
        kakao_data["kakao_id"],
        kakao_data["name"],
        kakao_data["address"],
    )
    source = tags.pop("_source", "ai_infer")
    tags.pop("_review_waiting", None)
    return tags, source


async def _get_or_create_cafe(db: AsyncSession, kakao_data: dict, tags: dict, source: str) -> tuple[Cafe, str]:
    """DB 캐시 조회 후 없으면 저장. 이미 스크래핑된 tags를 받아 저장만 담당."""
    kakao_id = kakao_data["kakao_id"]

    cafe = await db.scalar(select(Cafe).where(Cafe.kakao_id == kakao_id))
    if cafe:
        return cafe, "cached"

    cafe = Cafe(
        kakao_id=kakao_id,
        name=kakao_data["name"],
        address=kakao_data["address"],
        latitude=kakao_data["latitude"],
        longitude=kakao_data["longitude"],
        phone=kakao_data["phone"],
        kakao_url=kakao_data["kakao_url"],
        noise_level=tags.get("noise_level"),
        lighting=tags.get("lighting"),
        space_type=tags.get("space_type"),
        work_tags=tags.get("work_tags", []),
    )
    db.add(cafe)
    await db.flush()
    return cafe, source


def _score_to_match_pct(score: float) -> int:
    """0–1 범위 score를 사용자에게 보여줄 50–99% 범위로 변환한다."""
    pct = 50 + round(score * 49)
    return max(50, min(99, pct))


@router.get("/recommend", response_model=RecommendResponse)
async def recommend_cafes(
    lat: float = Query(..., description="사용자 위도"),
    lng: float = Query(..., description="사용자 경도"),
    radius_km: float = Query(1.0, description="검색 반경 (km)"),
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    # 1. 사용자 컨디션 분석
    latest = await db.scalar(
        select(HealthData)
        .where(HealthData.user_id == user_id)
        .order_by(HealthData.recorded_at.desc())
        .limit(1)
    )
    if not latest:
        raise HTTPException(status_code=404, detail="건강 데이터가 없습니다.")

    mode, _ = analyze_condition(latest)

    # 2. 카카오 로컬 API로 반경 내 카페 검색 (가까운 순)
    try:
        kakao_docs = await search_cafes_nearby(lat, lng, radius_m=int(radius_km * 1000))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"카카오 API 오류: {e}")

    if not kakao_docs:
        return RecommendResponse(mode=mode, mode_label=CONDITION_LABELS[mode], cafes=[])

    # 3. DB 캐시 조회 / 리뷰 스크래핑 → AI 추론 태그 생성 후 저장
    # DB에 없는 카페만 병렬 스크래핑, DB 저장은 순차
    parsed_docs = [parse_kakao_cafe(doc) for doc in kakao_docs]

    cached_map: dict[str, Cafe] = {}
    for row in await db.scalars(
        select(Cafe).where(Cafe.kakao_id.in_([p["kakao_id"] for p in parsed_docs]))
    ):
        cached_map[row.kakao_id] = row

    new_docs = [p for p in parsed_docs if p["kakao_id"] not in cached_map]
    scraped_map: dict[str, tuple[dict, str]] = {}
    if new_docs:
        results = await asyncio.gather(*[_scrape_tags(p) for p in new_docs])
        scraped_map = {p["kakao_id"]: r for p, r in zip(new_docs, results)}

    cafes: list[tuple[Cafe, int, str]] = []
    for parsed in parsed_docs:
        kid = parsed["kakao_id"]
        if kid in cached_map:
            cafes.append((cached_map[kid], parsed["distance_m"], "cached"))
        else:
            tags, source = scraped_map[kid]
            cafe, source = await _get_or_create_cafe(db, parsed, tags, source)
            cafes.append((cafe, parsed["distance_m"], source))

    await db.commit()

    # 4. 컨디션 기반 스코어링 → 상위 10개
    scored = sorted(
        [
            (cafe, dist, source, score_cafe(cafe, mode, lat, lng, radius_km))
            for cafe, dist, source in cafes
        ],
        key=lambda x: x[3],
        reverse=True,
    )[:10]

    return RecommendResponse(
        mode=mode,
        mode_label=CONDITION_LABELS[mode],
        cafes=[
            CafeCard(
                id=cafe.id,
                name=cafe.name,
                address=cafe.address,
                distance_m=dist,
                noise_level=cafe.noise_level,
                lighting=cafe.lighting,
                work_tags=cafe.work_tags or [],
                kakao_url=cafe.kakao_url,
                recommendation_reason=CONDITION_CAFE_HINTS[mode],
                score=round(s, 3),
                match_pct=_score_to_match_pct(s),
                tag_source=source,
            )
            for cafe, dist, source, s in scored
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
        match_pct=0,
        tag_source="cached",
    )
