# fe-skills

FE 팀 에이전트 스킬 마켓플레이스.

## 설치 (Claude Code)

```bash
claude plugin marketplace add luke-rxc/fe-skills
# 프로젝트 전용 플러그인은 해당 프로젝트 루트에서 project scope로 설치
claude plugin install fe-mobile@fe-skills -s project
```

## 플러그인

| 플러그인 | 대상 | 스킬 |
|---|---|---|
| `fe-mobile` | fe-mobile | `figma-to-component` |

## 구조

- 스킬 원본은 `.claude/skills/<name>/` 에 평평하게 둔다 (Agent Skills 표준 폴더).
- 플러그인 구성은 `.claude-plugin/marketplace.json` 한 곳에서 관리한다 (`strict: false`, `skills` 경로 나열).

## 스킬 추가

1. `.claude/skills/<name>/SKILL.md` 추가 (frontmatter `name` = 폴더명, `description` 필수)
2. `marketplace.json`의 대상 플러그인 `skills` 배열에 경로 추가, `version` 올리기
3. `claude plugin validate .` 통과 확인
