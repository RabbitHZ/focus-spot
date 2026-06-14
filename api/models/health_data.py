from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from api.db.database import Base


class HealthData(Base):
    __tablename__ = "health_data"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)

    # 수면
    sleep_duration_hours: Mapped[float | None] = mapped_column(Float)
    deep_sleep_hours: Mapped[float | None] = mapped_column(Float)
    rem_sleep_hours: Mapped[float | None] = mapped_column(Float)
    light_sleep_hours: Mapped[float | None] = mapped_column(Float)

    # 심박수
    resting_heart_rate: Mapped[float | None] = mapped_column(Float)
    avg_heart_rate: Mapped[float | None] = mapped_column(Float)

    # 기타
    respiratory_rate: Mapped[float | None] = mapped_column(Float)
    spo2: Mapped[float | None] = mapped_column(Float)
    step_count: Mapped[int | None] = mapped_column()

    recorded_at: Mapped[datetime] = mapped_column(DateTime)
    synced_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
