#!/bin/bash

# ── Stop 이벤트 훅 ──────────────────────────────────────────
# Claude 응답 완료 시 실행됩니다.
# 새로운 기능은 이 파일에 추가하세요.
# ────────────────────────────────────────────────────────────

INPUT=$(cat)

# 작업 완료 macOS 알림
MSG=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
msg = d.get('last_assistant_message', '').strip().replace('\n', ' ')[:40]
print(msg)
" 2>/dev/null)
# 메시지를 AppleScript 문자열에 끼워 넣으면 응답 속 큰따옴표(")가 문법을 깨 알림이 안 뜬다 → argv로 넘긴다
osascript \
  -e 'on run argv' \
  -e 'display notification (item 1 of argv) with title "Claude Code" sound name "Glass"' \
  -e 'end run' \
  "${MSG:-작업 완료}"
