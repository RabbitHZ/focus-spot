import math

from api.models.cafe import Cafe
from api.services.condition import ConditionMode

# 컨디션별 선호 카페 속성 가중치
CONDITION_PREFERENCES: dict[ConditionMode, dict] = {
    ConditionMode.FOCUS: {
        "noise_level": ["quiet"],
        "work_tags": ["work-friendly", "fast-wifi", "power-outlet"],
        "space_type": ["spacious"],
    },
    ConditionMode.DROWSY: {
        "noise_level": ["moderate-noise", "lively"],
        "lighting": ["bright", "natural-light"],
        "work_tags": ["easy-to-seat"],
    },
    ConditionMode.FATIGUE: {
        "noise_level": ["quiet"],
        "space_type": ["cozy", "private-booth"],
        "lighting": ["dim", "natural-light"],
    },
    ConditionMode.ENERGIZED: {
        "noise_level": ["lively", "moderate-noise"],
        "space_type": ["spacious"],
    },
    ConditionMode.RECOVERY: {
        "noise_level": ["quiet"],
        "space_type": ["private-booth", "cozy"],
        "work_tags": ["easy-to-seat"],
    },
}


def score_cafe(
    cafe: Cafe,
    mode: ConditionMode,
    user_lat: float,
    user_lng: float,
    radius_km: float = 1.0,
) -> float:
    """
    score = 컨디션 매칭도×0.5 + 거리점수×0.2 + 혼잡도역수×0.2 + 선호도×0.1
    """
    condition_score = _condition_match(cafe, mode)
    distance_score = _distance_score(cafe, user_lat, user_lng, radius_km)
    crowd_score = 0.5  # TODO: 실시간 혼잡도 연동 전 기본값
    preference_score = 0.5  # TODO: 사용자 선호 필터 연동 전 기본값

    return (
        condition_score * 0.5
        + distance_score * 0.2
        + crowd_score * 0.2
        + preference_score * 0.1
    )


def _condition_match(cafe: Cafe, mode: ConditionMode) -> float:
    prefs = CONDITION_PREFERENCES[mode]
    hits = 0
    total = 0

    if "noise_level" in prefs:
        total += 1
        if cafe.noise_level in prefs["noise_level"]:
            hits += 1

    if "lighting" in prefs:
        total += 1
        if cafe.lighting in prefs["lighting"]:
            hits += 1

    if "space_type" in prefs:
        total += 1
        if cafe.space_type in prefs["space_type"]:
            hits += 1

    if "work_tags" in prefs and cafe.work_tags:
        total += 1
        if any(tag in cafe.work_tags for tag in prefs["work_tags"]):
            hits += 1

    return hits / total if total else 0.5


def _distance_score(cafe: Cafe, user_lat: float, user_lng: float, radius_km: float) -> float:
    dist = _haversine(user_lat, user_lng, cafe.latitude, cafe.longitude)
    if dist >= radius_km:
        return 0.0
    return 1.0 - (dist / radius_km)


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))
