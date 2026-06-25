"""네이버 플레이스 방문자 리뷰 API에서 키워드를 추출해 카페 태그를 반환한다.

흐름:
  1. 네이버 통합검색(where=place)으로 카페명 검색 → place ID 추출
  2. pcmap-api.place.naver.com GraphQL API로 방문자 리뷰 수집 (최대 60개)
  3. 리뷰 텍스트에서 정규식 키워드 카운팅 → 카페 속성 태그 변환
  4. 태그 추출 실패 시 Claude API fallback (이름/주소 추론)
"""

import re

import httpx

_NAVER_SEARCH_URL = "https://search.naver.com/search.naver"
_GRAPHQL_URL = "https://pcmap-api.place.naver.com/place/graphql"

_HEADERS_PC = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "ko-KR,ko;q=0.9",
}

_VISITOR_REVIEWS_QUERY = """
query getVisitorReviews($input: VisitorReviewsInput) {
    visitorReviews(input: $input) {
        items {
            id
            cursor
            body
        }
        total
    }
}
"""

# 키워드 → 정규식 (방문자 리뷰 텍스트 대상)
_PATTERNS: list[tuple[str, re.Pattern]] = [
    ("wifi_good", re.compile(r"와이파이\s*(빠르|잘\s*돼|좋|빵빵|빠름|무료|터져)", re.I)),
    ("wifi_bad", re.compile(r"와이파이\s*(느리|안\s*돼|없|불안정|약해|끊)", re.I)),
    ("power_outlet", re.compile(r"콘센트\s*(있|많|곳곳|여러|충분|넉넉)", re.I)),
    ("no_outlet", re.compile(r"콘센트\s*(없|부족|못\s*찾|거의\s*없)", re.I)),
    (
        "work_friendly",
        re.compile(
            r"(공부|작업|업무|노트북\s*가능|작업\s*하기|공부하기|공부\s*하러|작업\s*하러|업무\s*보러|노트북\s*들고)",
            re.I,
        ),
    ),
    (
        "no_laptop",
        re.compile(
            r"(노트북\s*안\s*돼|노트북\s*금지|노트북\s*못|작업\s*하기\s*어|공부\s*하기\s*어)", re.I
        ),
    ),
    ("quiet", re.compile(r"(조용|한적|소음\s*없|소음.*적|차분|고요|조용한)", re.I)),
    ("noisy", re.compile(r"(시끄|시끌|소음\s*(심|많|커|크)|음악.*크게|북적|왁자)", re.I)),
    ("bright", re.compile(r"(밝은?|채광\s*좋|햇빛|자연광|환한?|환해|햇살)", re.I)),
    ("dim", re.compile(r"(어둡|아늑|감성|무드|어두운|아늑한)", re.I)),
    ("spacious", re.compile(r"(넓|자리\s*(많|넉넉|여유|충분)|여유\s*있|널찍|탁 트|탁트)", re.I)),
    ("crowded", re.compile(r"(자리\s*(없|부족|꽉|모자)|항상\s*붐|대기\s*있|만석|자리\s*없)", re.I)),
    (
        "waiting",
        re.compile(r"(웨이팅|대기\s*(있|길|많|번호)|줄\s*(섰|있|서야)|번호표|웨이팅\s*있)", re.I),
    ),
    (
        "easy_to_seat",
        re.compile(
            r"(자리\s*(잘|쉽게|금방|바로)\s*(앉|있|생)|여유\s*있|자리\s*많|자리\s*넉넉)", re.I
        ),
    ),
    (
        "specialty",
        re.compile(r"(스페셜티|싱글\s*오리진|핸드드립|원두\s*(좋|훌륭|맛있)|드립\s*커피)", re.I),
    ),
    ("decaf", re.compile(r"(디카페인|카페인\s*(없|제거|프리)|디카)", re.I)),
]


async def _find_naver_place_id(name: str, address: str) -> str | None:
    """카페명+주소로 네이버 장소 검색 → place ID 반환."""
    addr_hint = " ".join(address.split()[:2]) if address else ""
    query = f"{name} {addr_hint}".strip()
    try:
        async with httpx.AsyncClient(follow_redirects=True, timeout=8.0) as client:
            r = await client.get(
                _NAVER_SEARCH_URL,
                params={"query": query, "where": "place"},
                headers=_HEADERS_PC,
            )
            if r.status_code != 200:
                return None
            ids = re.findall(r'"id"\s*:\s*"(\d{7,12})"', r.text)
            return ids[0] if ids else None
    except Exception:
        return None


async def _fetch_visitor_reviews(place_id: str, max_reviews: int = 60) -> list[str]:
    """네이버 플레이스 GraphQL API로 방문자 리뷰 텍스트 수집.

    cursor 기반 페이지네이션으로 최대 max_reviews개를 수집한다.
    """
    graphql_headers = {
        **_HEADERS_PC,
        "Accept": "application/json, text/plain, */*",
        "Content-Type": "application/json",
        "Origin": "https://pcmap.place.naver.com",
        "Referer": f"https://pcmap.place.naver.com/restaurant/{place_id}/review/visitor",
    }

    all_bodies: list[str] = []
    after: str | None = None

    async with httpx.AsyncClient(follow_redirects=True, timeout=10.0) as client:
        while len(all_bodies) < max_reviews:
            inp: dict = {
                "businessId": place_id,
                "businessType": "restaurant",
                "size": 20,
                "includeContent": True,
            }
            if after:
                inp["after"] = after

            payload = {
                "operationName": "getVisitorReviews",
                "variables": {"input": inp},
                "query": _VISITOR_REVIEWS_QUERY,
            }

            try:
                r = await client.post(_GRAPHQL_URL, json=payload, headers=graphql_headers)
                if r.status_code != 200 or not r.text.strip():
                    break
                data = r.json()
            except Exception:
                break

            vr = data.get("data", {}).get("visitorReviews")
            if not vr or not vr.get("items"):
                break

            items = vr["items"]
            for item in items:
                body = item.get("body") or ""
                if body.strip():
                    all_bodies.append(body)

            if len(items) < 20:
                break
            after = items[-1].get("cursor")
            if not after:
                break

    return all_bodies


def _count_keywords(bodies: list[str]) -> dict[str, int]:
    text = " ".join(bodies)
    counts: dict[str, int] = {}
    for keyword, pattern in _PATTERNS:
        matches = len(pattern.findall(text))
        if matches:
            counts[keyword] = matches
    return counts


def _keywords_to_tags(counts: dict[str, int], total_reviews: int = 0) -> dict:
    tags: dict = {}

    # 주관적/오탐 가능 키워드: 5% + 최소 2건
    subjective_threshold = max(2, total_reviews * 0.05)

    def sig_s(key: str) -> bool:
        return counts.get(key, 0) >= subjective_threshold

    # 직접적 사실 언급 키워드: 최소 2건 (오탐 적음)
    def sig_f(key: str) -> bool:
        return counts.get(key, 0) >= 2

    # noise_level (주관적)
    q, n = counts.get("quiet", 0), counts.get("noisy", 0)
    if sig_s("quiet") and q > n:
        tags["noise_level"] = "quiet"
    elif sig_s("noisy") and n > q:
        tags["noise_level"] = "lively"
    elif sig_s("quiet") or sig_s("noisy"):
        tags["noise_level"] = "moderate-noise"

    # lighting (주관적)
    if sig_s("bright"):
        tags["lighting"] = "bright"
    elif sig_s("dim"):
        tags["lighting"] = "dim"

    # space_type (주관적)
    if sig_s("spacious"):
        tags["space_type"] = "spacious"
    elif sig_s("crowded"):
        tags["space_type"] = "cozy"

    # work_tags (직접적 사실)
    work: list[str] = []
    if sig_f("work_friendly"):
        work.append("work-friendly")
    if sig_f("no_laptop"):
        work.append("no-laptop")
    if sig_f("power_outlet"):
        work.append("power-outlet")
    if sig_f("wifi_good"):
        work.append("fast-wifi")
    if sig_f("easy_to_seat"):
        work.append("easy-to-seat")
    if sig_f("specialty"):
        work.append("specialty-coffee")
    if sig_f("decaf"):
        work.append("decaf-available")
    if work:
        tags["work_tags"] = work

    tags["_review_waiting"] = counts.get("waiting", 0)
    return tags


async def infer_tags_from_reviews(kakao_id: str, name: str, address: str) -> dict:  # noqa: ARG001
    """네이버 플레이스 GraphQL API로 방문자 리뷰 수집 → 키워드 추출.

    리뷰가 없거나 신호가 부족하면 태그 없이 반환한다 (추론 없음).
    """
    place_id = await _find_naver_place_id(name, address)
    if place_id:
        bodies = await _fetch_visitor_reviews(place_id, max_reviews=60)
        if len(bodies) >= 5:
            counts = _count_keywords(bodies)
            tags = _keywords_to_tags(counts, total_reviews=len(bodies))
            tags["_source"] = "review"
            tags["_review_count"] = len(bodies)
            return tags

    return {"_source": "no_data"}
