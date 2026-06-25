"""카카오 로컬 API — 반경 내 카페 검색"""

import httpx

from api.config import settings

KAKAO_LOCAL_URL = "https://dapi.kakao.com/v2/local/search/category.json"


async def search_cafes_nearby(
    lat: float,
    lng: float,
    radius_m: int = 1000,
    max_results: int = 20,
) -> list[dict]:
    """
    카카오 로컬 카테고리 검색으로 반경 내 카페 목록을 가져온다.
    카테고리 코드 CE7 = 카페
    """
    headers = {"Authorization": f"KakaoAK {settings.kakao_api_key}"}
    results = []
    page = 1

    async with httpx.AsyncClient(timeout=10.0) as client:
        while len(results) < max_results:
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

            documents = data.get("documents", [])
            if not documents:
                break

            results.extend(documents)
            if data["meta"].get("is_end", True):
                break
            page += 1

    return results[:max_results]


def parse_kakao_cafe(doc: dict) -> dict:
    """카카오 API 응답 document를 내부 포맷으로 변환"""
    return {
        "kakao_id": doc["id"],
        "name": doc["place_name"],
        "address": doc.get("road_address_name") or doc.get("address_name", ""),
        "latitude": float(doc["y"]),
        "longitude": float(doc["x"]),
        "phone": doc.get("phone") or None,
        "kakao_url": doc.get("place_url") or None,
        "distance_m": int(doc.get("distance", 0)),
    }
