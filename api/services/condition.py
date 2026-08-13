from enum import StrEnum

from api.models.health_data import HealthData


class ConditionMode(StrEnum):
    FOCUS = "focus"  # 집중 모드
    DROWSY = "drowsy"  # 졸림 모드
    FATIGUE = "fatigue"  # 피로 모드
    ENERGIZED = "energized"  # 활기 모드
    RECOVERY = "recovery"  # 회복 모드


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

    if score.fatigue >= 60:
        return ConditionMode.FATIGUE, min(score.fatigue, 99)
    if score.drowsy >= 40:
        return ConditionMode.DROWSY, min(score.drowsy, 99)
    if score.energized >= 55:
        return ConditionMode.ENERGIZED, min(score.energized, 99)
    if score.recovery >= 40:
        return ConditionMode.RECOVERY, min(score.recovery, 99)
    return ConditionMode.FOCUS, min(score.focus, 99)


class _Scores:
    def __init__(self):
        self.focus = 50
        self.drowsy = 0
        self.fatigue = 0
        self.energized = 0
        self.recovery = 0


def _compute_score(data: HealthData) -> _Scores:
    s = _Scores()

    sleep_hours = data.sleep_duration_hours
    hr = data.resting_heart_rate

    sleep_ok = sleep_hours is not None and sleep_hours >= 6.5
    sleep_good = sleep_hours is not None and sleep_hours >= 7.5
    sleep_short = sleep_hours is not None and sleep_hours < 5.5
    sleep_mid = sleep_hours is not None and 5.5 <= sleep_hours < 6.5
    hr_normal = hr is not None and 50 <= hr <= 80
    hr_optimal = hr is not None and 55 <= hr <= 70
    hr_high = hr is not None and hr > 85
    hr_very_high = hr is not None and hr > 95
    hr_low = hr is not None and hr < 50
    spo2_low = data.spo2 is not None and data.spo2 < 95
    spo2_very_low = data.spo2 is not None and data.spo2 < 92
    steps_high = data.step_count is not None and data.step_count >= 8000
    steps_very_high = data.step_count is not None and data.step_count >= 12000

    # 피로 모드
    if hr_very_high:
        s.fatigue += 50
    elif hr_high:
        s.fatigue += 35
    if spo2_very_low:
        s.fatigue += 35
    elif spo2_low:
        s.fatigue += 20
    if sleep_short:
        s.fatigue += 25
    if hr_high and sleep_short:
        s.fatigue += 10  # 복합 패널티

    # 졸림 모드
    if sleep_short and not hr_high:
        s.drowsy += 45
    elif sleep_mid and not hr_high:
        s.drowsy += 25
    if hr_low:
        s.drowsy += 25
    if sleep_short and hr_low:
        s.drowsy += 15  # 복합 가중치

    # 활기 모드
    if sleep_good and steps_very_high and hr_optimal:
        s.energized += 90
    elif sleep_ok and steps_high and hr_normal:
        s.energized += 72
    elif sleep_ok and steps_high:
        s.energized += 55

    # 회복 모드
    if sleep_mid:
        s.recovery += 40
    if not sleep_ok and not sleep_short and not sleep_mid:
        s.recovery += 30
    if steps_high and not hr_normal:
        s.recovery += 20

    # 집중 모드
    if sleep_good and hr_optimal and not steps_high:
        s.focus = 92
    elif sleep_ok and hr_normal and not steps_high:
        s.focus = 80
    elif sleep_ok and hr_normal:
        s.focus = 65

    return s
