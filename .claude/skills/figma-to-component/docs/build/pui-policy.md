# 공통 UI(pui) 생성 정책 — 상세 경로

대상: `src/pui/{category}/{name}/` 에 추가되는 **디자인시스템 공통 컴포넌트**. 단순 코드 생성이 아니라 **PUI 기여 프로세스**다. 아래 정책을 모두 지킨다.

> **출처(Notion)** — 아래 문서를 기반으로 본 정책을 정리했다. **런타임 조회는 하지 않으며, 이 md 문서가 단일 기준**이다. (원본이 바뀌면 문서를 수동 갱신)
> - **생성 원칙·배치·시맨틱**은 `.claude/rules/pui-code-convention.md`가 단일 기준(원본 Notion 링크·동기화일도 거기)
> - PUI Work Process: https://app.notion.com/p/rxc/PUI-Work-Process-38414ad98d56804ca906e9f2203db3ca
> - PUI Storybook: https://www.notion.so/rxc/PUI-Storybook-8e005c60a5834b60b8cbdcf9f2d10cd2

## 0. 이게 공통 UI(PUI)가 맞는가 — 생성 판단 기준 (필수)

판정 기준은 `.claude/rules/pui-code-convention.md` **「생성 원칙」**이 소유한다(전제 + 원칙 1~4). 여기서는 **스킬이 그 기준을 어떻게 운영하나**만 정한다. 하나도 해당 안 되면 비즈니스 컴포넌트(→ business-policy.md)다.

1. **전제부터 본다** — 렌더 트리 밖에서 동작하거나, 비즈니스 로직·데이터 연동이 필요하면 원칙을 볼 것도 없이 비즈니스다.
2. **원칙 1(PDS 정의)** — `fileKey=pds` + F.M.C.면 객관적으로 충족(`get_metadata`로 `<symbol>`/`<instance>` 확인 → [plan/intake.md](../plan/intake.md) §4). 마스터 **내부 요소**를 분리하려면 여러 마스터에서 디자인과 UI/UX 처리가 **완전히 같은지** 근거(`file:line`·노드 id)를 카드에 단다.
3. **원칙 2~4(Non-PDS)** — Atomic / Behavior / Structure 중 **어느 원칙의 어느 조건을 만족하는지** 카드에 적고 Gate 1에서 확인받는다.
   - ⚠️ **팀 합의가 필수**다. 스킬이 임의로 확정하지 말고 **"팀 합의가 필요한 케이스"임을 명확히 경고**한 뒤 진행 여부를 확인한다. 배치는 `nonPds/`.
   - **"2곳 이상에서 쓰인다"만으로는 근거가 안 된다** — 검토 트리거일 뿐이다.
   - 🚨 **`src/features/`와 혼동하지 말 것 — 갈림은 "비즈니스 로직 유무"다.** `src/features/{featureName}`도 **도메인 횡단 재사용 모듈**이라 "2곳 이상 도메인"에서 쓰인다. 차이는 pui가 **비즈니스 로직·데이터 연동이 없어야** 한다는 점이다(features는 `apis/`·`services/`·`models/`를 갖는다). **로직을 품으면 pui가 아니라 features다** → [business-policy.md](business-policy.md) 0번.

> **"pui가 아니다"는 곧 `apps/`가 아니다.** 비즈니스 경로는 **`src/features/{featureName}/components/`(도메인 횡단)와 `src/apps/{domain}/components/`(도메인 전용) 둘**이며, 어느 쪽인지는 Gate 1에서 확정한다.

## 1. 생성 전 — 재사용 우선

PUI 공식 목표: **"불필요한 컴포넌트 생성을 줄이고 재사용성을 높인다."**

- `src/pui/README.md`의 PUI 리스트(약 90여 개)에서 유사 컴포넌트 확인.
- 기존 스토리의 `defineMeta` `design` nodeId를 대상 노드와 grep 대조(역방향 매핑).
- 유사 컴포넌트가 있으면 **신규 생성 대신 확장/variant 추가**를 우선 제안.

> **코드 작성법(HOW)은 [pui-generation-guide.md](pui-generation-guide.md) 로 분리했다.** 이 문서(2~4번)는 정책상 **무엇이 필수인가**만 규정하고, 실제 골격·예시는 그쪽을 따른다.

## 2. 디렉토리 / 파일 구성 (필수 산출물)

**위치**: 신규는 `src/pui/{category}/{name}/`(카테고리 폴더 = Gate 2 category와 1:1, 폴더 camelCase). Figma 슬래시 이름의 서브는 마스터 폴더 `components/`에 `MasterSub.tsx`로 두고 `index.ts`에서 export → 컨벤션 「배치」.

필수: `index.ts`(barrel export), `components/{Name}.tsx`, `components/{Name}.stories.tsx`(스토리 필수), `README.md`(Changelog 필수). 복잡도에 따라 `constants/`·`hooks/`·`styles/` 등 추가. 참고(기존 평평한 구조 — 파일 구성만 참고하고 위치는 따르지 않는다): 단순형 `src/pui/button/`, 복합형 `src/pui/modal/`, 풍부형 `src/pui/goods/`. **파일 구성·작성 골격·형제 컴포넌트 참고법은 [guide/structure.md](guide/structure.md) 1·2번.**

## 3. Foundation 토큰 (하드코딩 절대 금지)

색상·타이포·반경·간격은 모두 `src/styles/theme.ts` 토큰 사용(하드코딩 금지). Figma `get_variable_defs` 결과를 토큰에 대응시키고, 모호하면 임의값 금지 → 사용자 확인. **토큰 접근 패턴·믹스인 사용법은 [guide/figma-to-css.md](guide/figma-to-css.md) 3번.**

## 4. 스토리 작성 (필수작성)

PUI 분류는 스토리북 **필수작성** 대상. `@pui/_utils`의 `defineMeta`를 쓰고 **원본 Figma nodeId를 `design`에 연결**. 스토리는 **Figma 배치 매트릭스(디자이너가 나눈 구역을 범주로) + Figma 밖 케이스(상태·랜딩·엣지)** 로 구성한다 — Work Process의 "기본 + Variant별 + 상태별"을 Figma 순서로 구체화한 것이다. 분류(`category`)는 정확히 — 잘못되면 탐색이 어려워져 공식 목표 위배. **defineMeta 작성 예시는 [guide/structure.md](guide/structure.md) 4번.** `FIGMA_FILES`/`parseFigmaUrl`로 URL→파일 타입을 역조회하는 규칙은 [plan/intake.md](../plan/intake.md).

- **작성 규칙은 팀 원본(Notion PUI Storybook) 5건을 따른다** — 컴포넌트당 파일 1개 · 케이스당 story 1개(케이스 보드 금지) · Template은 args 그대로 · title 패턴(Non-PDS는 componentGroup 없음) · design 배열. 요약·예시는 [guide/structure.md](guide/structure.md) 4번 「팀 작성 규칙」.
- **스토리 순서·이름은 Figma 마스터 배치를 따른다** — 디자이너가 나눈 구역을 큰 범주 접두어로(`스몰_`·`그룹오프_`), 구역 안은 행 → 열 순으로 export하고, variant 스토리엔 개별 `design`을 연결한다. 상세는 [guide/structure.md](guide/structure.md) 4번 「스토리 순서·이름 = Figma 배치」.
- **서브 컴포넌트는 서브마다 별도 스토리 파일(`{Name}{Sub}.stories.tsx`)** — 컨벤션은 마스터 스토리에 함께 두는 것도 허용하지만, 이 스킬은 **분리를 기본**으로 한다. 마스터 스토리에 몰면 서브의 variant·엣지 케이스가 루트 스토리들 사이에 묻혀 단독으로 확인하기 어렵다(실측: `OrderVoucher` 드라이런에서 서브를 한 파일에 몰았다가 분리가 낫다고 판단). 서브 스토리의 `design`에는 **서브 세트 id**를 연결한다. 마스터 스토리는 서브를 조합한 루트 모습만 다룬다.
- **enum variant prop은 값마다 별도 스토리 필수(강제)** — 대개 Figma 축이라 배치 규칙으로 충족되고, Figma 축에 없으면 `{prop 범주}_{값}`으로 둔다. 값이 유한한 variant/enum prop(예: `tagType`, `type`, `size`)은 **각 값을 개별 스토리로** 만들어 Storybook에서 값별 노출을 육안 확인할 수 있게 한다. **특히 자신이 enum을 정의하지 않고 다른 pui의 태그/뱃지 타입을 prop으로 위임받는 소비 컴포넌트**(예: `GoodsMedium.tagType: PrizmOnlyTagType`)도 값별 스토리를 누락하지 말 것. 실제 누락 사례: `GoodsMedium`이 `tagType`을 받으면서 타입별 스토리가 빠져 태그 타입 노출을 확인할 수 없었다. (작성법은 [guide/structure.md](guide/structure.md) 4번.)

## 5. README Changelog (필수)

PUI 신규/수정 시 컴포넌트 폴더의 `README.md`에 Changelog 작성 + `src/pui/README.md` PUI 리스트에 항목 추가.

- **최신 항목을 맨 위에** 추가.
- 형식: `### [YYYY.MM.DD](JIRA 링크)` → `#### 카테고리` → `* 변경 내용`
- 카테고리: **Added**(신규) / **Changed**(변경) / **Fixed**(수정) / **Deprecated**(지원 중단 예정) / **Removed**(제거) / **Etc**(기타) (Security 포함 가능)

```
## Changelog

### [YYYY.MM.DD](https://rxc.atlassian.net/browse/FE-XXXX)
#### Added
  * `{Name}` 컴포넌트 신규 추가 (#FE-XXXX)
```

## 6. 접근성 / 품질

신규 컴포넌트는 컨벤션 **「시맨틱」 원칙 1~5**를 생성 기준으로 적용한다 — 네이티브 태그 · 헤딩 태그 prop(`titleIs`) · 대체 텍스트 · 버튼/링크 이름 · role/상태/live. **시맨틱 값(헤딩 레벨·alt·aria-label)은 prop으로 열고 PUI가 정하지 않는다.** Doc의 a11y 규칙이 있으면 그것도 수용기준으로 올린다. addon-a11y가 스토리북에 적용돼 있다.

## 7. 검증

`yarn type-check` → `yarn lint`(`yarn lint:fix`) → `yarn stylelint` → `yarn storybook`(포트 6006, Figma 임베드 대조). 모두 통과 + 스토리 렌더 확인 후 보고.

> **Work Process 범위**: 실제 팀 절차는 ①Figma 배포(Product 채널 공유) → ②공통 UI 여부 판단(PDS면 PUI, 그 외 공통은 논의) → ③개발 → ④README+Storybook 작성. 본 스킬은 **②판단 보조 + ③개발 + ④초안 생성까지** 수행하고, 디자인 배포/팀 합의/PR·리뷰는 사용자가 진행한다.
