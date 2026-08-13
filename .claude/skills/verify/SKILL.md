---
name: verify
description: API 테스트(pytest) + 웹 타입체크 + 린트를 한 번에 실행해 변경사항 검증. 커밋 전 또는 PR 전에 사용.
disable-model-invocation: false
---

다음 순서로 전체 검증을 실행한다. **각 단계는 아래 명시된 압축 명령으로 실행하여 출력을 최소화한다.** 실패 시에만 상세 내용을 노출한다.

## 실행 명령 (복사해서 그대로 사용)

### 1. API 린트 & 포맷 체크

```bash
ROOT=/Users/hwa.j/Dev/project/toy/focus-spot; \
  ruff_out=$(uv run --project "$ROOT/api" ruff check "$ROOT/api" 2>&1); \
  ruff_fmt=$(uv run --project "$ROOT/api" ruff format --check "$ROOT/api" 2>&1); \
  ruff_err=$(echo "$ruff_out" | grep -cE '^\S+\.py' || true); \
  fmt_err=$(echo "$ruff_fmt" | grep -c 'would reformat' || true); \
  echo "ruff check: $([ "$ruff_err" -eq 0 ] && echo OK || echo "$ruff_err errors")"; \
  echo "ruff format: $([ "$fmt_err" -eq 0 ] && echo OK || echo "$fmt_err files need format")"; \
  [ "$ruff_err" -gt 0 ] && echo "$ruff_out"; \
  [ "$fmt_err" -gt 0 ] && echo "$ruff_fmt"; \
  true
```

### 2. API 테스트 (압축 출력)

```bash
ROOT=/Users/hwa.j/Dev/project/toy/focus-spot; \
  result=$(uv run --project "$ROOT/api" python -m pytest "$ROOT/api/tests/" -q --tb=short 2>&1); \
  summary=$(echo "$result" | tail -2); \
  failed=$(echo "$result" | grep -E '^FAILED' || true); \
  errors=$(echo "$result" | grep -E '^ERROR' || true); \
  echo "pytest: $summary"; \
  [ -n "$failed" ] && echo "--- failures ---" && echo "$failed"; \
  [ -n "$errors" ] && echo "--- errors ---" && echo "$errors"; \
  [ -n "$failed$errors" ] && echo "--- detail ---" && echo "$result" | grep -A 20 'FAILURES\|ERRORS'; \
  true
```

### 3. 웹 타입 체크 (압축 출력)

```bash
ROOT=/Users/hwa.j/Dev/project/toy/focus-spot; \
  result=$(cd "$ROOT/web" && pnpm type-check 2>&1); \
  err_count=$(echo "$result" | grep -c 'error TS' || true); \
  echo "type-check: $([ "$err_count" -eq 0 ] && echo OK || echo "$err_count errors")"; \
  [ "$err_count" -gt 0 ] && echo "$result" | grep 'error TS' | head -20; \
  true
```

### 4. 웹 린트 (압축 출력)

```bash
ROOT=/Users/hwa.j/Dev/project/toy/focus-spot; \
  result=$(cd "$ROOT/web" && pnpm lint 2>&1); \
  err_count=$(echo "$result" | grep -cE 'error(\s|$)' || true); \
  warn_count=$(echo "$result" | grep -cE 'warning(\s|$)' || true); \
  echo "eslint: $([ "$err_count" -eq 0 ] && echo OK || echo "$err_count errors, $warn_count warnings")"; \
  [ "$err_count" -gt 0 ] && echo "$result" | grep -E 'error|warning' | head -20; \
  true
```

## 결과 판단

- 모든 단계 OK → "✓ 모든 검증 통과 — 커밋 가능합니다"
- 실패 항목 있음 → 압축 출력에서 드러난 오류만 분석해 수정 방안 제안
- **전체 출력을 다시 반복하지 않는다** — 이미 압축된 내용을 그대로 활용한다
