---
name: verify
description: API 테스트(pytest) + 웹 타입체크 + 린트를 한 번에 실행해 변경사항 검증. 커밋 전 또는 PR 전에 사용.
disable-model-invocation: false
---

다음 순서로 전체 검증을 실행한다. 각 단계 실패 시 즉시 멈추고 오류를 분석해 수정 방안을 제안한다.

1. **API 린트 & 포맷 체크**
   - `cd api && uv run ruff check .`
   - `uv run ruff format --check .`
   - 오류 있으면 자동 수정 가능 여부 판단 후 제안

2. **API 테스트**
   - `cd api && uv run pytest -v`
   - 실패한 테스트가 있으면 오류 메시지를 분석해 원인 설명

3. **웹 타입 체크**
   - `cd web && pnpm type-check`
   - TypeScript 오류가 있으면 파일별로 정리해서 보여준다

4. **웹 린트**
   - `cd web && pnpm lint`
   - ESLint 오류가 있으면 자동 수정 가능 여부 판단 후 제안

5. **결과 요약**
   - 전체 통과 시: "✓ 모든 검증 통과 — 커밋 가능합니다"
   - 실패 항목이 있으면: 항목별 요약 + 수정 우선순위 제안
