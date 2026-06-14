---
name: dev-start
description: FocusSpot 로컬 개발 환경 전체 시작 (Docker + API + Web). 처음 개발 시작할 때 또는 환경을 초기화할 때 사용.
disable-model-invocation: false
---

다음 순서로 FocusSpot 로컬 개발 환경을 시작한다:

1. **Docker Compose 상태 확인**
   - `docker compose ps`로 PostgreSQL, Redis 컨테이너 상태 확인
   - 실행 중이지 않으면 `docker compose up -d` 실행
   - 컨테이너가 healthy 상태가 될 때까지 기다린다

2. **API 의존성 동기화**
   - `cd api && uv sync` 실행
   - 새로 추가된 패키지가 있으면 사용자에게 알린다

3. **DB 마이그레이션 확인**
   - `cd api && uv run alembic current`로 현재 마이그레이션 상태 확인
   - 미적용 마이그레이션이 있으면 사용자에게 알리고 적용 여부를 묻는다

4. **웹 의존성 동기화**
   - `cd web && pnpm install` 실행 (lock 파일 변경 없이)

5. **실행 안내**
   - API 서버: `cd api && uv run uvicorn main:app --reload` (포트 8000)
   - 웹 서버: `cd web && pnpm dev` (포트 3000)
   - 두 명령어를 별도 터미널에서 실행해야 함을 안내한다
   - `.env` 파일이 없으면 `.env.example`을 복사하라고 안내한다
