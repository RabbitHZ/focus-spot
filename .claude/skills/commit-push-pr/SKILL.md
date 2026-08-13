---
name: commit-push-pr
description: Conventional Commits 형식으로 변경사항 커밋 → push → GitHub PR 생성까지 한 번에 처리.
disable-model-invocation: true
---

`$ARGUMENTS`에 커밋 메시지(선택)를 받아 다음을 수행한다.

1. **변경사항 확인**
   - `git status`와 `git diff HEAD --stat` 실행
   - 스테이징된 파일이 없으면 `git diff HEAD --name-only`로 변경 파일 전체 목록을 출력한다

2. **커밋 그룹 분리 (변경이 많을 때 필수)**
   - 변경된 파일이 **여러 레이어(api/web/ios) 또는 여러 관심사**에 걸쳐 있으면 **반드시 커밋을 나눈다**. 한 커밋에 몰아넣지 않는다.
   - 분리 기준 (비슷한 작업끼리 묶기):
     - `chore(config)`: 설정 파일 변경 (`.claude/`, `CLAUDE.md`, `.env.example` 등)
     - `feat(api)` / `fix(api)`: API 라우터·서비스·모델 변경
     - `feat(web)` / `fix(web)`: 웹 프론트엔드 변경
     - `feat(ios)` / `fix(ios)`: iOS 앱 변경
     - `test`: 테스트 추가·수정만 있는 경우
     - `chore(db)`: alembic 마이그레이션 파일 (API 변경과 함께 묶어도 됨)
   - 각 그룹별로 `git add <파일들>` → `git commit` 순서로 커밋을 나눠서 진행한다
   - 변경이 단일 레이어·단일 관심사이면 커밋 하나로 처리해도 된다

3. **커밋 메시지 작성**
   - `$ARGUMENTS`가 있으면 그것을 베이스로 사용
   - Conventional Commits 형식 준수: `<type>(<scope>): <description>`
     - type: feat / fix / chore / refactor / test / docs
     - scope 예시: api, web, ios, condition, cafes, auth, config, db
   - 변경 파일을 분석해 적절한 type과 scope 제안
   - **커밋 메시지는 반드시 영어로 작성한다** (description 포함)

4. **Push**
   - 모든 커밋 완료 후 `git push` 실행
   - 원격 브랜치가 없으면 `git push -u origin <branch>` 실행

5. **PR 생성**
   - `gh pr create` 명령으로 PR 생성
   - PR 제목: 가장 핵심적인 변경을 대표하는 커밋 메시지 기준
   - PR 본문: 커밋별 변경사항 요약 + 테스트 체크리스트 포함
   - PR URL을 사용자에게 출력
