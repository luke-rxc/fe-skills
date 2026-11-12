---
name: figma-to-component
description: Figma 디자인을 분석해 React 컴포넌트를 신규 생성합니다(fe-mobile). 공통 UI(`src/pui`)와 비즈니스(`src/features/{name}` · `src/apps/{domain}`)를 모두 지원합니다 — pui 전용이 아닙니다. TRIGGER when ⓐ 사용자가 컴포넌트 신규 생성을 요청할 때 — Figma 명시 여부·pui/도메인 여부와 무관하게 발동한다. 예: 'pui 컴포넌트 만들어줘', '도메인/비즈니스 컴포넌트 만들어줘', '피그마로 컴포넌트 만들어줘', Figma URL을 붙여넣으며 '이거 만들어줘'. 또는 ⓑ 다른 스킬·워크플로우가 진행 중 UI 컴포넌트를 신규 생성하는 단계에 도달했을 때 — 호출측 지침에 f2c 언급이 없어도 이 스킬에 위임한다(인자 규약 docs/common/input-contract.md). 단 기존 컴포넌트 리뷰/수정/레거시 분석이 아니라 신규 생성일 때로 한정한다.
allowed-tools: Read Grep Glob Write Edit Bash AskUserQuestion Task mcp__figma__* mcp__notion__* mcp__plugin_fe-mobile_figma__* mcp__plugin_common_notion__*
---

# Figma → 컴포넌트 생성

Figma 디자인을 분석해 React 컴포넌트로 만든다. **기존 `src/pui/*` 재사용을 우선**하고, 없는 것만 신규 생성한다.

**입력은 Figma URL 하나면 된다.** 파일 타입·마스터·Doc·서브 컴포넌트·기존 구현 충돌은 `get_metadata` probe로 도출한다. 사람에게 묻는 건 **도구가 알 수 없는 것**뿐이다(랜딩·category·네이밍).

대상 레포: **fe-mobile** (`src/pui/`, `src/features/`, `src/apps/`, `src/styles/theme.ts`).

## 경로 3갈래

Phase 0~1(인테이크·추출·설계)은 공통이고, Phase 2 생성 정책에서 대상에 따라 갈린다:

- **공통 UI** (`src/pui/{category}/{name}/`) → [docs/build/pui-policy.md](docs/build/pui-policy.md) — 디자인시스템 기여, 정책이 두꺼움(스토리 필수·토큰·changelog)
- **비즈니스** → [docs/build/business-policy.md](docs/build/business-policy.md) — pui 조합, 경량. **UI가 들어가는 곳은 두 군데다**:
  - `src/features/{featureName}/components/` — 도메인 **횡단 재사용** 모듈 (2개+ 도메인)
  - `src/apps/{domain}/components/` — 도메인별 **독립** 모듈 (단일 도메인)

---

## 문서 지도

**폴더 = 단계**다. `common/`은 전 Phase 공용, 나머지는 Phase 순서대로 `plan/`(P0~1) → `build/`(P2) → `verify/`(P3).

```
docs/
├── common/   전 Phase 공용 — 게이트·진입 계약
├── plan/     Phase 0~1  인테이크 → 추출·설계
├── build/    Phase 2     생성 → 컨벤션 리뷰  (guide/ = 코드 작성 부가 컨벤션)
└── verify/   Phase 3     측정 검증
```

| 문서 | 언제 읽나 |
|---|---|
| [common/gates.md](docs/common/gates.md) | **전 Phase** — 게이트 규칙·무응답 규칙·카드 규약·실패사례의 **단일 원본** |
| [common/input-contract.md](docs/common/input-contract.md) | Phase 0 진입 — 호출측(다른 스킬·사람)이 넘긴 인자 해석 |
| [plan/intake.md](docs/plan/intake.md) | Phase 0 — URL 파싱·판정표·후보 처리·Doc 감지·확정 카드 |
| [plan/extraction.md](docs/plan/extraction.md) | Phase 1 — 추출·Doc 정책·서브 id·재사용 매핑(**실측 대조 강제**) |
| [build/pui-policy.md](docs/build/pui-policy.md) · [build/business-policy.md](docs/build/business-policy.md) | Phase 2 — 경로별 생성 정책 (공통 UI / 비즈니스) |
| [build/pui-generation-guide.md](docs/build/pui-generation-guide.md) | Phase 2 — 부가 컨벤션 인덱스 → [build/guide/](docs/build/guide/) 4종으로 라우팅 |
| [build/review.md](docs/build/review.md) | Phase 2 — 컨벤션 리뷰 체크리스트 |
| [verify/verification.md](docs/verify/verification.md) | Phase 1 끝(수용기준 작성) · Phase 3(측정 검증 실행) |

---

## 참조 규칙 위치

| 규칙 | 위치 | 로드 방식 |
|---|---|---|
| **PUI 코드 컨벤션** | [../../../plugins/fe-mobile/rules/pui-code-convention.md](../../../plugins/fe-mobile/rules/pui-code-convention.md) (fe-skills `fe-mobile` 플러그인 소유) | `src/pui/**` 파일을 Read/Edit/Write 하면 플러그인 hook이 세션당 1회 자동 주입. **경로 판별처럼 파일을 건드리기 전에 필요하면 위 경로를 직접 Read한다.** |
| **프로젝트 코드 컨벤션** | 프로젝트 저장소의 `CLAUDE.md`/`AGENTS.md` | 세션 시작 시 자동 로드 |

---

## ⚠️ 전역 규칙

> 다른 문서·절에서 이 규칙을 가리킬 땐 **번호가 아니라 이름으로** 부른다. 번호로 참조하면 목록이 바뀔 때 가리키는 대상이 조용히 어긋난다(실측: "전역 규칙 4"가 실제로는 규칙 5를 가리키고 있었다).

1. **무응답·타임아웃은 확정이 아니다** — 추천값 자동 수락 금지. 배칭 호출이 통째로 타임아웃이면 **전 문항 미확정**, 부분 응답이면 **응답된 문항만 확정**. 확정 전 "완료" 보고 금지 → [docs/common/gates.md](docs/common/gates.md)
2. **확정 없이 넘기면 안 되는 값** — 랜딩 / category / 네이밍 / 경로(pui·features·apps)와 그 이름 / (감지 실패 시) Doc · componentGroup. 나머지는 probe로 도출하므로 묻지 않는다.
3. **Gate 2 승인 없이 코드 생성 금지.** Phase 0 인증 실패 시 안내 후 중단.
4. **설계 노트를 유지한다** — 확정값(Gate 1·2)·행동규칙·재사용 매핑·**스토리 구성**·수용기준을 **설계 노트** 하나로 모아 Gate 2 카드와 함께 제시하고, Phase 3은 그 수용기준을 그대로 실행한다. 기본은 **파일 산출물 없이 대화에 남긴다.**
   - **산출물 확장(선택)** — 이 스킬 폴더에 `docs/common/artifact-contract.md`가 **있으면** 그 문서와 `docs/common/phase-checklist.md`를 따라 설계 노트·검증 결과를 파일로 기록한다(없으면 이 항목은 무시). ⚠️ 어떤 경우든 `.claude/`·`.kiro/` 아래에는 쓰지 않는다 — 심볼릭으로 **다른 레포**를 가리킬 수 있다.
5. **실패는 회귀한다** — 리뷰·검증 실패를 임의로 "통과"로 넘기지 않는다.
   - 컨벤션·구현 결함 → Phase 2 생성으로 회귀
   - **설계 결함**(랜딩 구조·서브 분리·API 형태가 틀림) → **Gate 2로 회귀**해 재확정
   - **대상 오인**(마스터·방향이 틀림) → **Gate 1로 회귀**
   - 회귀 사유는 보고에 명시한다.
6. **서브에이전트 보고는 근거가 아니다** — 재사용 매핑은 Figma 실측 ↔ 대상 CSS(`file:line`) 대조 후에만 표에 올린다.
7. **디자인 토큰 하드코딩 금지** — `#fff`/hex/rgba를 박지 말고 `get_variable_defs`의 **토큰 이름**을 `theme.ts` 토큰으로 매핑(→ `docs/build/guide/figma-to-css.md` 3-0). 기존 컴포넌트가 hex를 박고 있어도 따라하지 말 것. 재사용 가능한 pui 우선.
8. **커밋은 별도 요청 시에만.** 본 스킬은 코드(+공통 UI는 스토리·changelog 초안) 생성까지만 수행한다.

---

## 절차

### Phase 0 — 인테이크 → 🚦 Gate 1

1. **Figma MCP 인증 검증 (본 작업 전에 반드시)** — `whoami` 호출. **사용 불가/인증 실패** → Figma 연동 안내([docs/common/figma-mcp-setup.md](docs/common/figma-mcp-setup.md))를 Read해 그 내용을 그대로 제공하고 **중단**(자체 대안 제시 금지).
2. **URL 확보 → 파싱 → probe → 판정 → 확정 카드** → [docs/plan/intake.md](docs/plan/intake.md)
   - URL이 없을 때만 Gate 0으로 묻는다. **파일 타입은 묻지 않는다** — URL fileKey 역조회로 나온다.
   - 호출측이 인자로 준 값은 재질문하지 않는다 → [docs/common/input-contract.md](docs/common/input-contract.md)
3. **🚦 Gate 1 — 대상 확정** (`AskUserQuestion` 1회, ≤4문항) → [docs/common/gates.md](docs/common/gates.md)
   - 마스터(항상) · 경로·도메인(조건부) · Doc 유무(조건부) · 서브 URL(조건부) · 기존 충돌 3-way(조건부)
   - **서브(`<마스터> / …`)는 마스터 옆 형제라 마스터 URL로는 안 보인다.** 대표 variant를 probe해 `<instance name="<마스터명> / …">` 신호가 있으면 서브 URL을 요청한다 → [docs/plan/intake.md](docs/plan/intake.md) §6-2
4. **브랜치 세팅** — 코드를 건드리기 전에. 통합 브랜치(`master`/`develop`/`stage`) 위에서 코드 수정·커밋하지 않는다.
   - 팀 관례: `feature/FE-<티켓번호>`. 커밋 컨벤션이 브랜치명에서 `#FE-티켓`을 추출하므로 티켓이 들어가야 한다. 이미 있으면 전환, 없으면 생성한다.
   - 티켓을 모르면 **사용자에게 한 번만 묻는다**(티켓 번호나 Jira 링크, 없으면 `feature/<slug>`). 🚫 티켓을 찾으려고 Jira 검색을 돌리지 않는다.
   - 미커밋 변경이 있으면 전환 전에 확인받는다. `git push`는 하지 않는다.
   - **현재 브랜치가 이 작업과 무관하면 그대로 쓰지 말 것.** 무관한 티켓 브랜치 위에서 시작하면 남의 커밋을 끌고 간다(실측 실패: 무관한 `FE-6406` 위에서 시작해 사용자가 잡아줬다).
   - 티켓·분기점(master/develop)이 불확실하면 **확정받는다**. 티켓은 README changelog·커밋 컨벤션에도 쓰이므로 여기서 정해두면 뒤가 편하다.
5. **설계 노트 시작** — Gate 1 확정값을 설계 노트에 올린다(산출물 확장이 켜져 있으면 그 계약대로 기록).

**경로 판별(공통 UI vs 비즈니스)** — 단일 기준은 **PUI 코드 컨벤션** **「생성 원칙」**이다(운영은 [docs/build/pui-policy.md](docs/build/pui-policy.md) 0번):
- **전제** — 렌더 트리 안 · 내부 상호작용만 · 비즈니스 로직/데이터 연동 없음. 하나라도 어기면 비즈니스.
- **원칙 1 PDS 정의**(F.M.C., 또는 여러 마스터에 완전히 같은 내부 요소) · **2 Atomic** · **3 Behavior** · **4 Structure** 중 하나를 만족하면 **공통 UI**. 원칙 2~4는 **팀 합의 필수** → 해당 시 경고.
- "2개+ 도메인에서 쓰인다"는 **검토 트리거일 뿐 생성 조건이 아니다.**

`fileKey=pds` + F.M.C. 확정이면 원칙 1이 객관적으로 충족되므로 경로 질문을 생략한다. 그 외(`prizmApp`/`prizmWeb`, F.M.C. 아님, 원칙 2~4 후보)면 Gate 1에서 확인한다.

**비즈니스면 `features`인지 `apps`인지까지 확정한다** — 2개+ 도메인에서 재사용하면 `src/features/{featureName}`, 단일 도메인 전용이면 `src/apps/{domain}`. 이름은 Figma에 없으므로 Gate 1 문항이다.

> ⚠️ **여러 도메인에서 쓰인다고 pui가 아니다 — 갈림은 비즈니스 로직·데이터 연동 유무다.** 로직을 품으면 pui가 아니라 **features**다 → [docs/build/business-policy.md](docs/build/business-policy.md) 0번.

**공통 UI의 배치** — 신규는 `src/pui/{category}/{name}/`(카테고리 폴더 = 스토리 category와 1:1, 폴더명 camelCase). Figma 이름이 `Master / sub`처럼 슬래시로 나뉜 **서브는 마스터 폴더 안에** `MasterSub.tsx`로 둔다 → 컨벤션 「배치」. 기존 평평한 컴포넌트는 옮기지 않는다(팀 마이그레이션 몫).

### Phase 1 — 추출 & 설계 → 🚦 Gate 2

→ [docs/plan/extraction.md](docs/plan/extraction.md)

1. **추출** — `get_design_context` · `get_variable_defs` · **`get_screenshot`(필수, 교차대조)**. Doc이 확정됐으면 함께 추출해 행동 규칙(Pressed/Overflow/Anatomy/a11y)을 뽑는다. 마스터(정적 모양) + Doc(행동 규칙) = 완성.
   - **마스터 실측에 variant 배치(구역·행·열)를 함께 기록한다** — symbol `x`·`y`로 디자이너가 나눈 구역과 순서를 읽는다. 스토리 범주·순서의 근거다 → [docs/plan/extraction.md](docs/plan/extraction.md) · [docs/build/guide/structure.md](docs/build/guide/structure.md) 4번 「스토리 순서·이름 = Figma 배치」
   - ⚠️ **추출한 즉시 설계 노트에 정리한다** — 마스터 직후 / Doc 직후 / 매핑 대조 후 **3시점**. Phase 1은 런에서 가장 비싼 구간(실측 MCP 8회)이고 해석(Doc 문구→행동규칙)이 섞여 같은 복원이 보장되지 않는다 — "Gate 2 때 몰아서" 정리하면 누락이 생긴다.
2. **서브 컴포넌트** — Phase 0에서 확보한 서브 노드에 판정표를 적용해 세트 id를 **부모-자식으로 확정**한다(id 추정 질문 없음). variant symbol id로 서브 단위 정밀 추출.
3. **재사용 매핑** — Code Connect 확인 → `Task`로 `Explore` 서브에이전트 호출 → **Figma 실측 ↔ 대상 CSS(file:line) 대조 후** 표로 정리.
   - ⚠️ **Explore 보고를 그대로 표에 올리지 말 것.** 검증 없이 올렸다가 버튼·헤더 2건이 오답이었다(→ [docs/plan/extraction.md](docs/plan/extraction.md) §4).
4. **수용기준 작성** — 마스터·Doc에서 뽑은 **행동규칙 1건 = 수용기준 1행**. 측정 가능한 단언으로 적어 설계 노트에 남긴다 → [docs/verify/verification.md](docs/verify/verification.md)
   - Phase 1은 이미 "어떻게 동작해야 하는가"를 다 알아냈다. **적지 않으면 Phase 3이 그걸 모른다.**
   - **스토리 구성 표 작성(공통 UI)** — 배치 실측 + Doc 행동규칙에서 「스토리 구성」 표(범주 · 케이스 · 연결 variant · 근거 R#)를 설계 노트에 쓴다. 코드로 먼저 만들고 보여주면 분류가 어긋났을 때 전면 재작성이 된다 → [docs/build/guide/structure.md](docs/build/guide/structure.md) 4번 규칙 8
5. **🚦 Gate 2 — 설계 확정** (`AskUserQuestion` 1회, ≤4문항) → [docs/common/gates.md](docs/common/gates.md)
   - 랜딩(항상) · 네이밍(항상) · category(공통 UI — **배치 폴더도 함께 정해진다**. 섹션 미감지 시 **componentGroup**도 같은 문항) · 서브 분리/정책문서/시맨틱 역할(조건부)
   - **`componentGroup`은 PDS 섹션 이름**이다(컴포넌트명 아님). 섹션 URL이면 probe로 자동, 아니면 묻는다 → [docs/common/gates.md](docs/common/gates.md) Q3
   - **스토리 구성 표를 재사용 매핑 표와 함께 제시한다** — 문항은 따로 만들지 않는다(분류·누락 이의는 Other로) → [docs/common/gates.md](docs/common/gates.md) Gate 2
   - **시맨틱 역할은 여기서 정한다** — 제목 여부·조작 요소 태그·이미지 의미/장식·상태 전달은 Props 구조를 바꾸므로 생성 뒤로 미루지 않는다 → [docs/plan/extraction.md](docs/plan/extraction.md) 「시맨틱 역할 판정」
6. **확정 직후 정리** — Gate 2 확정값 + 수용기준(+ 스토리 구성 이의가 있었으면 표 갱신)을 설계 노트에 반영한다.

**승인 전 코드 생성 금지.**

### Phase 2 — 생성 → 컨벤션 리뷰

1. **생성** — 경로별 정책 문서를 **반드시 읽고** 그대로 따른다:
   - **공통 UI** → [docs/build/pui-policy.md](docs/build/pui-policy.md) + [docs/build/pui-generation-guide.md](docs/build/pui-generation-guide.md)(→ `guide/` 라우팅)
     재사용 우선 → Foundation 토큰(`theme.ts`) → pui 표준 파일 구성 → 스토리 **필수**(`defineMeta`에 Figma nodeId 연결) → README changelog → a11y.
   - **비즈니스** → [docs/build/business-policy.md](docs/build/business-policy.md) — pui 조합 우선 → Gate 1에서 확정한 `src/features/{featureName}/components/` 또는 `src/apps/{domain}/components/`에 경량 생성(**barrel `index.ts` 포함**) → 스토리/README는 선택.
   - PUI 규칙(생성 원칙·배치·**시맨틱**·코드 규칙)은 **PUI 코드 컨벤션**이 단일 기준(`src/pui` 작업 시 자동 주입). 신규 컴포넌트는 **시맨틱 원칙 1~5를 생성 기준으로** 적용한다. 일반 컨벤션은 **프로젝트 코드 컨벤션**(프로젝트 저장소 `CLAUDE.md`/`AGENTS.md`).
   - 생성 직전 **형제 컴포넌트를 Read**해 패턴을 맞춘다 — 가이드는 요약일 뿐, 최종 기준은 실제 코드다.
2. **컨벤션 리뷰** → [docs/build/review.md](docs/build/review.md) — 별도 컨텍스트의 리뷰어(범용 에이전트 → `/code-review` → 셀프 체크 폴백)로 검사하고 `[필수]` 지적이 없을 때까지 수정 루프. **게이트가 아니다**(자동 루프, 결과만 보고).

### Phase 3 — 검증

> 상세: [docs/verify/verification.md](docs/verify/verification.md) — **Phase 1이 적은 수용기준을 여기서 실행한다.**

1. **정적 검사** — `yarn type-check` · `yarn lint`(실패 시 `yarn lint:fix` 검토) · 공통 UI는 `yarn stylelint` 추가.
2. **검증 모드 확인** — **측정(기본·권장)** / **직접 확인** 중 사용자가 고른다. 인자(`--verify=`)나 앞선 발언으로 정해져 있으면 묻지 않고, 아니면 Storybook 요청과 같은 메시지에서 1문항으로 묻는다(수용기준 개수를 함께 적는다) → [docs/verify/verification.md](docs/verify/verification.md) 「검증 모드」.
   - **직접 확인**이면 측정 대신 수용기준을 **스토리별 확인 체크리스트**로 넘기고, 결과를 **"측정 미실행 — 사용자 확인 모드"**로 보고한다(“통과”라고 쓰지 않는다). 아래 측정·육안 단계는 건너뛴다.
3. **측정 검증 (측정 모드 · 주)** — Storybook(6006)은 **사용자에게 `!` 명령으로 띄워 달라고 먼저 요청한다**(에이전트가 샌드박스 안에서 띄우면 브라우저가 접속하지 못한다 → [docs/verify/verification.md](docs/verify/verification.md) 3-0). 뜨면 설계 노트의 **수용기준 표를 하나씩 측정으로 단언**한다(`getComputedStyle`·`getBoundingClientRect`). 도구는 Playwright/Chrome MCP 무엇이든 좋다.
   - **엣지 케이스 스토리**로 일부러 깨뜨린다 — 아주 긴 텍스트·빈 값·아이템 1개/다수(짧은 더미로는 안 드러난다).
   - 측정으로 잡는 것: **색 토큰 적용 범위**(disabled가 정확히 어디까지) · **아이템 폭 균일성** · **말줄임 실제 발동**(`scrollWidth > clientWidth`) · **원/알약 판별**(`width===height` && radius) · **마스크 상태 전이**(scrollLeft 조작) · **이미지 로드 성공**(`complete`·`naturalWidth`).
4. **육안 확인 (보조)** — 측정으로 환원 안 되는 것만: 크롭 위치의 적절성 · 전반적 시각 균형 · Figma 임베드(`design`에 nodeId 연결 시 Design 패널)와의 최종 인상.
   - 🚫 **스크린샷을 Figma와 눈으로 비교해 "일치/불일치"를 판정하지 말 것.** 실측 **4전 4패**다(disabled 범위·이미지 충전·아이템 수·이미지 로드를 모두 오판, 전부 측정으로 뒤집힘) → [docs/verify/verification.md](docs/verify/verification.md) 3번.
5. **결과 보고** — 측정 모드는 기준별 측정값·판정을 표로, 직접 확인 모드는 체크리스트와 모드 표기를 보고한다.
   - **기준 하나라도 실패하면 통과가 아니다.** 회귀한다(→ 전역 규칙 **"실패는 회귀한다"**). 전 기준 통과 전에 완료를 보고하지 않는다.

> ⚠️ **stylelint는 CLI 통과 ≠ 완전 통과 — IDE 진단도 확인.** `npx stylelint`(범위 좁힌 폴백)가 **property-order(`order/properties-order`) 위반을 놓치고 통과**시키는 경우가 있다(실제: `position` 앞 `overflow`, `z-index` 앞 `display`를 CLI는 통과, IDE 진단만 잡음). 속성 순서는 형제 관례(대개 `display`→`overflow`→`position`→`z-index`…)에 맞춘다.

> ⚠️ **`yarn`이 node 엔진 제약으로 막히면 `npx` 폴백.** `package.json` engines가 `node >=18 <20`이라 상위 node(예: 22)에서는 `yarn <script>`가 *"The engine \"node\" is incompatible"* 로 **스크립트 실행 자체를 거부**한다. nvm으로 18.x로 맞추거나, 검증만 빠르게 하려면(생성 폴더로 범위를 좁히면 빠르다):
> ```bash
> npx tsc -p tsconfig.json --noEmit                                        # type-check
> npx eslint --ext .tsx,.ts --fix src/pui/{category}/{name}/                          # lint(+자동수정)
> npx stylelint 'src/pui/{category}/{name}/**/*.{ts,tsx}' --custom-syntax css-in-js   # stylelint
> ```

결과(통과/수정사항)와 생성 파일 목록을 보고한다.

