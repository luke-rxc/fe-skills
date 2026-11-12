# fe-skills

FE 팀 에이전트 플러그인 마켓플레이스. 프로젝트에서 이것만 설치하면 스킬·MCP·hook이 함께 들어온다.

- 1차 지원: **Claude Code**
- 부분 지원: **Codex** (스킬·HTTP MCP만 동작 — [Codex 제약](#codex-제약) 참고)

## 플러그인

| 플러그인 | 대상 | 스킬 | hook | MCP |
|---|---|---|---|---|
| `common` | 공용 | — | Stop: 작업 완료 macOS 알림 | notion, atlassian |
| `fe-mobile` | fe-mobile (`common` 의존) | `figma-to-component` | PreToolUse: `src/pui/**` Read/Edit/Write 시 PUI 코드 컨벤션 주입(세션당 1회) | figma, playwright |

> 프로젝트 전용 플러그인(`fe-mobile` 등)은 **해당 프로젝트에서만 켠다.** 전역으로 켜면 다른 저장소에서도 스킬이 발동하고 규칙이 주입된다.
> 플러그인 파일은 전역 캐시에 한 번만 받아지고, 어느 프로젝트에서 켤지는 각 프로젝트의 설정 파일이 정한다.

---

## Claude Code

### 설치

프로젝트 루트에서 실행한다. 마켓플레이스 등록 + 플러그인 설치 + 의존성(`common`) 설치가 한 번에 된다.

```bash
cd fe-mobile
claude plugin install fe-mobile --marketplace luke-rxc/fe-skills -s project
```

- `-s project` → 프로젝트의 `.claude/settings.json`에 아래 내용이 **자동으로 기록**된다. 이 파일을 커밋하면 팀원은 프로젝트를 열 때 설치 안내를 받는다(명령 입력 불필요).
  ```json
  {
    "extraKnownMarketplaces": {
      "fe-skills": { "source": { "source": "github", "repo": "luke-rxc/fe-skills" } }
    },
    "enabledPlugins": {
      "fe-mobile@fe-skills": true
    }
  }
  ```
- 나만 쓰려면 `-s local`(`.claude/settings.local.json`, 커밋 안 함), 모든 프로젝트에 쓰려면 `-s user`.
- ⚠️ 프로젝트 `.gitignore`에 `.claude`가 있으면 settings.json을 커밋할 수 없다. `.claude/settings.local.json`만 무시하도록 바꾼다.
- 설치 후 세션에서 `/mcp` → figma·notion·atlassian **OAuth 인증 1회**.

### 업데이트

```bash
claude plugin marketplace update fe-skills        # 마켓플레이스 최신화
claude plugin update fe-mobile@fe-skills -s project
claude plugin update common@fe-skills -s project
```

### 삭제

```bash
claude plugin uninstall fe-mobile@fe-skills -s project
claude plugin prune -s project                    # 더 이상 필요 없는 의존성(common) 정리
claude plugin marketplace remove fe-skills        # 마켓플레이스까지 제거할 때
```

---

## Codex

### 설치 — 프로젝트 단위 (권장)

`codex plugin add`는 **전역에만** 기록하고 프로젝트 파일을 만들지 않는다. 프로젝트 단위로 쓰려면 아래 파일을 **직접 만들어 커밋**한다.

```toml
# fe-mobile/.codex/config.toml
[marketplaces.fe-skills]
source_type = "git"
source = "https://github.com/luke-rxc/fe-skills.git"

# Codex는 의존성을 자동 설치하지 않으므로 common도 명시한다
[plugins."common@fe-skills"]
enabled = true

[plugins."fe-mobile@fe-skills"]
enabled = true
```

- 팀원은 프로젝트에서 Codex를 열기만 하면 마켓플레이스를 받아 자동 설치된다.
- 조건: 프로젝트가 **trusted**여야 한다(처음 열 때 Codex가 묻는다).
- **첫 세션에는 반영되지 않을 수 있다**(설치가 세션 시작보다 늦게 끝남). 한 번 다시 열면 된다.

### 설치 — 전역 (모든 프로젝트)

```bash
codex plugin marketplace add luke-rxc/fe-skills
codex plugin add common@fe-skills
codex plugin add fe-mobile@fe-skills
```

전역 설치 후 특정 프로젝트에서만 쓰려면 `~/.codex/config.toml`에서 `enabled = false`로 바꾸고, 해당 프로젝트 `.codex/config.toml`에서 `enabled = true`로 켠다.

### 업데이트

```bash
codex plugin marketplace upgrade fe-skills
```

설치된 플러그인은 **marketplace.json의 `version`이 바뀐 경우에만** 새로 설치된다.

### 삭제

```bash
codex plugin remove fe-mobile@fe-skills
codex plugin remove common@fe-skills
codex plugin marketplace remove fe-skills         # 마켓플레이스까지 제거할 때
```

프로젝트 단위로 쓰던 경우에는 `.codex/config.toml`에서 해당 항목을 지우거나 `enabled = false`로 바꾼다.

### Codex 제약

| 항목 | Codex |
|---|---|
| 스킬, HTTP MCP(figma·notion·atlassian) | ✅ |
| 의존성 자동 설치 | ❌ `common`을 직접 명시 |
| 플러그인 hook (PUI 컨벤션 주입, 완료 알림) | ❌ 실행되지 않음 |
| playwright MCP | ❌ `${CLAUDE_PLUGIN_ROOT}`가 치환되지 않아 시작 실패 |
| 스킬 본문의 Claude 전용 도구(`AskUserQuestion`, `Task`, `/code-review`) | ⚠️ 의도대로 동작하지 않을 수 있음 |

---

## 포함하지 않는 것 (프로젝트 저장소에서 관리)

- **상시 컨텍스트** — 프로젝트 구조·기술 스택·코드 컨벤션·커밋 규칙: 프로젝트 저장소의 `CLAUDE.md`/`AGENTS.md`
- **권한 설정** — `.env` 읽기 차단 등 `permissions`: 프로젝트 저장소의 `.claude/settings.json` (플러그인으로 배포 불가)

---

## 개발

### 구조

```
.claude-plugin/marketplace.json   # 플러그인 정의 (strict: false — 구성 요소를 여기서 전부 선언)
.claude/skills/<name>/            # 스킬 원본 (평평하게)
plugins/<plugin>/                 # 플러그인별 hook 스크립트·규칙·MCP 설정
```

- 모든 플러그인의 `source`는 `./`(저장소 루트)다. 스크립트 경로는 `${CLAUDE_PLUGIN_ROOT}/plugins/<plugin>/...`로 쓴다.
- ⚠️ `hooks`는 marketplace.json 항목에 **인라인 객체**로 적는다. 파일 경로(`"./plugins/x/hooks.json"`)로 적으면 validate는 통과하지만 로드되지 않는다(실측).
- 저장소 루트에 `skills/`, `hooks/`, `.mcp.json`을 만들지 않는다 — 모든 플러그인이 같은 루트를 공유하므로 자동 탐색되어 전 플러그인에 섞인다.
- 플러그인 MCP 도구 이름은 `mcp__plugin_<플러그인>_<서버>__<도구>` 형식이다 (예: `mcp__plugin_fe-mobile_figma__whoami`).

### 스킬 추가

1. `.claude/skills/<name>/SKILL.md` 추가 (frontmatter `name` = 폴더명, `description` 필수)
2. 스킬이 필요로 하는 자료는 스킬 폴더 안에 둔다. 프로젝트 저장소 경로(`.claude/rules/...` 등)를 참조하지 않는다.
3. `marketplace.json`의 대상 플러그인 `skills` 배열에 경로 추가, 해당 플러그인 `version` 올리기 (**버전을 올려야 사용자에게 업데이트가 배포된다**)
4. 검증
   ```bash
   claude plugin validate .
   claude plugin details <plugin>@fe-skills   # 설치 후 Skills/Hooks/MCP 개수 확인
   ```
