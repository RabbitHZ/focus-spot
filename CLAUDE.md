# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**FocusSpot** — 애플워치 건강 데이터 기반 카페 추천 서비스.

- `api/` — Python FastAPI 백엔드
- `web/` — Next.js 웹 프론트엔드
- `ios/` — Swift/SwiftUI + HealthKit 컴패니언 앱

자세한 기능 명세는 @SPEC.md 참조.

---

## 작업 범위 원칙

- **현재 작업 디렉토리만 수정한다.** 사용자가 `web/`에서 작업 중이면 `api/`, `ios/` 등 다른 디렉토리의 파일은 읽거나 수정하지 않는다.
- 다른 레이어에 변경이 필요한 경우 직접 수정하지 않고 사용자에게 알린다.

---

## 기술 스택 & 패키지 매니저

| 레이어 | 패키지 매니저 | 주요 도구 |
|--------|--------------|-----------|
| Python (api/) | `uv` | FastAPI, SQLAlchemy, pytest, ruff |
| Node (web/) | `pnpm` | Next.js 14 (App Router), TypeScript |
| iOS (ios/) | Xcode / SPM | SwiftUI, HealthKit |
| 로컬 인프라 | Docker Compose | PostgreSQL, Redis |

---

## 개발 환경 시작

```bash
# 로컬 DB/캐시 실행
docker compose up -d

# 백엔드 (프로젝트 루트에서 실행)
uv sync --project api
PYTHONPATH=. uv run --project api uvicorn api.main:app --reload --port 8000

# 웹 프론트엔드
cd web
pnpm install
pnpm dev
```

---

## 커맨드 레퍼런스

### API (api/)

```bash
uv run pytest                          # 전체 테스트
uv run pytest -k "test_name"           # 단일 테스트
uv run ruff check .                    # 린트
uv run ruff format .                   # 포맷
uv run alembic upgrade head            # DB 마이그레이션 적용
uv run alembic revision --autogenerate -m "message"  # 마이그레이션 생성
```

### Web (web/)

```bash
pnpm dev          # 개발 서버 (localhost:3000)
pnpm build        # 프로덕션 빌드
pnpm lint         # ESLint
pnpm type-check   # TypeScript 타입 체크
```

---

## 커밋 컨벤션

Conventional Commits 사용:

```
feat: 새 기능
fix: 버그 수정
chore: 빌드/설정/의존성
refactor: 리팩터링
test: 테스트 추가/수정
docs: 문서
```

스코프 예시: `feat(api): add condition analysis endpoint`, `fix(web): cafe card layout`

커밋 메시지는 영어로 작성한다.

커밋 메시지에 `Co-Authored-By: Claude` 등 AI 작성자 표기는 포함하지 않음.

---

## 환경 변수

`.env` 파일은 커밋하지 않음. `.env.example`을 복사해 사용:

```bash
cp .env.example .env
```

필수 환경 변수:
- `DATABASE_URL` — PostgreSQL 연결 문자열
- `REDIS_URL` — Redis 연결 문자열
- `KAKAO_API_KEY` — 카카오맵 API 키
- `ANTHROPIC_API_KEY` — Claude API 키 (리뷰 분석용)
- `JWT_SECRET` — JWT 서명 키

---

## 주요 아키텍처 결정

- **컨디션 분류**: 규칙 기반 1차 분류 (5가지 모드) → 추후 개인화 보정 추가 예정
- **카페 추천 점수**: `컨디션 매칭도×0.5 + 거리×0.2 + 혼잡도 역수×0.2 + 선호도×0.1`
- **iOS → 백엔드**: JWT 인증, 30분 주기 백그라운드 동기화
- **AI 분석**: Claude API로 카페 리뷰 텍스트에서 속성 태그 추출

---

## MVP 범위 (1차)

포함: iOS HealthKit 연동, 컨디션 분류, 카페 DB(강남/홍대/성수 ~200개), 웹 추천 화면, 카카오맵 API  
제외: 실시간 혼잡도, 개인화 학습, 리뷰 크롤링 자동화, 컨디션 히스토리 그래프
