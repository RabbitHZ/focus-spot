from datetime import datetime

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from api.db.database import get_db
from api.models.health_data import HealthData
from api.routers.deps import get_current_user

router = APIRouter()


class HealthSyncRequest(BaseModel):
    sleep_duration_hours: float | None = None
    deep_sleep_hours: float | None = None
    rem_sleep_hours: float | None = None
    light_sleep_hours: float | None = None
    resting_heart_rate: float | None = None
    avg_heart_rate: float | None = None
    respiratory_rate: float | None = None
    spo2: float | None = None
    step_count: int | None = None
    recorded_at: datetime


@router.post("/sync", status_code=status.HTTP_201_CREATED)
async def sync_health_data(
    body: HealthSyncRequest,
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    record = HealthData(user_id=user_id, **body.model_dump())
    db.add(record)
    await db.commit()
    return {"status": "synced"}
