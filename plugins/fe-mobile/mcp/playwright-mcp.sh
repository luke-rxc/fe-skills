#!/bin/bash
# Playwright MCP 서버 실행 스크립트
#
# @playwright/mcp 최신 버전은 Node.js 20 이상을 요구한다.
# 그런데 이 프로젝트는 .nvmrc(v18.20.5)로 Node 18에 고정돼 있어,
# npx를 그대로 실행하면 Node 18로 떠서 "requires Node.js 20" 에러로 즉시 종료된다.
#
# MCP 서버는 프로젝트와 별개의 독립 프로세스(브라우저 자동화 도구)이므로
# 프로젝트 Node 버전과 무관하게 Node 20+ 로 실행해도 된다.
# 여기서는 nvm에 설치된 Node 20+ 중 최신 버전의 bin을 PATH 앞에 붙여
# .nvmrc(18)와 무관하게 MCP만 20+ 로 실행되도록 한다.

NVM_NODE_DIR="$HOME/.nvm/versions/node"

# v20 이상 디렉토리 중 최신 버전을 선택 (버전 정렬 후 마지막)
NODE20_DIR=""
if [ -d "$NVM_NODE_DIR" ]; then
  NODE20_DIR=$(ls -d "$NVM_NODE_DIR"/v* 2>/dev/null \
    | awk -F/v '{ split($2, a, "."); if (a[1] >= 20) print }' \
    | sort -V \
    | tail -1)
fi

if [ -z "$NODE20_DIR" ]; then
  echo "ERROR: Node.js 20 이상이 nvm에 설치돼 있지 않습니다." >&2
  echo "Playwright MCP는 Node 20+ 가 필요합니다. 아래 명령으로 설치하세요:" >&2
  echo "  nvm install 22" >&2
  exit 1
fi

export PATH="$NODE20_DIR/bin:$PATH"

# 기본 출력 폴더(.playwright-mcp/ — 콘솔 로그·스냅샷·스크린샷)는 작업 레포 루트에 생겨
# untracked 부산물로 쌓인다. 레포 밖 임시 폴더로 보낸다(레포별로 분리).
OUTPUT_DIR="${TMPDIR:-/tmp}/playwright-mcp/$(basename "$PWD")"

npx -y @playwright/mcp@latest --output-dir "$OUTPUT_DIR" "$@"
