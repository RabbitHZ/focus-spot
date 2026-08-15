---
name: code-review
description: 변경된 레이어를 감지해 전문 리뷰어 에이전트를 자동으로 실행한다. /code-review [api|web|ios|all]
disable-model-invocation: false
---

`$ARGUMENTS`에 레이어 지정 가능 (api / web / ios / all). 미지정 시 변경된 레이어를 자동 감지한다.

## 실행 절차

### 1. 변경 레이어 감지 + diff 추출 (Bash로 실행)

```bash
ROOT=/Users/hwa.j/Dev/project/toy/focus-spot

# 변경 레이어 감지
changed=$(git -C "$ROOT" diff HEAD --name-only)
has_api=$(echo "$changed" | grep -c '^api/' || true)
has_web=$(echo "$changed" | grep -c '^web/' || true)
has_ios=$(echo "$changed" | grep -c '^ios/' || true)
echo "changed layers: api=$has_api web=$has_web ios=$has_ios"

# 레이어별 diff 추출 (파일 전체 대신 변경분만)
[ "$has_api" -gt 0 ] && git -C "$ROOT" diff HEAD -- api/ > /tmp/fs_diff_api.txt
[ "$has_web" -gt 0 ] && git -C "$ROOT" diff HEAD -- web/app/ web/components/ web/lib/ web/types/ > /tmp/fs_diff_web.txt
[ "$has_ios" -gt 0 ] && git -C "$ROOT" diff HEAD -- ios/ > /tmp/fs_diff_ios.txt
```

`$ARGUMENTS`가 있으면 해당 레이어의 diff만 추출한다.

### 2. 에이전트에 diff 전달해 리뷰

각 레이어별로 해당 전문 리뷰어 에이전트를 사용한다.
**에이전트에게 파일을 직접 읽히지 않는다.** 대신 diff 내용을 읽어서 에이전트 프롬프트에 포함한다:

```bash
cat /tmp/fs_diff_api.txt   # api 리뷰 시
cat /tmp/fs_diff_web.txt   # web 리뷰 시
cat /tmp/fs_diff_ios.txt   # ios 리뷰 시
```

에이전트 호출 시 프롬프트: "다음 git diff를 기준으로 리뷰하라. 파일 전체를 읽지 말고 이 diff만 분석한다:\n[diff 내용]"

### 3. 결과 요약

- 레이어별 결과를 종합해 Critical → Warning → Suggestion 순으로 정리한다
- 각 항목에 파일 경로와 줄 번호를 포함한다
- diff에 없는 코드에 대한 지적은 하지 않는다
- "수정 필요한 항목이 없습니다" 또는 항목 목록을 명확히 출력한다
