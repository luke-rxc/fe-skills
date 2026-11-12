# 비즈니스 컴포넌트 생성 정책 — 경량 경로

대상: **pui가 아닌** 두 경로에 추가되는 조합 컴포넌트. 공통 UI(pui)보다 정책이 가볍고, 핵심은 **pui 재사용을 통한 조합**이다.

| 경로 | 성격 (steering `structure.md`) | 언제 |
|---|---|---|
| `src/apps/{domain}/components/` | 도메인별 **독립** 모듈 | **단일 도메인 전용** |
| `src/features/{featureName}/components/` | 도메인 **횡단 재사용** 모듈 | **2개+ 도메인에서 재사용** · 앱 모듈 간 순환 참조 회피 |

> 출처: PUI Storybook 분류상 Feature/Apps는 스토리 **필수작성 아님**(점진적). 도메인 단위 컴포넌트·페이지 템플릿.

## 0. 경로 선택 — pui / features / apps (Gate 1에서 확정)

**세 경로는 배타적이고, 순서대로 판정한다.**

1. **PUI 생성 원칙**(**PUI 코드 컨벤션** 「생성 원칙」, 운영은 [pui-policy.md](pui-policy.md) 0번)을 만족 → `src/pui/{category}/{name}/` (여기서 끝)
2. **2개+ 도메인에서 재사용** → `src/features/{featureName}/components/`
3. 그 외(단일 도메인 전용) → `src/apps/{domain}/components/`

### ⚠️ Non-PDS pui(원칙 2~4) vs features — 갈림은 "비즈니스 로직 유무"다

둘 다 여러 도메인에서 쓰일 수 있어 헷갈린다. 구분선은 명확하다:

| | Non-PDS pui (원칙 2~4) | features |
|---|---|---|
| 비즈니스 로직 · 데이터 연동 | **없어야 한다** (표시·화면 변화·배치만) | **포함해도 된다** (apis·services·models를 가진다) |
| 예 | `Swiper`·`Lottie`·`InfiniteScroller` | `@features/exception`·`@features/coupon`·`@features/prizmPay` |
| 합의 | **팀 합의 필수** → 해당 시 경고 | 불필요 |

즉 **"여러 도메인에서 쓰이는데 비즈니스 로직을 품는다" → features**다. pui로 올리려다 전제의 "비즈니스 로직·데이터 연동 X" 조건에 걸리면 features가 정답이다. **"2곳 이상에서 쓰인다"는 pui 생성 조건이 아니다**(검토 트리거일 뿐).

- steering 아키텍처 불변 규칙 4: **"앱 모듈 간 순환 참조 시 `src/features/`로 추출한다."** 이것도 features 신호다.
- **`{featureName}`·`{domain}` 이름은 Figma에 없다** → Gate 1에서 확정받는다(→ [../common/gates.md](../common/gates.md)).

## 1. 최우선 — 같은 경로의 형제 컴포넌트를 먼저 Read한다 (1급 규칙)

**비즈니스 컴포넌트는 pui처럼 촘촘한 내부 정책이 없다 — 정책 자체가 "형제 따라하기"다.** 코드를 짜기 전에 **가장 먼저** 대상 경로(`src/apps/{domain}/components/` 또는 `src/features/{featureName}/components/`)의 형제 컴포넌트 1개를 반드시 Read해, **파일 구성·네이밍·import 관례·`forwardRef`/`styled` 사용 패턴·props 설계**를 그대로 따른다. 별도 정책을 발명하지 말고, 형제가 곧 기준이다.

- 형제가 여럿이면 **가장 유사한 성격**(같은 종류의 조합/리스트/카드 등)을 고른다.
- 형제가 특정 규칙(예: 이벤트 핸들러 시그니처, `getLink` 사용)을 따르면 그대로 답습한다 → 세부 코드 패턴은 [pui-generation-guide.md](pui-generation-guide.md) 참고(pui/도메인 공통 적용).

## 2. 생성 전 — pui 우선 조합

- 새 마크업을 짜기 전에 `src/pui/*`에서 쓸 수 있는 컴포넌트를 최대한 조합한다.
- pui로 표현 안 되는 비즈니스 로직/레이아웃만 비즈니스 컴포넌트로 구현한다.
- pui에 넘길 **로깅 등 UI 외 정보**는 pui에 prop을 늘리지 말고 `'data-*'`로 실어 보낸다(예: 매퍼에서 `{ name, 'data-goods-status': status }`) → **PUI 코드 컨벤션** 「디자인과 무관한 데이터는 `data-*` 어트리뷰트로 받는다」.
- **여러 도메인에서 재사용될 조짐이 보이면** → 0번 판정을 다시 태운다. 비즈니스 로직이 없으면 **pui 승격 제안**(공통 UI 경로로 전환, 팀 합의 필요), 있으면 **features 이동 제안**.

## 3. 디렉토리 / 파일 구성

```
src/apps/{domain}/components/
├── {Name}.tsx
└── index.ts            ← barrel export

src/features/{featureName}/components/
├── {Name}.tsx
└── index.ts            ← barrel export (필수)
```

- **barrel(`index.ts`)은 두 경로 모두 사실상 관례다** — 실측: `apps/*/components` **27/27**, `features/*/components` **16/17**이 보유. 형제의 export 형태(`export *` vs named)를 그대로 따른다.
- **`src/features/{featureName}/` 루트에는 `index.ts`를 만들지 않는다**(steering 명시). import는 **서브디렉토리까지 명시**한다 — 실측: `@features/exception/components`(107회)·`@features/policy/components`(11회) 형태가 관례.
  ```ts
  import { Xxx } from '@features/exception/components';   // ✅
  import { Xxx } from '@features/exception';              // ❌ 루트 barrel 금지
  ```
- 나머지 구조(`apis/`·`containers/`·`hooks/`·`models/`·`services/`·`types/` 등)는 기존 패턴을 따른다. 대표: `src/apps/goods/components/`, `src/apps/bookmark/components/`, `src/features/coupon/components/`, `src/features/exception/components/`.
- **레이어 의존 규칙은 두 경로 모두 적용된다** — `components/`는 `apis/`·`stores/`를 직접 참조하지 않는다(Pure UI, Props에만 의존) → steering `structure.md`.

(형제 Read는 **1번 규칙** 참고 — 착수 전 필수.)

## 4. 토큰 / 스타일

- 색상·간격 등은 가능한 한 `src/styles/theme.ts` 토큰 사용(하드코딩 지양). 단 공통 UI만큼 엄격히 강제하지는 않음.
- pui 컴포넌트의 props로 처리되는 스타일은 그대로 props 사용.

## 4-1. 랜딩(클릭 이동)/인터랙션

- 비즈니스 컴포넌트도 랜딩은 inline `<a>`·`<button>` 대신 **`@pui/action`의 `Action` + `getLink`**(`@utils/link`)를 쓴다. 🚦Gate 2의 랜딩 문항([../common/gates.md](../common/gates.md))에서 영역을 확정하고, 코드 패턴(앵커/버튼 분기, `link` 오버라이드+`getLink` 폴백, 앵커 중첩 금지·영역 분리)은 [guide/composition.md](guide/composition.md) **3-4**를 따른다.
- 도메인은 보통 코드/id를 이미 들고 있으므로 `getLink(UniversalLinkTypes.XXX, { code })`로 내부 생성하는 경우가 많다.

## 5. 스토리 (선택)

- Feature/Apps 스토리는 필수 아님(실측: `apps` 101건 · `features` 17건 — 있긴 하나 강제 아님). 필요하거나 사용자가 요청할 때만 `defineMeta`로 작성.
- 작성 시 `category`는 Feature/Apps 분류 사용(`@stories/menu`).

## 6. README / Changelog (선택)

- 비즈니스 컴포넌트는 pui처럼 컴포넌트별 README/changelog를 강제하지 않는다.
- 변경 이력은 커밋 메시지(`type(scope): ... (#FE-XXXX)`)로 충분. 커밋은 별도 요청 시 `git-commit` 스킬 사용.

## 7. 검증

`yarn type-check` → `yarn lint`. 통과 후 보고. (스토리북은 스토리를 만든 경우에만)
