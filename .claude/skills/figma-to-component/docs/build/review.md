# Phase 2 — 컨벤션 리뷰

> 로드 시점: Phase 2, 코드 생성 직후. 생성 규칙 자체는 [guide/](pui-generation-guide.md), 게이트 규칙은 [common/gates.md](../common/gates.md).

방금 만든 코드가 **컨벤션대로 구현됐는지** 별도 컨텍스트에서 검사한다. **게이트가 아니다** — 자동 루프이고 결과만 보고한다.

## 왜 별도 컨텍스트인가

방금 자기가 쓴 코드를 자기가 보면 **"의도한 대로 읽어버리는" 편향**이 있다. 아래 체크 항목은 전부 **실제로 통과한 적 있는 실수**들이다 — 정적 검사(type/lint/stylelint)를 전부 통과하면서 화면이나 다크모드만 조용히 깨진다.

---

## 1. 리뷰어 — 폴백 체인

이 스킬은 다른 툴에서도 쓴다. 위에서부터 **가능한 첫 번째**를 쓴다:

1. **범용 에이전트**(`general-purpose` 등 Task로 띄울 수 있는 것) — 별도 컨텍스트만 확보되면 목적은 달성된다. 기준은 아래 체크리스트를 프롬프트에 통째로 싣는 것으로 전달하므로 **전용 리뷰 에이전트가 필요 없다.** 리뷰어에게는 **파일을 고치지 말고 지적만 보고하라**고 명시한다(수정은 메인이 한다)
2. **빌트인 `/code-review`**
3. **인라인 셀프 체크** — 서브에이전트를 못 띄울 때만. **"셀프 체크로 수행함"을 보고에 명시**한다(편향이 남아 있음을 사용자가 알아야 한다)

### 🔑 포터빌리티 요건 — 이 문서가 체크리스트를 온전히 소유한다

폴백 대상이 **팀 컨벤션을 전혀 모르는 범용 에이전트**일 수 있다. 따라서:

> **리뷰어의 사전 지식에 기대는 지시를 쓰지 않는다.** "팀 컨벤션대로 봐줘" 같은 프롬프트는 금지. **판단 기준을 전부 프롬프트에 실어 보낸다.**
> 리뷰어는 **실행자일 뿐**이고, 기준은 이 문서가 소유한다. 그래야 어떤 에이전트로 갈아끼워도 결과가 같다.

**프롬프트 조립 방법**: 아래 §3 체크리스트를 **근거 경로와 함께 그대로 프롬프트에 넣고**, 대상 파일 경로와 "각 항목에 대해 위반/통과와 근거 file:line을 보고하라"를 덧붙인다. 리뷰어가 규칙을 찾아 읽게 만들지 말 것(못 찾으면 조용히 통과시킨다).

---

## 2. 리뷰 전 필수 — 생성 직전 체크

리뷰를 요청하기 전에 아래가 됐는지 확인한다(옛 가이드 5번 "생성 직전 체크"):

1. **형제 컴포넌트 1개 Read** — 가이드 패턴은 요약일 뿐. 실제 네이밍/스타일/export는 같은 폴더(또는 유사 복잡도) 컴포넌트를 열어 그대로 따랐는가.
2. ****PUI 코드 컨벤션** 준수** — `src/pui` 파일을 다루면 세션에 자동 로드되는 기본 규칙.
3. ****프로젝트 코드 컨벤션**(프로젝트 저장소 `CLAUDE.md`/`AGENTS.md`) 준수** — alias 필수, props 타입 파일 내 정의, JSDoc 한국어, `any` 최소화 등.

---

## 3. 체크리스트 (리뷰어 프롬프트에 그대로 싣는다)

> 각 항목: **위반 여부 + 근거 `file:line`**. 애매하면 위반으로 보고하고 판단은 넘긴다.

### A. 토큰·색 (실패 이력 있음 — 다크모드가 조용히 깨진다)

- [ ] **hex/rgba 하드코딩이 없는가** — `#fff`·`#ffffff`·`rgba(...)` 리터럴 색이 코드에 박혀 있으면 위반. 모든 색은 `${({ theme }) => theme.color.*}`.
  - `grep -nE "#[0-9a-fA-F]{3,8}\b|rgba?\(" <생성 파일>`
- [ ] **prop으로 넘기는 색도 hex가 아닌가** — 예: `<CountDown textColor="#fff" />` 금지. 부모 styled에서 `${CountDown}` 블록으로 토큰 오버라이드.
- [ ] **간격/반경/폰트가 토큰인가** — `theme.spacing.s*` / `theme.radius.r*` / `theme.fontType.*`. 임의 rem 값 남발이면 지적.
- [ ] 근거: `guide/figma-to-css.md` 3-0, 3-3

### B. 기존 pui 재사용 (직접 만들면 거의 항상 위반)

- [ ] **inline `<svg>`가 없는가** — 단색 글리프는 `@pui/icon` 프리셋 import.
- [ ] **`<img>` 직접 사용이 없는가** — 일반 이미지는 `@pui/image`의 `ImageProps` + `<Image />`.
- [ ] **Figma asset URL(`figma.com/api/mcp/asset/...`)이 박혀 있지 않은가** — 7일 후 만료. 컴포넌트/스토리 어디에도 없어야 한다.
- [ ] **inline `<a>`/`<button>`이 없는가** — 랜딩/액션은 `@pui/action`의 `Action`.
- [ ] **앵커 중첩이 없는가** — `<a>` 안에 `<a>`/`<button>` 금지. 전체+내부 랜딩이 공존하면 영역별 분리.
- [ ] **자식 pui를 조합했다면 Props를 통으로 받는가** — 개별 prop 재선언(`image`·`brandName`·`goodsName`…)이면 위반. `goods: GoodsMediumProps` 형태.
- [ ] 근거: `guide/composition.md` 3-1, 3-2, 3-4, 3-7

### C. 치수·반응형 (320px 기기에서 깨진다)

- [ ] **절대 px 고정폭이 없는가** — `width: 34.5rem` 같은 Figma 캔버스 폭 복사는 위반. `100%` 또는 `calc(...)` + `max-width`.
- [ ] **비정사각 요소에 `50%`/`r100` radius가 없는가** — 타원·알약화. 원형이면 `width === height` 보장 후.
- [ ] **패딩 중복이 없는가** — wrapper + 루트 + 자식이 같은 방향 패딩을 겹쳐 주지 않았는가.
- [ ] **고정 높이 + 다중행 말줄임이면 슬롯 계산을 했는가** — `N × lineHeight ≤ (카드높이 − 패딩 − 형제높이 − gap)`. 초과하면 마지막 줄이 잘리는데 **정적 검사는 전부 통과한다**.
- [ ] **mixin 숫자 인자 단위** — `absolute({ t: 12 })` = `1.2rem`(내부 `/10`). `{ t: 1.2 }`로 쓰면 `0.12rem` 버그.
- [ ] 근거: `guide/figma-to-css.md` 3-3-1, 3-6

### D. 컴포넌트 골격

- [ ] **`forwardRef<RefType, PropsType>` 제네릭 명시** + ref가 루트 DOM에 연결
- [ ] **Props는 `export interface {Name}Props`로 파일 상단** (별도 `types/` 파일 생성 금지), 적절한 `HTMLAttributes<...>` 확장
- [ ] **모든 prop에 한국어 JSDoc**
- [ ] **prop 선언 순서** — 데이터/표시 props 먼저 → `on*` 핸들러는 맨 아래로 분리
- [ ] **Boolean prop에 `is` 접두사 금지** — `disabled` (O) / `isDisabled` (X)
- [ ] **UI에 쓰이지 않는 도메인 값을 prop으로 선언하지 않았는가** — 상태 코드·로깅용 값(`goodsStatus` 등)이 Props에 있으면 위반(`...rest`로 DOM에 새어 React 경고). Props가 `DataAttributes`(`import type { DataAttributes } from '@pui/_types'`)를 확장해 `data-*`로 받고, 루트 요소에 `{...rest}`를 스프레드해야 한다
- [ ] **styled 컴포넌트는 변수로 선언** (익명함수 금지), 색은 styled 내부 `${({ theme }) => ...}`로 접근(`useTheme` 아님)
- [ ] **CSS 선택자에 태그명 금지** (클래스/컴포넌트 셀렉터)
- [ ] **배열 key에 index 사용 금지**
- [ ] **상대 경로(`../../../`) 금지** — alias(`@pui/`·`@utils/`·`@constants/` …)
- [ ] 근거: **PUI 코드 컨벤션**, `guide/structure.md` 2

### E. 스토리 (`defineMeta`)

- [ ] **`category`가 Gate 2에서 확정된 값인가** — 형제 컴포넌트 값을 임의로 미러링했으면 위반(실패 이력: `SelectVoucher`에 `DataDisplayCardType` 답습 → 정답 `DataEntry`)
- [ ] **`componentGroup`이 PDS 섹션 이름인가** — 섹션 감지값(`[자동]`) 또는 Gate 2에서 확정한 값이어야 한다. 컴포넌트명을 기본값으로 채웠거나 이름이 비슷한 형제에 임의로 묶었으면 위반(실패 이력: `SelectVoucher` → `'Voucher'` 임의 묶음 / `PriceArea` → `'PriceArea'`, 정답 `'Goods'`)
- [ ] **`design`의 `nodeId`가 dash 포맷인가** — `1782-2695` (colon `1782:2695` 아님)
- [ ] **`file`이 URL fileKey 역조회 결과와 일치하는가** — `pds`/`prizmApp`/`prizmWeb`
- [ ] **enum/유한값 variant prop마다 개별 named export 스토리가 있는가** — Figma 축이면 매트릭스로, 아니면 `{prop 범주}_{값}`으로
- [ ] **엣지 케이스 스토리가 있는가** — 아주 긴 텍스트·빈 값
- [ ] **케이스마다 story가 하나인가** — 한 story에서 `cases.map`·여러 인스턴스 나열(케이스 보드)이면 위반(실패 이력: `PriceArea`의 `Small케이스`·`Mini케이스` 보드)
- [ ] **Template이 args를 그대로 넘기는가** — Template 안 병합·가공 금지, 공통값은 story `.args`에서. 표시용 래퍼는 `decorators`
- [ ] **컴포넌트당 stories 파일이 하나인가** — 케이스별 파일 분할 금지(서브는 자기 파일)
- [ ] **스토리 순서·이름이 Figma 배치를 따르는가** — 큰 범주 접두어 = 마스터 캔버스 구역, 구역 안은 행 → 열 순으로 export(`{범주}_{케이스}`). Figma 밖 케이스는 매트릭스 뒤 `상태_`·`랜딩_`·`엣지_` 등으로. 범주가 제각각·순서가 섞였으면 위반(실패 이력: FE-6555 `GoodsSmall`·`PriceArea` 전면 재작성)
- [ ] **Figma variant 스토리에 story 단위 `design`(variant nodeId)이 있는가** — `figma({ file, nodeId })`
- [ ] **화면으로 확인되는 Doc 행동규칙마다 story가 있는가** — JSDoc에 R# 표기. 규칙이 빠졌으면 위반(실패 이력: `GoodsSmall` R12·R13 누락)
- [ ] **export 목록이 설계 노트 「스토리 구성」 표와 일치하는가** — 표에 없는 스토리 추가·순서 변경이 있으면 표부터 갱신
- [ ] **decorators가 Figma 캔버스만 재현하는가** — Figma에 없는 흰 박스·radius·여백 래퍼를 덧댔으면 위반(실패 이력: `GoodsSmall` Grouped on `GroupBox`)
- [ ] **Non-PDS면 `componentGroup`이 없는가** — title은 `category/name`
- [ ] **언더스코어 쓴 export명에 영문이 없는가** — `그룹Off_기본`·`Small_판매중`·`태그_PrizmOnly` → lint 에러. 전부 한글(`그룹오프_기본`)
- [ ] 근거: `guide/structure.md` 4 「팀 작성 규칙」(원본 Notion PUI Storybook) · 「스토리 순서·이름 = Figma 배치」

### F. 파일 구성

- [ ] **`index.ts` barrel export**가 형제 패턴과 일치
- [ ] **`README.md` Changelog** 작성 (공통 UI 필수)
- [ ] **신규 공통 UI가 `src/pui/{category}/{name}/`에 있는가** — 카테고리 폴더가 스토리 `category`와 1:1인가, 폴더명이 camelCase인가. Figma 슬래시 이름의 서브가 마스터 폴더 안 `MasterSub.tsx`로 있고 `index.ts`에서 export되는가. 서브마다 **별도 스토리 파일**(`MasterSub.stories.tsx`, `design`에 서브 세트 id)이 있는가
- [ ] **컴포넌트 전용 유틸이 컴포넌트 폴더의 `utils/`에 있는가** — root `@utils`에 새로 만들었으면 위반(기존 공용 인프라 유틸 재사용은 허용)
- [ ] 근거: `guide/structure.md` 1, **PUI 코드 컨벤션** 「배치」

### F-2. 시맨틱 (신규 공통 UI)

- [ ] **클릭은 `<button>`, 이동은 `<a>`(`Action`), 입력은 `<input>`인가** — `div`+onClick이면 `role`+`tabIndex`+Enter/Space 복원이 있는가. 관측용 요소에 불필요한 `role`·`tabIndex`가 없는가
- [ ] **제목 요소에 헤딩 태그 prop(`titleIs`)이 열려 있는가** — 레벨을 컴포넌트가 하드코딩하지 않았는가
- [ ] **이미지 `alt`·아이콘 `aria-label`/`aria-hidden`을 prop으로 받을 수 있는가** — 장식이면 `alt=""`/`aria-hidden`, 이중 낭독 없음
- [ ] **텍스트 없는 버튼·링크에 이름(`aria-label`)을 받을 수 있는가** — 이름에 역할·동작을 넣지 않음, 토글은 `aria-pressed`
- [ ] **상태를 색으로만 표현하지 않는가** — role + `aria-checked`/`aria-pressed`/`aria-selected`, 동적 알림은 `role="status"`/`"alert"` + `aria-live`
- [ ] 근거: **PUI 코드 컨벤션** 「시맨틱」

### G. 정책 반영 (해당 시)

- [ ] **Doc의 행동 규칙이 코드에 반영됐는가** — Pressed 오버레이 / Overflow·최대 줄수 / Anatomy / a11y
- [ ] **외부 표기 정책 종속 값이 하이브리드인가** — 원천 데이터 prop + 내부 유틸 호출 + 오버라이드 prop. "가공된 문자열만 받는" 설계면 위반
- [ ] **런타임 파생 상태를 enum prop으로 주입받지 않는가** — 예정/진행/종료는 타임스탬프에서 파생
- [ ] 근거: `guide/policy.md` 3-5, 3-5-1

---

## 4. 수정 루프

```
코드 생성 → 리뷰 요청 → 지적 있음?
  ├─ 없음 → ✅ Phase 3 검증으로
  └─ 있음 → 수정 → 재리뷰 → (반복)
```

- **`[필수]` 지적이 남아 있으면 통과가 아니다.** 고치고 다시 리뷰한다.
- `[권장]`/`[제안]`은 판단해서 반영하거나 보고에 기록.
- **임의로 "통과"로 넘기지 않는다** (전역 규칙 **"실패는 회귀한다"** → [../../SKILL.md](../../SKILL.md)).
- 리뷰 지적이 코드 결함이 아니라 **설계 애매점**(랜딩 범위·식별자 prop 필요 여부 등)이면 임의 결정하지 말고 **사용자에게 확인**한다.

### 잘못된 패턴

```
❌ 리뷰 스킵하고 type-check만 통과 → "완료"
❌ 리뷰어에게 "팀 컨벤션대로 봐줘"만 던짐 → 범용 에이전트는 기준을 모른다
❌ 지적을 받고 "이건 기존 컴포넌트도 그러니까 괜찮다" → 기존의 hex 하드코딩은 알려진 안티패턴이다
```

## 5. 보고

- 어떤 리뷰어로 수행했는지(폴백 단계 명시 — 특히 인라인 셀프 체크였다면)
- 지적 목록과 처리 결과
- 남은 `[권장]`/`[제안]`
