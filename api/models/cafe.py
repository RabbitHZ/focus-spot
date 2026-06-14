from sqlalchemy import ARRAY, Float, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from api.db.database import Base


class Cafe(Base):
    __tablename__ = "cafes"

    id: Mapped[int] = mapped_column(primary_key=True)
    kakao_id: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(200))
    address: Mapped[str] = mapped_column(String(500))
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    phone: Mapped[str | None] = mapped_column(String(50))
    kakao_url: Mapped[str | None] = mapped_column(String(500))

    # AI 추출 속성 태그
    # 소음: quiet / moderate-noise / lively
    noise_level: Mapped[str | None] = mapped_column(String(50))
    # 조명: bright / dim / natural-light
    lighting: Mapped[str | None] = mapped_column(String(50))
    # 공간: spacious / cozy / private-booth / counter-seat
    space_type: Mapped[str | None] = mapped_column(String(50))
    # 업무 적합도 태그 목록
    work_tags: Mapped[list[str] | None] = mapped_column(ARRAY(String))
    # 혼잡도 패턴 (시간대별 평균, JSON string)
    crowd_pattern: Mapped[str | None] = mapped_column(Text)

    # 평점
    rating: Mapped[float | None] = mapped_column(Float)
    review_count: Mapped[int | None] = mapped_column()
