---
name: db-migrate
description: Alembic DB 마이그레이션 생성 및 적용. 모델 변경 후 실행. 사용법: /db-migrate "마이그레이션 설명"
disable-model-invocation: true
---

`$ARGUMENTS`에 마이그레이션 설명 메시지를 받아 다음을 수행한다.

1. **현재 상태 확인**
   - `cd api && uv run alembic current` 실행
   - `uv run alembic check`로 모델과 DB 스키마 불일치 확인

2. **마이그레이션 파일 생성**
   - `uv run alembic revision --autogenerate -m "$ARGUMENTS"` 실행
   - 생성된 마이그레이션 파일을 열어 내용을 사용자에게 보여준다
   - 자동 생성된 내용이 의도와 맞는지 확인을 요청한다

3. **마이그레이션 적용**
   - 사용자 확인 후 `uv run alembic upgrade head` 실행
   - 성공 시 `uv run alembic current`로 최종 상태 확인

인수가 없으면 마이그레이션 설명을 입력하라고 안내한다.
