import json
import math
from datetime import UTC, datetime

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
    user_preferences: dict | None = None,
) -> float:
    """
    score = 컨디션 매칭도×0.5 + 거리점수×0.2 + 혼잡도역수×0.2 + 선호도×0.1
    """
    condition_score = _condition_match(cafe, mode)
    distance_score = _distance_score(cafe, user_lat, user_lng, radius_km)
    crowd_score = _crowd_score(cafe)
    preference_score = _preference_score(cafe, user_preferences)

    return condition_score * 0.5 + distance_score * 0.2 + crowd_score * 0.2 + preference_score * 0.1


def is_noise_excluded(cafe: Cafe, mode: ConditionMode) -> bool:
    """noise_level 데이터가 있고 컨디션 선호와 명시적으로 불일치하면 True."""
    prefs = CONDITION_PREFERENCES[mode]
    if "noise_level" not in prefs:
        return False
    if cafe.noise_level is None:
        return False
    return cafe.noise_level not in prefs["noise_level"]


def _condition_match(cafe: Cafe, mode: ConditionMode) -> float:
    prefs = CONDITION_PREFERENCES[mode]
    hits = 0
    total = 0

    if "noise_level" in prefs:
        total += 2
        if cafe.noise_level in prefs["noise_level"]:
            hits += 2
        elif cafe.noise_level is None:
            hits += 0.5

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


def _crowd_score(cafe: Cafe) -> float:
    """crowd_pattern JSON에서 현재 시간대 혼잡도를 읽어 역수 점수(0~1)로 반환."""
    if not cafe.crowd_pattern:
        return 0.5
    try:
        pattern: dict = json.loads(cafe.crowd_pattern)
        hour = str(datetime.now(UTC).hour)
        level = max(1, min(5, int(pattern.get(hour, 3))))  # 1(한산)~5(매우혼잡), 기본 보통
        return 1.0 - (level - 1) / 4
    except Exception:
        return 0.5


def _preference_score(cafe: Cafe, user_preferences: dict | None) -> float:
    """사용자 선호 설정과 카페 속성이 얼마나 맞는지 점수(0~1)로 반환."""
    if not user_preferences:
        return 0.5
    hits = 0
    total = 0

    preferred_noise = user_preferences.get("preferred_noise")
    if preferred_noise:
        total += 1
        if cafe.noise_level == preferred_noise:
            hits += 1

    preferred_space = user_preferences.get("preferred_space")
    if preferred_space:
        total += 1
        if cafe.space_type == preferred_space:
            hits += 1

    required_tags = user_preferences.get("required_tags", [])
    if required_tags and cafe.work_tags:
        total += 1
        if any(tag in cafe.work_tags for tag in required_tags):
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
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    )
    return R * 2 * math.asin(math.sqrt(a))
