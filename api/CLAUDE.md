# api/CLAUDE.md

Python FastAPI 백엔드 작업 지침.

## 커맨드

```bash
# 개발 서버 (반드시 프로젝트 루트 focus-spot/ 에서 실행)
uv sync --project api
uv run --project api python -m uvicorn api.main:app --reload --port 8000

# 테스트 (프로젝트 루트에서)
uv run --project api pytest api/tests/                          # 전체
uv run --project api pytest -k "test_name" api/tests/           # 단일
uv run --project api pytest -v --tb=short api/tests/            # 상세

# 린트 & 포맷 (api/ 디렉토리에서)
uv run ruff check .
uv run ruff format .

# DB 마이그레이션 (프로젝트 루트에서)
uv run --project api python -m alembic -c api/alembic.ini upgrade head                          # 적용
uv run --project api python -m alembic -c api/alembic.ini revision --autogenerate -m "message"  # 생성
uv run --project api python -m alembic -c api/alembic.ini current                               # 현재 상태
uv run --project api python -m alembic -c api/alembic.ini check                                 # 불일치 확인
```

## 디렉토리 구조

```
api/
├── main.py             # FastAPI 앱 진입점
├── config.py           # 환경변수 설정
├── models/             # SQLAlchemy ORM 모델
├── routers/            # 라우터 (auth, condition, cafes, ...)
├── services/           # 비즈니스 로직
├── alembic/            # DB 마이그레이션
│   └── versions/
├── scripts/            # 시드 스크립트
└── tests/              # pytest 테스트
```

## 코딩 규칙

- 라우터는 `routers/`에, 비즈니스 로직은 `services/`에 분리한다.
- DB 모델 변경 시 반드시 alembic 마이그레이션을 생성한다 (`/db-migrate` 사용).
- 새 의존성 추가: `uv add <package> --project api`
- 테스트는 `tests/` 디렉토리에 `test_*.py` 형식으로 작성한다.
- ruff 린트 규칙을 준수한다 (저장 시 자동 포맷 적용됨).

## 주요 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/health/sync` | iOS → 건강 데이터 전송 |
| GET | `/api/condition/current` | 현재 컨디션 분석 |
| GET | `/api/cafes/recommend` | 카페 추천 |
| GET | `/api/cafes/{id}` | 카페 상세 |
| POST | `/api/auth/register` | 회원가입 |
| POST | `/api/auth/login` | 로그인 |

## DB 모델 변경 주의사항

`models/` 파일 수정 후 반드시:
1. `uv run alembic check`로 불일치 확인
2. `uv run alembic revision --autogenerate -m "..."` 마이그레이션 생성
3. 생성된 마이그레이션 파일 내용 검토
4. `uv run alembic upgrade head` 적용
