from enum import StrEnum

from api.models.health_data import HealthData


class ConditionMode(StrEnum):
    FOCUS = "focus"       # 집중 모드
    DROWSY = "drowsy"     # 졸림 모드
    FATIGUE = "fatigue"   # 피로 모드
    ENERGIZED = "energized"  # 활기 모드
    RECOVERY = "recovery" # 회복 모드


CONDITION_LABELS = {
    ConditionMode.FOCUS: "집중 모드",
    ConditionMode.DROWSY: "졸림 모드",
    ConditionMode.FATIGUE: "피로 모드",
    ConditionMode.ENERGIZED: "활기 모드",
    ConditionMode.RECOVERY: "회복 모드",
}

CONDITION_CAFE_HINTS = {
    ConditionMode.FOCUS: "조용하고 넓은 업무 카페",
    ConditionMode.DROWSY: "적당한 소음과 밝은 조명 카페",
    ConditionMode.FATIGUE: "조용하고 편안한 분위기 카페",
    ConditionMode.ENERGIZED: "활기차고 사람 많은 카페",
    ConditionMode.RECOVERY: "조용하고 개인 공간이 있는 카페",
}


def analyze_condition(data: HealthData) -> tuple[ConditionMode, int]:
    """건강 데이터로 컨디션 모드를 분류한다. (모드, 신뢰도 0~100) 반환."""
    score = _compute_score(data)

    if score.fatigue >= 70:
        return ConditionMode.FATIGUE, score.fatigue
    if score.drowsy >= 60:
        return ConditionMode.DROWSY, score.drowsy
    if score.energized >= 65:
        return ConditionMode.ENERGIZED, score.energized
    if score.recovery >= 55:
        return ConditionMode.RECOVERY, score.recovery
    return ConditionMode.FOCUS, score.focus


class _Scores:
    def __init__(self):
        self.focus = 50
        self.drowsy = 0
        self.fatigue = 0
        self.energized = 0
        self.recovery = 0


def _compute_score(data: HealthData) -> _Scores:
    s = _Scores()

    sleep_ok = data.sleep_duration_hours is not None and data.sleep_duration_hours >= 6.5
    sleep_short = data.sleep_duration_hours is not None and data.sleep_duration_hours < 5.5
    hr_normal = data.resting_heart_rate is not None and 50 <= data.resting_heart_rate <= 80
    hr_high = data.resting_heart_rate is not None and data.resting_heart_rate > 85
    spo2_low = data.spo2 is not None and data.spo2 < 95
    steps_high = data.step_count is not None and data.step_count >= 8000

    # 피로 모드
    if hr_high:
        s.fatigue += 40
    if spo2_low:
        s.fatigue += 30
    if sleep_short:
        s.fatigue += 30

    # 졸림 모드
    if sleep_short and not hr_high:
        s.drowsy += 50
    if data.resting_heart_rate is not None and data.resting_heart_rate < 50:
        s.drowsy += 20

    # 활기 모드
    if sleep_ok and steps_high and hr_normal:
        s.energized += 70

    # 회복 모드
    if not sleep_ok and not sleep_short:
        s.recovery += 55

    # 집중 모드
    if sleep_ok and hr_normal and not steps_high:
        s.focus = 80

    return s
