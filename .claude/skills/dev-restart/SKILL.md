---
name: dev-restart
description: FocusSpot 서버 재시작 (API / Web / 전체). Docker·의존성 확인 없이 빠르게 재시작할 때 사용.
disable-model-invocation: false
---

args로 대상을 지정할 수 있다: `api`, `web`, 또는 생략 시 전체(api + web).

다음 순서로 재시작한다:

1. **대상 결정**
   - args가 `api`이면 API만, `web`이면 웹만, 없으면 둘 다 재시작한다.

2. **기존 프로세스 종료**
   - API 재시작 대상이면: `lsof -ti:8000 | xargs kill -9 2>/dev/null || true`
   - 웹 재시작 대상이면: `lsof -ti:3000 | xargs kill -9 2>/dev/null || true`

3. **서버 재시작 (백그라운드)**
   - API 재시작 대상이면 프로젝트 루트에서:
     `uv run --project api python -m uvicorn api.main:app --reload --host 0.0.0.0 --port 8000 > /tmp/focusspot-api.log 2>&1 &`
   - 웹 재시작 대상이면 `web/` 디렉토리에서:
     `pnpm dev > /tmp/focusspot-web.log 2>&1 &`

4. **기동 확인**
   - API 재시작 대상이면: `curl -s http://localhost:8000/docs`가 200 응답할 때까지 대기
   - 웹 재시작 대상이면: `curl -s http://localhost:3000`이 200 응답할 때까지 대기
   - 최대 30초 대기, 실패 시 로그 파일 마지막 10줄을 출력한다

5. **완료 보고**
   - 재시작된 서버의 PID와 로그 파일 경로를 알린다
   - 로그: API → `/tmp/focusspot-api.log`, 웹 → `/tmp/focusspot-web.log`
