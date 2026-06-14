# FocusSpot

애플워치 건강 데이터(수면, 심박수, SpO2 등)를 분석해 현재 컨디션을 파악하고, 집중하기 좋은 최적의 카페를 추천하는 서비스.

## 구조

```
focus-spot/
├── api/          # Python FastAPI 백엔드
├── web/          # Next.js 웹 프론트엔드
├── ios/          # Swift/SwiftUI + HealthKit 컴패니언 앱
└── docker-compose.yml
```

## 기술 스택

| 레이어 | 기술 |
|--------|------|
| iOS 컴패니언 앱 | Swift / SwiftUI + HealthKit |
| 웹 프론트엔드 | Next.js 15 (App Router) + TypeScript |
| 백엔드 API | Python FastAPI + SQLAlchemy (async) |
| 데이터베이스 | PostgreSQL 16 |
| 캐시 | Redis 7 |
| 인증 | JWT |
| AI 분석 | Claude API (카페 리뷰 속성 추출) |

## 로컬 개발 환경 시작

### 사전 요구사항

- Docker Desktop
- Python 3.12+ + [uv](https://docs.astral.sh/uv/)
- Node.js 20+ + pnpm
- Xcode 15+ (iOS 개발 시)

### 1. 저장소 클론 및 환경변수 설정

```bash
git clone https://github.com/your-org/focus-spot.git
cd focus-spot
cp .env.example .env
# .env 파일에서 KAKAO_API_KEY, ANTHROPIC_API_KEY 등 입력
```

### 2. 인프라 실행 (PostgreSQL + Redis)

> **주의:** 로컬에 PostgreSQL이 이미 5432 포트를 사용 중이면 Docker는 5433으로 실행됩니다.

```bash
docker compose up -d
```

### 3. 백엔드 실행

```bash
uv sync --project api
DATABASE_URL="postgresql+asyncpg://focusspot:focusspot@127.0.0.1:5433/focusspot" \
REDIS_URL="redis://127.0.0.1:6379" \
JWT_SECRET="dev-secret" \
PYTHONPATH=. uv run --project api uvicorn api.main:app --reload --port 8000
```

- API: http://localhost:8000
- Swagger 문서: http://localhost:8000/docs

### 4. 웹 프론트엔드 실행

```bash
cd web
pnpm install
pnpm dev
```

- 웹: http://localhost:3000

## API 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/auth/register` | 회원가입 |
| POST | `/api/auth/login` | 로그인 |
| POST | `/api/health/sync` | iOS → 건강 데이터 전송 |
| GET | `/api/condition/current` | 현재 컨디션 분석 |
| GET | `/api/condition/history` | 최근 7일 컨디션 히스토리 |
| GET | `/api/cafes/recommend` | 컨디션 기반 카페 추천 |
| GET | `/api/cafes/{id}` | 카페 상세 정보 |

## 컨디션 모드

| 모드 | 조건 | 추천 카페 |
|------|------|-----------|
| 집중 | 수면 충분 + 심박수 정상 | 조용하고 넓은 업무 카페 |
| 졸림 | 수면 부족 + 심박수 낮음 | 밝은 조명 + 적당한 소음 카페 |
| 피로 | 심박수 높음 + SpO2 낮음 | 조용하고 편안한 카페 |
| 활기 | 수면 충분 + 활동량 많음 | 활기차고 사람 많은 카페 |
| 회복 | 불규칙 패턴 | 개인 공간 있는 조용한 카페 |

## 테스트

```bash
# API 테스트
cd api
uv run pytest -v

# 웹 타입 체크
cd web
pnpm type-check
```

## MVP 범위

**포함 (1차)**
- iOS HealthKit 연동 및 서버 동기화
- 규칙 기반 컨디션 분류 (5가지 모드)
- 카페 DB (서울 강남/홍대/성수, ~200개)
- 웹 추천 화면 + 카카오맵 연동

**제외 (2차 이후)**
- 실시간 혼잡도 연동
- ML 기반 개인화 학습
- 리뷰 크롤링 자동화
- 컨디션 히스토리 그래프
