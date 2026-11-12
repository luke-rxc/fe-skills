# 가이드 — 기존 pui 재사용·조합 (이미지·아이콘·랜딩·자식 조합)

> 부가 컨벤션 중 **"이미 있는 pui를 어떻게 쓰나"**. 로드 시점: Phase 2 코드 생성 **거의 항상**.
> 문서 관계·라우팅은 [pui-generation-guide.md](../pui-generation-guide.md).

**이 문서의 한 줄 요약: 직접 만들지 말고 이미 있는 걸 쓴다.** `<img>`·inline `<svg>`·inline `<a>`/`<button>`을 손으로 쓰는 순간 거의 항상 규칙 위반이다.

---

## 3-1. 이미지/에셋 입력 — `ImageProps`로 받는다 (필수)

Figma 노드 안의 비트맵/사진/썸네일/로고처럼 **외부에서 주입되는 일반 이미지**는 컴포넌트 내부에 하드코딩하지 말고 **`@pui/image`의 `ImageProps`로 받아** `<Image />`로 렌더한다.

- **판별 기준**
  - **일반 이미지(→ `ImageProps`)**: 사진/썸네일/배너/발급사·브랜드 로고 등 **콘텐츠성 비트맵**. Figma `get_design_context`에서 `const imgXxx = "...figma.com/api/mcp/asset/..."` 형태로 떨어지는 사진성 에셋.
    - ⚠️ Figma MCP가 내려주는 `asset/...` URL은 **7일 후 만료**되므로 컴포넌트/스토리에 박지 말 것. 반드시 prop으로 외부 주입.
  - **아이콘/벡터(→ `ImageProps` 아님)**: 화살표·플러스·체크 등 단색 UI 글리프 → **아래 3-2** 정책을 따른다. `@pui/icon` 프리셋을 import해 쓰며 inline `<svg>` 즉흥 작성은 금지.
- **Props 정의**: 이미지 슬롯은 `image: ImageProps`(또는 `thumbnail`·`logo` 등 의미 기반 이름)로 받는다. 여러 장이면 `images: ImageProps[]`.
  ```tsx
  import { Image } from '@pui/image';
  import type { ImageProps } from '@pui/image';

  export interface {Name}Props extends HTMLAttributes<HTMLDivElement> {
    /** 썸네일 이미지 */
    image: ImageProps;
  }
  // 렌더: lazy·radius 등은 컴포넌트가 토큰/정책에 맞춰 지정
  <Image {...image} lazy radius={theme.radius.r8} />
  ```
- **`<img>` 직접 사용 금지**: lazy load·blurHash/thumbHash placeholder·fade-in·error fallback이 `Image`에 내장돼 있다(WebView 성능·UX 정책). 순수 `<img>`로 대체하지 않는다.
- **스토리**에는 만료되는 Figma asset URL 대신 실제 CDN 샘플(또는 더미) `src` + `blurHash`/`placeHolderHash`를 넣는다(기존 카드 스토리 참고).

---

## 3-2. 아이콘/벡터 — `@pui/icon` 프리셋을 import한다 (필수)

Figma 노드의 아이콘(화살표·플러스·체크 등 단색 UI 글리프)은 **대부분 이미 `@pui/icon`에 프리셋으로 구현돼 있다.** inline `<svg>`를 즉흥 작성하지 말고 **반드시 기존 프리셋을 import**해 쓴다.

- **매칭 방법**: Figma 노드명(예: `ic_plus`, `ic_arrow_right`)을 `src/pui/icon/presets/`의 프리셋명(`Plus`, `ArrowRight` …)과 대조. 노드명 `ic_xxx` → 보통 PascalCase 프리셋 `Xxx`. 목록 확인은 `src/pui/icon/presets/index.ts` 또는 `src/pui/icon/components/Icon.stories.tsx`.
- **사용**:
  ```tsx
  import { Plus } from '@pui/icon';
  // size는 문자열(rem), color는 theme.color 중첩 키 문자열
  <Plus size="2.4rem" color="text.textPrimary" />
  ```
  - `size`: `'2.4rem'` 같은 문자열, `color`: `'text.textPrimary'`처럼 `theme.color` 경로 문자열, 커스텀 색은 `colorCode`.
  - 크기/색을 CSS로 제어할 땐 styled 셀렉터(`.xxx-icon`)로 감싸 `width/height/color`를 지정해도 된다(프리셋은 `currentColor` 기반).
- **대응 프리셋이 없을 때만**: 사용자에게 알리고, 새 아이콘 등록 또는 inline SVG 여부를 확인한다(임의 inline 금지).
- ⚠️ Figma `get_design_context`가 아이콘을 `asset/...` 이미지 URL로 내려도(만료 7일) 그걸 쓰지 말 것 — 단색 글리프면 `@pui/icon` 프리셋으로 치환한다.

---

## 3-4. 랜딩(클릭 이동)/인터랙션 — `@pui/action`의 `Action` (필수)

**Figma엔 랜딩(어디로 이동) 정보가 없다.** Gate 2에서 확정한 영역대로, 클릭 이동/액션은 **inline `<a>`·`<button>`을 직접 쓰지 말고 `@pui/action`의 `Action`으로** 구현한다. (`Action`: `src/pui/action/components/Action.tsx`)

- **앵커(이동)**: `<Action is="a" link={target} aria-label={...}>` — 내부 링크는 react-router `Link`, 외부/APP은 `<a href>`로 **자동분기**(`isOtherDomain`/`isApp`).
- **버튼(액션)**: `<Action onClick={...} aria-pressed={...} aria-label={...}>` — `is` 생략 시 `<button>`. `haptic` prop으로 진동 피드백.
- **링크 값은 오버라이드 + 폴백 둘 다 제공**(팀 관행):
  ```tsx
  import { getLink, getImageLink } from '@utils/link';
  import { UniversalLinkTypes } from '@constants/link/universalLink';
  // link prop 우선, 없으면 도메인 코드/id로 내부 생성
  const target = link || getLink(UniversalLinkTypes.GOODS, { goodsCode });
  ```
  `link?: string`(오버라이드)와 도메인 코드 prop(예: `goodsCode`)을 함께 받는다. `getLink`/`getImageLink`는 `@utils/link`(`getLink`는 APP/WEB 자동분기), `UniversalLinkTypes`는 `@constants/link/universalLink`. 이미지 URL은 `getImageLink(src, width)`.
- **랜딩이 옵셔널**(없을 수 있음)이면 `@pui/conditional`의 `Conditional`로 폴백:
  ```tsx
  <Conditional condition={!!target} trueExp={<Action is="a" link={target} />} falseExp={<div />}>
    {/* 카드 내용 */}
  </Conditional>
  ```
  폴백 요소는 `<div/>` 또는 `<span role="text"/>`(형제: `goodsSmall`의 `noLink`, `reviewCard`).
- **다중/중첩 랜딩 (핵심 규칙)**: 한 컴포넌트에 랜딩이 여러 개일 수 있다. **앵커(`<a>`) 안에 앵커/버튼 중첩은 HTML상 금지** — 전체+부분 랜딩이 공존하면 **전체로 감싸지 말고 영역별로 분리**한다(`brandCard`: 썸네일/정보 영역을 각각 `Conditional`+`Action`). 상태별로 목적지가 다르면 `Conditional`로 분기(onAir → live/showroom). 독립 인터랙션(follow/bookmark 등)은 전체 앵커 **밖** 형제로 배치(`liveCard`).
- **전체 press/선택이 카드 내부 전체를 덮어야 하는데 내부에 별도 버튼이 있을 때 — 오버레이 히트 + `pointer-events`(실제 실패 사례)**: "카드 전체"가 선택/press 대상이면서 내부에 별도 액션(상세보기 등)이 있으면, 선택 영역이 콘텐츠 **일부만 감싸게** 만들면 안 된다 — press 배경이 그 일부에만 적용된다(실패 사례: `SelectVoucher`의 선택 `<button>`이 상단+list만 감싸 press 회색이 **카드 전체가 아니라 상단만** 바뀜. 게다가 `<button>` 안에 `<div>`/`<ul>` block 을 넣는 것도 HTML 위반이라 hit 영역이 왜곡). 해결: **선택 히트 영역을 카드 전체를 덮는 오버레이 `Action`**(`position:absolute; inset:0; z-index:0`, 완전 리셋 + `aria-label` 필수)으로 두고, 콘텐츠 래퍼는 그 위(`z-index:1`)에 얹되 `pointer-events:none`으로 클릭을 히트 영역에 통과시킨다. 내부 별도 액션(상세보기 버튼)만 `pointer-events:auto`. 이러면 press 배경(`.select-area:active`)이 **카드 내부 전체**를 덮고, 히트/버튼이 DOM 형제라 **인터랙티브 중첩도 없다**. (전체가 표시 데이터 감싸는 단일 랜딩이면 이 오버레이 없이 위 `Conditional`+`Action`으로 통째 감싸는 게 더 단순 — 오버레이는 "전체 선택 + 내부 별도 버튼" 공존에 한정.)
- **press `transform` 트랜지션은 이징 없이 `transition: transform 0.2s;` 로 통일**: press 피드백으로 `transform`(예: `scale(0.96)` 축소)을 애니메이션할 때 트랜지션은 팀 표준인 `transition: transform 0.2s;` 를 쓴다. `200ms ease-in-out` 같은 커스텀 이징을 붙이지 말 것. (scale 수치·축소 대상 영역은 Figma Pressed 사양에 따라 그때그때 다르므로 여기서 고정하지 않는다.)
- **자식이 이미 링크/앵커를 처리하면 바깥에서 다시 감싸지 말고 자식의 `link` prop으로 넘겨라**: 재사용 자식(예: `GoodsMedium`)이 자체 `link`(+`goodsCode` 폴백)·앵커·press를 이미 갖고 있으면, 컨테이너에서 `Action`으로 한 번 더 감싸 자식을 `noLink`로 죽이지 말고 **`goods.link` 로 통과**시킨다(3-7 "props 통으로"와 결). 단 자식의 **press 배경이 컨테이너 배경과 겹쳐 어색하면 그 부분만 override로 끈다**(링크는 유지): `& ${GoodsMedium} ${Action}:active { background: transparent; }`(실제 사례: `OrderVoucherItemFnb` — 흰 surface 아이템 + 카드 회색 배경 겹침 방지). override 셀렉터는 자식 규칙보다 깊게(3-7-1 ⓓ specificity).
- 형제 인용: 전체 감싸기 `goodsCardSmall`·`contentCard`, 조건부 `goodsSmall`·`reviewCard`, 다중/중첩 분리 `liveCard`·`brandCard`, 전체 선택+내부 버튼 오버레이 `selectVoucher`, 자식 자체 링크 통과 `orderVoucher`(item_fnb).

---

## 3-7. 다른 pui 컴포넌트를 조합하면 그 Props를 "통으로" 받는다 (필수)

컴포넌트가 **다른 pui 컴포넌트를 그대로 렌더**(조합)한다면, 그 자식의 표시 데이터를 **개별 prop으로 재선언하지 말고 자식의 Props 타입을 통으로 받는 슬롯 prop**으로 노출한다.

- 🚫 **안티패턴(개별 재선언)** — 자식 prop을 하나씩 다시 나열하면, 자식이 확장될 때(예: `GoodsMedium`에 `count`·`additionalLabels`·`isRunOut` 추가)마다 부모도 따라 고쳐야 하고, 자식이 이미 검증한 prop 조합(타입·기본값·JSDoc)을 중복·유실한다.
  ```tsx
  // ❌ image·brandName·goodsName·goodsCode·count ... 를 개별로 다시 받음
  export interface VoucherProps ... { image: ImageProps; brandName: string; goodsName: string; goodsCode: string; count?: number; }
  <GoodsMedium image={image} brandName={brandName} goodsName={goodsName} goodsCode={goodsCode} type={count!=null?'count':'none'} count={count} />
  ```
- ✅ **슬롯 prop(통으로)** — 의미 기반 이름 + 자식 Props 타입. 자식 API 변화가 **부모 수정 없이** 그대로 흘러간다.
  ```tsx
  import type { GoodsMediumProps } from '@pui/goodsMedium';
  export interface VoucherProps ... {
    /** 상단 상품 영역 (GoodsMedium props 전체) */
    goods: GoodsMediumProps;
  }
  // 컨테이너가 강제하는 속성은 스프레드 뒤에 덮어써서 고정한다(grouped·noLink)
  <GoodsMedium {...goods} grouped noLink />
  ```
- **강제 속성은 스프레드 후 덮어쓴다** — 부모가 반드시 고정해야 하는 자식 prop(예: 카드 내부라서 항상 `grouped`·표시 전용이라 `noLink`)은 `{...goods}` **뒤에** 명시해 호출자가 못 바꾸게 한다.
- **파생값이 자식 데이터에 필요하면 슬롯에서 꺼내 쓴다** — 예: "상세 보기" 랜딩 폴백은 `getLink(GOODS, { goodsCode: goods.goodsCode })`.
- **여러 개면 각각 슬롯**(`goods: GoodsMediumProps`, `bookmark: BookmarkProps` …). 자식 콜백 타입도 그대로 재사용(예: `onClick?: BookmarkProps['onClick']`, PUI Convention).
- **적용 범위**: "자식을 그대로 렌더"할 때. 자식 prop 중 일부만 노출/변형해야 하는 특수 케이스는 `Pick`/`Omit`으로 좁혀 받되, 개별 원시 prop 나열보다 자식 타입 파생을 우선한다.

## 3-7-1. 조합한 자식을 오버라이드할 때 — 기본 스타일 대조 + 상태 확장은 자식 전 variant 커버 (필수)

자식 pui를 통으로 렌더(3-7)하더라도, **부모가 요구하는 시각 스펙이 자식의 기본값과 다르거나, 자식에 없는 상태(disabled/selected 등)를 부모에서 입혀야 할 때**가 있다. 이때 아래 둘을 반드시 점검한다(실제 실패 사례 2건). 핵심은 **마스터에 "보이는 것"만 맞추지 말고, 재사용하는 자식 컴포넌트의 "전체 표면"(기본 스타일값 + 모든 type/variant 요소)을 대조**하는 것이다.

**ⓐ 기본 스타일 vs 마스터 스펙 대조 (폰트 굵기·색 누락 방지)**
- 재사용 컴포넌트의 size/variant별 **기본 스타일값**(특히 fontType의 bold/regular, 색)이 마스터가 요구하는 값과 **일치하는지 대조**한다. 다르면 부모 styled에서 자식 내부 클래스를 오버라이드한다.
- 실패 사례: 마스터 "상세 보기" 텍스트는 `Small_b`(14 bold)인데, 재사용한 `ButtonGeneral size="medium"`의 기본 폰트는 `small`(14 regular) → **bold 누락**. 부모에서 `& .text-label { font: ${({ theme }) => theme.fontType.smallB}; }` 로 오버라이드해 해결.
- 점검법: 마스터 `get_design_context`가 알려주는 폰트 스타일명(`Small`/`Small_b` 등)을 재사용 컴포넌트의 해당 size css(예: `button.ts`의 `is-medium`)와 **grep 대조**한다. "재사용했으니 맞겠지"라고 넘기지 않는다.
- **Figma의 shape/variant가 재사용 컴포넌트의 공개 props로 노출 안 돼 있으면 → 신규 컴포넌트 추가 말고, 그대로 쓰되 delta(패딩·radius 등)만 부모에서 오버라이드**한다. 오버라이드 값은 임의 추정 말고 **그 컴포넌트 안에 이미 있는 대응 variant css를 grep해 정확히 미러링**한다(실제 사례: 마스터 `Button_Squircle` = medium 좌우 `1.6rem`인데 `ButtonGeneral`은 `shape?: never`라 squircle 미노출 → `button.ts` 의 `is-shape-squircle.is-medium` 값 `calc(1.6rem - var(--button-border-width))` 을 그대로 미러링해 `& ${ButtonGeneral}.is-medium { padding: 0 calc(1.6rem - var(--button-border-width)); }` 로 오버라이드. 기본 `is-medium` 은 1.2rem). border-width 보정 같은 자식 내부 관용(`var(--...)`)도 함께 미러링한다.

**ⓑ 상태 오버라이드는 자식의 전 variant를 커버 (케이스 누락 방지)**
- 자식에 없는 상태(예: `GoodsMedium`엔 disabled 없음)를 부모 styled 하위 셀렉터로 구현할 때, **마스터에 보이는 요소만 처리하면 안 된다.** 마스터 디자인은 특정 케이스(예: brand+title)만 보여주지만, 자식은 여러 type/variant를 노출하므로 **자식이 렌더하는 색 있는 요소 전체를 grep해 빠짐없이 커버**한다.
- 실패 사례: `SelectVoucher` disabled에서 `GoodsMedium`의 `.brand`·`.name`만 회색 처리 → `type='price'/'optionName'`의 `.price`·`.discount`(sale 색)·`.option`·`.divider`가 원색으로 남음. 자식 styled를 grep해 색 요소 전부를 `textDisabled` 로 오버라이드해 해결.
- 점검법: 자식 컴포넌트 파일에서 `color:`·`background:`가 걸린 클래스를 grep → 부모 오버라이드에 그 클래스를 **전부** 포함한다.
- ⚠️ **상태 색을 다루는 CSS 3원칙(상속 안 됨 · base 조건부 · specificity 깊이 맞추기)은 `src/pui` 전역 컨벤션으로 승격됐다** → `.claude/rules/pui-code-convention.md` "상태에 따라 색을 바꿀 때"(`src/pui` 작업 시 자동 로드). 여기서 재서술하지 않는다.
  - 실측 근거: 자식 `GoodsMedium`이 `.name`을 `.info .text .name`(클래스 4개)으로 잡는데 부모가 `${GoodsMedium} .name`(3개)으로 덮어 **disabled 회색이 안 먹었다**. / `SelectVoucher` 혜택 List는 하단 disabled 블록에 오버라이드를 뒀다가 base와 셀렉터가 겹쳐 `no-duplicate-selectors` 경고 → base `color`를 삼항으로 바꿔 해결.
  - **f2c 고유 부분은 아래 ⓑ 본문**이다 — 자식이 렌더하는 색 요소를 **전부 grep해 빠짐없이 커버**하는 것. 3원칙을 지켜도 대상을 빠뜨리면 그 variant만 원색으로 남는다.
- ⚠️ **오버라이드 상태는 자식 variant별 스토리로 검증**(→ [structure.md](structure.md) 4번 State별 스토리): 추가한 상태를 자식의 각 type/variant마다 스토리로 만들어 육안 확인한다(예: `Disabled가격형`·`Disabled옵션형`·`Disabled수량형`).

**ⓒ 상태를 입히면 그 상태의 "인터랙션 피드백"도 함께 꺼라 (색만 바꾸면 모순)**
- 비활성(disabled) 등 상태를 **색/오버레이만** 바꾸고 `:active`/`:hover`/press 피드백을 그대로 두면, **disabled 인데 눌러서 press 회색이 뜨는** 모순이 생긴다(실제 실패 사례). 상태를 시각화할 땐 그 상태에서 무의미한 인터랙션 피드백도 반드시 차단한다.
- 해결: 피드백 셀렉터에 상태 가드를 건다 — `&:not(:disabled):active { … }`. (표준상 `disabled` 버튼은 `:active`가 안 걸리지만, `@pui/action`의 `Action` 구현·브라우저 차이로 새는 경우가 있어 명시적으로 가드하는 게 안전.) hover 피드백도 동일.

**ⓓ 마스터의 특정 "상태 variant"를 그 상태의 유일한 형태로 단정 금지 — 상태 축 × 콘텐츠 축은 독립**
- 마스터가 보여주는 상태 variant(예: `disabled` 카드가 마침 혜택 List 없는 144px 형태)를 보고 **`disabled → List 숨김`처럼 상태 조건과 콘텐츠 조건을 얽어매면** 다른 조합에서 깨진다(실제 실패 사례: "혜택 있는 disabled"에서 List가 사라짐 → 로직을 `showList = benefits.length > 0`로 되돌리고 disabled 는 List 를 회색 처리만 하도록 분리).
- 원칙: **상태(default/selected/disabled)와 콘텐츠(혜택 유무·type 등)는 별개 축**으로 다룬다. 마스터의 한 variant는 "그 상태 × 그 콘텐츠"의 한 스냅샷일 뿐이니, 표시 여부는 콘텐츠 조건으로, 상태는 스타일(회색·오버레이·피드백 차단)로 각각 독립 처리한다. 두 축의 조합(혜택 있는 disabled 등)을 스토리로 검증한다.

**ⓔ 상태의 "시각 적용 범위"를 임의 확대 금지 — 마스터 상태 variant에서 정확히 어느 영역이 바뀌는지 읽어라**
- `disabled`·`selected` 같은 상태가 **카드 전체/모든 하위 요소에 적용된다고 넘겨짚지 말 것.** 특정 하위 영역에만 적용되는 경우가 많다(실제 실패 사례: `Order_Voucher` 의 `disabled`(만료·취소)는 **상단 헤더 영역만** dimmed — 타이틀·서브 회색 + '사용' 버튼 disabled — 이고 **캐러셀 아이템은 풀컬러 정상**인데, 캐러셀 전체에 미디어 오버레이를 씌워 틀림).
- 점검법: 마스터의 그 상태 variant(그리고 있으면 Doc)를 `get_screenshot` 으로 확대해 **어느 서브 영역의 색/투명도가 바뀌고 어느 영역이 그대로인지**를 눈으로 대조한 뒤, 딱 그 영역만 처리한다. "상태니까 다 흐리게"는 금물. 범위 확정이 애매하면 사용자에게 확인한다.

## 3-7-2. 컨테이너가 자식 목록을 렌더할 때 — 합성 방식 · 식별자 · 재사용 자식 API 확장 (필수)

컨테이너가 **여러 자식(서브 아이템)을 반복 렌더**하는 복합 컴포넌트에서, 세 가지를 판단한다. Figma는 "정적 스냅샷"만 주므로 아래는 **설계 결정**이며, 애매하면 임의로 정하지 말고 형제 관행 확인 후 **사용자에게 확인(게이트)** 한다.

**ⓐ 판별 축(`type` 등)이 있으면 `children` 합성보다 "데이터 prop 내부 렌더"**
- 루트에 어떤 자식을 쓸지 가르는 **판별 prop**(예: `type: 'stay'|'dining'`)이 이미 있으면, `children: ReactNode` 로 합성을 열기보다 **데이터 배열(`items`)을 받아 내부에서 `type` 별 대응 컴포넌트를 렌더**한다. 호출자가 타입-아이템을 짝맞출 필요가 없어지고(타입 안전), API가 데이터-주도로 단순해진다.
- discriminated union으로 `type` ↔ `items` 를 묶는다:
  ```ts
  export type XProps = BaseProps & (
    | { type?: 'stay';   items: ItemStayProps[] }
    | { type:  'dining'; items: ItemFnbProps[]  }
  );
  // 렌더: type==='dining' ? items.map(ItemFnb) : items.map(ItemStay)
  //   구조분해로 discriminant 가 끊기면 map 대상만 좁은 타입으로 캐스팅해 잇는다.
  ```
- 자식 아이템 컴포넌트는 **여전히 별도 export**해 재사용·스토리를 연다. "데이터 prop 렌더"와 "서브 분리"는 양립한다.
- 반대로 **판별 축이 없거나 자식 종류가 열려 있으면(임의 조합)** `children` 합성을 유지한다. 규칙은 "type이 있으면 데이터 prop 을 우선 검토"이지 "children 금지"가 아니다.

**ⓑ 도메인 식별용 고유 id/코드 prop — 형제 관행 확인 후, 애매하면 사용자에게 확인**
- 반복되는 아이템 **그리고 그 아이템을 담는 컨테이너 컴포넌트 자체**도, 도메인이 인스턴스를 구분(선택·추적·이벤트 매칭)하려면 **고유 식별자 prop**이 필요할 수 있다. 내부 렌더 `key` 안정화에도 쓰인다.
- 단 **항상 추가/항상 생략이 정답이 아니다** — 불필요한 경우도, 형제마다 이름이 다른 경우(`id`·`code`·`goodsCode`·`goodsId` 등)도 있다.
- 절차: ① **형제/도메인 컴포넌트 관행을 먼저 grep**해 식별자 prop 이름·유무를 확인(예: `GoodsMedium` 은 `goodsCode`). ② 관행이 뚜렷하면 그 이름을 따른다. ③ **뚜렷하지 않거나 불필요해 보이면 임의 결정 금지 → `AskUserQuestion` 으로 "고유 식별자 prop 필요 여부·이름"을 확인**(랜딩 게이트와 동일 원칙).
- 추가 시: 아이템/컨테이너가 `HTMLAttributes` 를 확장하면 DOM `id` 로 자연히 실리므로 `id?: string` 을 JSDoc 으로 노출하고, 목록은 `key={item.id ?? index}` 로 쓴다. 도메인 코드 성격이면 `goodsCode` 처럼 의미 이름을 별도로 둔다.

**ⓒ 재사용 자식이 마스터가 요구하는 콘텐츠 variant를 못 담으면 → 억지 매핑 말고 공유 자식 API를 확장**
- 자식 pui를 통으로 렌더(3-7)하는데, 마스터가 요구하는 표기가 자식의 기존 type/prop 으로 **표현 불가**할 때가 있다(실제 사례: `Order_Voucher` F&B 아이템의 상태 문구 `사용가능`·`이용완료 10. 9(월)` 를 `GoodsMedium` 의 `count`(`N장`) 로는 못 담음).
- 🚫 억지 매핑(뜻 안 맞는 기존 type 재활용)·부모에서 자식 위에 덧그리기(중복 렌더) 금지. ✅ **공유 자식 컴포넌트에 알맞은 type/prop 을 추가**한다(예: `GoodsMedium` 에 `type='label'` + `label?: string`). 표기 슬롯(예: 가격 슬롯)을 재사용해 스타일 일관성을 지킨다.
- **좁은 표기 타입을 난립시키지 말고 범용 텍스트 타입으로 통합** — 같은 슬롯에 문자열만 다르게 찍는 케이스(수량 `2장`·상태 `사용가능` 등)는 `count: number` 처럼 포맷별 타입을 따로 두기보다 **`label: string` 하나로 통합하고 문자열 조립은 호출자에게 맡긴다**(실제 사례: `GoodsMedium` `count`(`N장`) → `label` 로 통합). 통합 시 기존 사용처(스토리 포함)를 grep해 함께 마이그레이션하고 Changelog에 남긴다.
- 단 **공유 컴포넌트 변경은 파급이 있으니**: 형제 사용처를 grep해 회귀 없음을 확인하고, 그 컴포넌트의 **README Changelog·스토리·타입 JSDoc 을 함께 갱신**한다. 변경 범위가 크면 사용자에게 고지한다.
