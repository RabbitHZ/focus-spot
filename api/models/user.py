from datetime import datetime

from sqlalchemy import ARRAY, DateTime, Float, String, func
from sqlalchemy.orm import Mapped, mapped_column

from api.db.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    # 사용자 선호 설정
    preferred_noise: Mapped[str | None] = mapped_column(
        String(50), nullable=True
    )  # quiet / moderate-noise / lively
    preferred_space: Mapped[str | None] = mapped_column(
        String(50), nullable=True
    )  # spacious / cozy / private-booth / counter-seat
    required_tags: Mapped[list[str] | None] = mapped_column(
        ARRAY(String), nullable=True
    )  # work-friendly / fast-wifi / power-outlet 등
    radius_km: Mapped[float] = mapped_column(Float, default=1.0, server_default="1.0")
