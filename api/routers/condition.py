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
