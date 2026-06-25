"""카카오 로컬 API로 강남/홍대/성수 카페를 가져와 네이버 리뷰 태그를 붙여 DB에 저장한다.

사용법:
    PYTHONPATH=. uv run --project api python api/scripts/seed_cafes_auto.py
"""

import asyncio
import sys

import httpx
from sqlalchemy import select

from api.config import settings
from api.db.database import AsyncSessionLocal
from api.models.cafe import Cafe
from api.services.kakao import parse_kakao_cafe
from api.services.review_scraper import infer_tags_from_reviews

# 지역 중심좌표 + 검색 반경
REGIONS = [
    {"name": "강남", "lat": 37.5172, "lng": 127.0473, "radius_m": 2000, "limit": 30},
    {"name": "홍대", "lat": 37.5519, "lng": 126.9245, "radius_m": 1500, "limit": 30},
    {"name": "성수", "lat": 37.5443, "lng": 127.0557, "radius_m": 1500, "limit": 30},
]

KAKAO_LOCAL_URL = "https://dapi.kakao.com/v2/local/search/category.json"
CONCURRENCY = 5  # 동시 스크래핑 수


async def fetch_kakao_cafes(lat: float, lng: float, radius_m: int, limit: int) -> list[dict]:
    headers = {"Authorization": f"KakaoAK {settings.kakao_api_key}"}
    results = []
    page = 1

    async with httpx.AsyncClient(timeout=10.0) as client:
        while len(results) < limit:
            params = {
                "category_group_code": "CE7",
                "x": str(lng),
                "y": str(lat),
                "radius": str(radius_m),
                "size": 15,
                "page": page,
                "sort": "distance",
            }
            resp = await client.get(KAKAO_LOCAL_URL, headers=headers, params=params)
            resp.raise_for_status()
            data = resp.json()

            docs = data.get("documents", [])
            if not docs:
                break
            results.extend(docs)
            if data["meta"].get("is_end", True):
                break
            page += 1

    return results[:limit]


async def scrape_tags(sem: asyncio.Semaphore, parsed: dict) -> dict:
    """네이버 스크래핑 → AI fallback으로 태그 추출. DB 접근 없음."""
    async with sem:
        try:
            tags = await infer_tags_from_reviews(
                parsed["kakao_id"], parsed["name"], parsed["address"]
            )
        except Exception as e:
            print(f"  [오류] {parsed['name']}: {e}", file=sys.stderr)
            tags = {"_source": "error"}
    return tags


async def main() -> None:
    if not settings.kakao_api_key:
        print("KAKAO_API_KEY가 설정되지 않았습니다.", file=sys.stderr)
        sys.exit(1)

    sem = asyncio.Semaphore(CONCURRENCY)
    total_saved = total_skipped = total_error = 0

    for region in REGIONS:
        print(f"\n[{region['name']}] 카카오 API 조회 중...")
        try:
            docs = await fetch_kakao_cafes(
                region["lat"], region["lng"], region["radius_m"], region["limit"]
            )
        except Exception as e:
            print(f"  카카오 API 오류: {e}", file=sys.stderr)
            continue

        parsed_list = [parse_kakao_cafe(doc) for doc in docs]
        print(f"  {len(parsed_list)}개 카페 발견 → 태그 추출 시작 (병렬 {CONCURRENCY}개)")

        # 1단계: 스크래핑을 병렬로 모두 완료 (DB 세션 밖에서)
        tag_results = await asyncio.gather(*[scrape_tags(sem, p) for p in parsed_list])

        # 2단계: DB에 순차 저장 (세션 하나로 직렬 처리)
        async with AsyncSessionLocal() as session:
            saved = skipped = error = 0
            for parsed, tags in zip(parsed_list, tag_results):
                kakao_id = parsed["kakao_id"]
                existing = await session.scalar(select(Cafe).where(Cafe.kakao_id == kakao_id))
                if existing:
                    skipped += 1
                    continue

                source = tags.pop("_source", "?")
                if source == "error":
                    error += 1
                    continue
                tags.pop("_review_waiting", None)

                cafe = Cafe(
                    kakao_id=kakao_id,
                    name=parsed["name"],
                    address=parsed["address"],
                    latitude=parsed["latitude"],
                    longitude=parsed["longitude"],
                    phone=parsed["phone"],
                    kakao_url=parsed["kakao_url"],
                    noise_level=tags.get("noise_level"),
                    lighting=tags.get("lighting"),
                    space_type=tags.get("space_type"),
                    work_tags=tags.get("work_tags", []),
                )
                session.add(cafe)
                label = "태그없음" if source == "no_data" else source
                print(f"  ✓ {parsed['name']} [{label}]")
                saved += 1

            await session.commit()

        total_saved += saved
        total_skipped += skipped
        total_error += error
        print(f"  → 저장 {saved} / 스킵(이미 존재) {skipped} / 오류 {error}")

    print(f"\n완료: 총 저장 {total_saved}개, 스킵 {total_skipped}개, 오류 {total_error}개")


if __name__ == "__main__":
    asyncio.run(main())
