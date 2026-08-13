import logging
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.db.database import get_db
from api.models.health_data import HealthData
from api.routers.deps import get_current_user
from api.services.condition import CONDITION_CAFE_HINTS, CONDITION_LABELS, analyze_condition

router = APIRouter()


class ConditionResponse(BaseModel):
    mode: str
    label: str
    confidence: int
    cafe_hint: str
    heart_rate: int | None = None
    sleep_hours: float | None = None
    spo2: float | None = None
    step_count: int | None = None


class AnalyzeRequest(BaseModel):
    sleep_duration_hours: float | None = None
    deep_sleep_hours: float | None = None
    rem_sleep_hours: float | None = None
    light_sleep_hours: float | None = None
    resting_heart_rate: float | None = None
    avg_heart_rate: float | None = None
    respiratory_rate: float | None = None
    spo2: float | None = None
    step_count: int | None = None


@router.post("/analyze", response_model=ConditionResponse)
async def analyze_condition_direct(
    body: AnalyzeRequest,
    user_id: int = Depends(get_current_user),
):
    """HealthKit 스냅샷을 직접 받아 DB 저장 없이 바로 컨디션 분석."""
    logger = logging.getLogger(__name__)
    logger.debug("[analyze] sleep=%s rHR=%s spo2=%s steps=%s", body.sleep_duration_hours, body.resting_heart_rate, body.spo2, body.step_count)
    data = HealthData(
        user_id=user_id,
        recorded_at=datetime.now(UTC),
        **body.model_dump(),
    )
    mode, confidence = analyze_condition(data)
    logger.debug("[analyze] result mode=%s confidence=%s", mode, confidence)
    return ConditionResponse(
        mode=mode,
        label=CONDITION_LABELS[mode],
        confidence=confidence,
        cafe_hint=CONDITION_CAFE_HINTS[mode],
        heart_rate=int(body.resting_heart_rate) if body.resting_heart_rate else None,
        sleep_hours=body.sleep_duration_hours,
        spo2=body.spo2,
        step_count=body.step_count,
    )


class ConditionHistory(BaseModel):
    records: list[dict]


@router.get("/current", response_model=ConditionResponse)
async def get_current_condition(
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    latest = await db.scalar(
        select(HealthData)
        .where(HealthData.user_id == user_id)
        .order_by(HealthData.recorded_at.desc())
        .limit(1)
    )
    if not latest:
        raise HTTPException(status_code=404, detail="건강 데이터가 없습니다. iOS 앱에서 동기화해주세요.")

    mode, confidence = analyze_condition(latest)
    return ConditionResponse(
        mode=mode,
        label=CONDITION_LABELS[mode],
        confidence=confidence,
        cafe_hint=CONDITION_CAFE_HINTS[mode],
        heart_rate=latest.resting_heart_rate,
        sleep_hours=latest.sleep_duration_hours,
        spo2=latest.spo2,
        step_count=latest.step_count,
    )


@router.get("/history", response_model=ConditionHistory)
async def get_condition_history(
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    rows = await db.scalars(
        select(HealthData)
        .where(HealthData.user_id == user_id)
        .order_by(HealthData.recorded_at.desc())
        .limit(7 * 48)  # 최근 7일 × 30분 간격
    )
    records = []
    for row in rows:
        mode, confidence = analyze_condition(row)
        records.append(
            {
                "recorded_at": row.recorded_at.isoformat(),
                "mode": mode,
                "label": CONDITION_LABELS[mode],
                "confidence": confidence,
            }
        )
    return ConditionHistory(records=records)
