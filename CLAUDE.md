# CLAUDE.md

FocusSpot 하네스 설정. 레이어별 상세는 각 디렉토리의 CLAUDE.md 참조.

## 프로젝트 개요

**FocusSpot** — 애플워치 건강 데이터 기반 카페 추천 서비스.

- `api/` — Python FastAPI 백엔드 → [api/CLAUDE.md](api/CLAUDE.md)
- `web/` — Next.js 웹 프론트엔드 → [web/CLAUDE.md](web/CLAUDE.md)
- `ios/` — Swift/SwiftUI + HealthKit 컴패니언 앱 → [ios/CLAUDE.md](ios/CLAUDE.md)

기능 명세: @SPEC.md

---

## 작업 범위 원칙

- **현재 작업 디렉토리만 수정한다.** `web/` 작업 중이면 `api/`, `ios/` 파일은 읽거나 수정하지 않는다.
- 다른 레이어 변경이 필요하면 직접 수정하지 않고 사용자에게 알린다.

---

## 기술 스택 & 패키지 매니저

| 레이어 | 패키지 매니저 | 주요 도구 |
|--------|--------------|-----------|
| Python (api/) | `uv` | FastAPI, SQLAlchemy, pytest, ruff |
| Node (web/) | `pnpm` | Next.js 14 (App Router), TypeScript |
| iOS (ios/) | Xcode / SPM | SwiftUI, HealthKit |
| 로컬 인프라 | Docker Compose | PostgreSQL, Redis |

---

## 커밋 컨벤션

Conventional Commits:

```
feat(scope): 새 기능
fix(scope): 버그 수정
chore(scope): 빌드/설정/의존성
refactor(scope): 리팩터링
test(scope): 테스트 추가/수정
docs(scope): 문서
```

스코프: `api` / `web` / `ios` / `condition` / `cafes` / `auth`

- 커밋 메시지는 **영어**로 작성한다.
- `Co-Authored-By: Claude` 등 AI 작성자 표기는 포함하지 않는다.

---

## 환경 변수

`.env` 파일은 커밋하지 않는다. `.env.example`을 복사해 사용:

```bash
cp .env.example .env
```

필수 변수: `DATABASE_URL`, `REDIS_URL`, `KAKAO_API_KEY`, `ANTHROPIC_API_KEY`, `JWT_SECRET`

---

## 아키텍처 결정

- **컨디션 분류**: 규칙 기반 1차 분류 (5가지 모드) → 추후 개인화 보정
- **카페 추천 점수**: `컨디션 매칭도×0.5 + 거리×0.2 + 혼잡도 역수×0.2 + 선호도×0.1`
- **iOS → 백엔드**: JWT 인증, 30분 주기 백그라운드 동기화
- **AI 분석**: Claude API로 카페 리뷰에서 속성 태그 추출

---

## 스킬 (slash commands)

| 커맨드 | 용도 |
|--------|------|
| `/dev-start` | Docker + API + Web 개발 환경 시작 |
| `/verify` | 전체 테스트 + 린트 + 타입체크 |
| `/db-migrate "설명"` | Alembic 마이그레이션 생성 및 적용 |
| `/commit-push-pr` | 커밋 → push → PR 생성 |
| `/code-review` | 레이어별 코드 리뷰 |
