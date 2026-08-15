---
name: commit-push-pr
description: Conventional Commits 형식으로 변경사항 커밋 → push → GitHub PR 생성까지 한 번에 처리.
disable-model-invocation: true
---

`$ARGUMENTS`에 커밋 메시지(선택)를 받아 다음을 수행한다.

1. **변경사항 확인**
   - `git status`와 `git diff --staged` 실행
   - 스테이징된 파일이 없으면 `git diff`로 변경된 파일 목록을 보여주고 스테이징을 안내한다

2. **커밋 메시지 작성**
   - `$ARGUMENTS`가 있으면 그것을 베이스로 사용
   - Conventional Commits 형식 준수: `<type>(<scope>): <description>`
     - type: feat / fix / chore / refactor / test / docs
     - scope 예시: api, web, ios, condition, cafes, auth
   - 변경 파일을 분석해 적절한 type과 scope 제안
   - 사용자에게 최종 확인 후 커밋

3. **Push**
   - `git push` 실행
   - 원격 브랜치가 없으면 `git push -u origin <branch>` 실행

4. **PR 생성**
   - `gh pr create` 명령으로 PR 생성
   - PR 제목: 커밋 메시지와 동일
   - PR 본문: 변경사항 요약 + 테스트 체크리스트 포함
   - PR URL을 사용자에게 출력
