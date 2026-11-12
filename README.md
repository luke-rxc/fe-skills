# fe-skills

FE 팀 Claude Code 플러그인 마켓플레이스. 프로젝트에서 이것만 설치하면 스킬·MCP·hook이 함께 들어온다.

## 설치

```bash
claude plugin marketplace add luke-rxc/fe-skills

# 프로젝트 전용 플러그인은 해당 프로젝트 루트에서 project scope로 설치 (common은 의존성으로 자동 설치)
cd fe-mobile
claude plugin install fe-mobile@fe-skills -s project
```

설치 후 `/mcp`에서 figma·notion·atlassian OAuth 인증을 1회 진행한다.

## 플러그인

| 플러그인 | 대상 | 스킬 | hook | MCP |
|---|---|---|---|---|
| `common` | 공용 | — | Stop: 작업 완료 macOS 알림 | notion, atlassian |
| `fe-mobile` | fe-mobile (`common` 의존) | `figma-to-component` | PreToolUse: `src/pui/**` Read/Edit/Write 시 PUI 코드 컨벤션 주입(세션당 1회) | figma, playwright |

플러그인 MCP 도구 이름은 `mcp__plugin_<플러그인>_<서버>__<도구>` 형식이다 (예: `mcp__plugin_fe-mobile_figma__whoami`).

## 포함하지 않는 것 (프로젝트 저장소에서 관리)

- **상시 컨텍스트** — 프로젝트 구조·기술 스택·코드 컨벤션·커밋 규칙: 프로젝트 저장소의 `CLAUDE.md`/`AGENTS.md`
- **권한 설정** — `.env` 읽기 차단 등 `permissions`: 프로젝트 저장소의 `.claude/settings.json` (플러그인으로 배포 불가)

## 구조

```
.claude-plugin/marketplace.json   # 플러그인 정의 (strict: false — 구성 요소를 여기서 전부 선언)
.claude/skills/<name>/            # 스킬 원본 (평평하게)
plugins/<plugin>/                 # 플러그인별 hook 스크립트·규칙·MCP 설정
```

- 모든 플러그인의 `source`는 `./`(저장소 루트)다. 스크립트 경로는 `${CLAUDE_PLUGIN_ROOT}/plugins/<plugin>/...`로 쓴다.
- ⚠️ `hooks`는 marketplace.json 항목에 **인라인 객체**로 적는다. 파일 경로(`"./plugins/x/hooks.json"`)로 적으면 validate는 통과하지만 로드되지 않는다(실측).
- 저장소 루트에 `skills/`, `hooks/`, `.mcp.json`을 만들지 않는다 — 모든 플러그인이 같은 루트를 공유하므로 자동 탐색되어 전 플러그인에 섞인다.

## 스킬 추가

1. `.claude/skills/<name>/SKILL.md` 추가 (frontmatter `name` = 폴더명, `description` 필수)
2. 스킬이 필요로 하는 자료는 스킬 폴더 안에 둔다. 프로젝트 저장소 경로(`.claude/rules/...` 등)를 참조하지 않는다.
3. `marketplace.json`의 대상 플러그인 `skills` 배열에 경로 추가, 해당 플러그인 `version` 올리기
4. 검증
   ```bash
   claude plugin validate .
   claude plugin details <plugin>@fe-skills   # 설치 후 Skills/Hooks/MCP 개수 확인
   ```
