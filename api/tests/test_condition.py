from datetime import datetime

from api.models.health_data import HealthData
from api.services.condition import ConditionMode, analyze_condition


def make_data(**kwargs) -> HealthData:
    defaults = dict(
        id=1,
        user_id=1,
        recorded_at=datetime.now(),
        sleep_duration_hours=7.0,
        resting_heart_rate=65.0,
        spo2=98.0,
        step_count=5000,
    )
    defaults.update(kwargs)
    data = HealthData.__new__(HealthData)
    for k, v in defaults.items():
        setattr(data, k, v)
    return data


def test_focus_mode():
    data = make_data(sleep_duration_hours=7.5, resting_heart_rate=62, step_count=4000)
    mode, confidence = analyze_condition(data)
    assert mode == ConditionMode.FOCUS
    assert confidence > 0


def test_drowsy_mode():
    data = make_data(sleep_duration_hours=4.5, resting_heart_rate=48)
    mode, _ = analyze_condition(data)
    assert mode == ConditionMode.DROWSY


def test_fatigue_mode():
    data = make_data(sleep_duration_hours=4.0, resting_heart_rate=90, spo2=93)
    mode, _ = analyze_condition(data)
    assert mode == ConditionMode.FATIGUE


def test_energized_mode():
    data = make_data(sleep_duration_hours=8.0, resting_heart_rate=65, step_count=10000)
    mode, _ = analyze_condition(data)
    assert mode == ConditionMode.ENERGIZED
