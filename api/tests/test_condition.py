from dataclasses import dataclass, field
from datetime import datetime

from api.services.condition import ConditionMode, analyze_condition


@dataclass
class FakeHealthData:
    id: int = 1
    user_id: int = 1
    recorded_at: datetime = field(default_factory=datetime.now)
    sleep_duration_hours: float | None = 7.0
    deep_sleep_hours: float | None = None
    rem_sleep_hours: float | None = None
    light_sleep_hours: float | None = None
    resting_heart_rate: float | None = 65.0
    avg_heart_rate: float | None = None
    respiratory_rate: float | None = None
    spo2: float | None = 98.0
    step_count: int | None = 5000


def test_focus_mode():
    data = FakeHealthData(sleep_duration_hours=7.5, resting_heart_rate=62, step_count=4000)
    mode, confidence = analyze_condition(data)
    assert mode == ConditionMode.FOCUS
    assert confidence > 0


def test_drowsy_mode():
    data = FakeHealthData(sleep_duration_hours=4.5, resting_heart_rate=48)
    mode, _ = analyze_condition(data)
    assert mode == ConditionMode.DROWSY


def test_fatigue_mode():
    data = FakeHealthData(sleep_duration_hours=4.0, resting_heart_rate=90, spo2=93)
    mode, _ = analyze_condition(data)
    assert mode == ConditionMode.FATIGUE


def test_energized_mode():
    data = FakeHealthData(sleep_duration_hours=8.0, resting_heart_rate=65, step_count=10000)
    mode, _ = analyze_condition(data)
    assert mode == ConditionMode.ENERGIZED
