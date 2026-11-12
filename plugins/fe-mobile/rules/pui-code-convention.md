---
paths:
  - "src/pui/**/*"
---

# PUI(src/pui) 코드 컨벤션 — 항상 지켜야 할 핵심 규칙

> **이 문서가 PUI 규칙의 단일 기준이다.** Notion 원본은 배경·근거를 소유하고, 여기엔 코드를 쓸 때 지켜야 할 규칙만 옮긴다. 원본이 동기화일 이후 바뀌었으면 이 문서를 수동 갱신한다.
>
> | 원본 (Notion) | 담당 절 | 마지막 동기화 |
> |---|---|---|
> | [PUI Overview](https://app.notion.com/p/rxc/PUI-Overview-3be14ad98d5680e7a2fbf65e3a8bff79) | 개요 | 2026-09-28 |
> | [PUI Principles](https://app.notion.com/p/rxc/PUI-Principles-3be14ad98d5680e498eded57e5bc60cd) | 생성 원칙 | 2026-09-28 |
> | [피그마 마스터 컴포넌트 배치 정책](https://app.notion.com/p/rxc/3e414ad98d56809b8551ce576ec0df9d) | 배치(스캐폴딩) | 2026-09-28 |
> | [PUI Semantics](https://app.notion.com/p/rxc/PUI-Semantics-3be14ad98d5680c4abd9e5da4a36931f) | 시맨틱 | 2026-09-28 |
> | [PUI Convention DB](https://www.notion.so/rxc/PUI-Convention-a8da9aa42c4d434297833fd59a5aa540) (활성 규칙) | 코드 규칙 | 2026-10-01 |
>
> **적용 범위** — 생성 원칙·배치·시맨틱은 **신규 컴포넌트 기준**이다. 기존 컴포넌트를 이 기준으로 옮기거나 고치는 일은 팀 단위 마이그레이션으로 따로 진행하므로, 기존 코드를 수정할 때 위치·구조를 임의로 바꾸지 않는다. 코드 규칙은 `src/pui` 코드에 항상 적용된다.
>
> 전사 일반 컨벤션은 `.kiro/steering/code-conventions.md`.

## 개요

PUI는 PDS(Prizm Design System) 가이드라인에 기반한 React UI 컴포넌트 집합이다. 서비스 전반의 UI 일관성·재사용성이 목적이다.

- 컴포넌트마다 `README.md`를 두고, `src/pui/README.md`가 전체 인덱스다 — 신규 추가 시 둘 다 갱신한다.
- 사용법·props는 각 README와 Storybook(https://storybook.prizm.co.kr/)을 참고한다.

## 생성 원칙 — 무엇을 PUI로 만드나

PUI는 **화면에 보이는 것과 그 안의 동작**만 책임진다. 무엇을 보여줄지는 도메인이 정한다.

**전제 (모든 원칙 공통)** — 하나라도 어기면 PUI가 아니다(→ `src/features` 또는 `src/apps`):
- 렌더 트리 안에 존재한다. 화면 결과에 관여하지 않는 공통 모듈(예: 메타태그 관리)은 대상이 아니다.
- 상호작용은 컴포넌트 내부 동작(hover·focus·animation·sliding 등)으로 한정한다.
- 비즈니스 로직에 종속되지 않고, **데이터 연동을 포함하지 않는다.**

**"2회 이상 쓰인다"는 검토 트리거일 뿐 생성 조건이 아니다.** 아래 원칙 중 하나를 만족해야 생성한다.

| 원칙 | 조건 | 합의 |
|---|---|---|
| **1. PDS 정의** | PDS의 Figma 마스터 컴포넌트(F.M.C.). 마스터 **내부 요소**도 여러 마스터에서 디자인과 UI/UX 처리가 **완전히 같으면** 분리 가능(예: 카드 안 북마크). 디자인이 같아도 동작·상태 처리가 다르면 별개 | 불필요 |
| **2. Atomic** | ① 더 쪼갤 수 없다(다른 PUI를 조합하지 않음) ② 책임이 '표시' 하나이고 도메인 의미가 없다 ③ children이 아니라 그릴 대상 하나를 값으로 받는다. lazy load·로딩/에러 폴백·placeholder는 포함 가능. 현재: `image`·`video`·`icon`·`svg`·`lottie` (타이포는 테마로 제어하므로 제외) | **팀 합의 필수** |
| **3. Behavior** | 화면이 **어떻게 변하는지**(전환·애니메이션·타이밍·내부 계산)를 스스로 관리한다. 관리하는 값은 화면 표현에 한정 — 서버 요청·도메인 가공은 하지 않고 이벤트 콜백으로 알린다(예: `infiniteScroller`는 끝 도달만 알림). 예: `countDown`·`collapse`·`swiper`·`chips`·`modal`·`toast`·`floating` | **팀 합의 필수** |
| **4. Structure** | 받은 내용을 **어떤 태그로·어디에·어떤 간격으로** 놓을지만 정한다. ① 보여줄 내용을 스스로 갖지 않는다 ② 무엇을 받았는지 모른다(도메인 전용 값 없음) ③ 변하는 과정은 다루지 않는다 ④ 렌더 트리 안에서 동작한다. 배치용 간격·여백만 갖고 아이템의 생김새에는 관여하지 않는다. 예: `conditional`·`list`·`portal`·`action`·`gridList`·`gridCarousel` | **팀 합의 필수** |

## 배치 (스캐폴딩)

신규 컴포넌트는 **Figma 카테고리 기준 폴더** 아래에 둔다.

```
src/pui/
├── system/ · button/ · navigation/ · dataDisplay/ · dataDisplayCard/ · dataEntry/ · feedback/   ← PDS 카테고리
├── graphics/     ← icon · lottie 등
├── nonPds/       ← PDS에 없는(원칙 2~4) 공통 컴포넌트
└── _utils/       ← 내부 관리용
```

- **카테고리 폴더 = 스토리 category** — `defineMeta`의 `category`(`src/stories/menu.ts`)와 1:1로 대응한다. 하나를 정하면 다른 하나가 정해진다.

  | 스토리 category | 폴더 |
  |---|---|
  | `StoriesMenu.PDS.System` · `Button` · `Navigation` · `DataEntry` · `DataDisplay` · `Feedback` | `system/` · `button/` · `navigation/` · `dataEntry/` · `dataDisplay/` · `feedback/` |
  | `StoriesMenu.PDS.DataDisplayCardType` | `dataDisplayCard/` |
  | `StoriesMenu.NonPDS` | `nonPds/` |
  | `StoriesMenu.Graphic` | `graphics/` |

- **마스터 폴더** — 카테고리 폴더 안에 컴포넌트마다 폴더를 만든다. 폴더명은 **camelCase**: `dataDisplay/titleLarge/`. Non-PDS도 같은 방식: `nonPds/action/`.
- 마스터 폴더 구성: `components/` · `index.ts` · `README.md`가 기본이고, 필요하면 `hooks/` · `types/` · `constants/` · `utils/` · `models/` 등 레이어 폴더를 추가한다(형제 컴포넌트 관례를 따른다).
- **서브 컴포넌트** — Figma에서 `Order_Voucher / item_stay`처럼 **슬래시로 나뉜 이름**은 마스터의 서브다.
  - 별도 폴더를 만들지 않고 **마스터 폴더의 `components/`에 함께 둔다.**
  - 파일명은 마스터명 + 서브명을 PascalCase로 잇는다: `OrderVoucherItemStay.tsx`.
  - 서브도 `index.ts`에서 export한다.
  - 스토리는 마스터 스토리에 함께 두거나 서브별 파일로 나눠도 된다.
- 슬래시 없이 독립 정의된 마스터와 Non-PDS는 각자 마스터 폴더를 만든다.
- ⚠️ `button/` 루트의 기존 Button은 이관 전 상태다(추후 `button/button/`으로 이관 예정). 신규 버튼류는 `button/<master>/`에 둔다.

## 시맨틱 (접근성 · SEO)

**PUI는 시맨틱을 표현할 prop을 제공하고, 실제 값은 도메인이 정한다.** 같은 컴포넌트라도 페이지 맥락에 따라 필요한 구조가 다르기 때문이다.

1. **클릭·입력 요소는 용도에 맞는 태그로** — 클릭은 `<button>`, 이동은 `<a>`, 입력은 `<input>`. 태그를 못 바꾸면 `role="button"` + `tabIndex={0}` + `onKeyDown`(Enter/Space)으로 복원한다. 로깅·이벤트 위임용 관측 요소에는 `role`·`tabIndex`를 붙이지 않는다.
2. **제목·구조는 태그로** — 제목 컴포넌트는 헤딩 태그를 지정할 prop(`titleIs?: 'h1'~'h6' | 'div'`)을 제공한다. 레벨은 PUI가 정하지 않는다.
3. **대체 텍스트** — 이미지가 사라졌을 때 정보도 사라지면 의미 있는 이미지다.

   | | 이미지 | 아이콘 |
   |---|---|---|
   | 의미 있음 | `alt="의미"` | `role="img"` + `aria-label="의미"` |
   | 장식 | `alt=""` | `aria-hidden="true"` |

   상위 요소에 이미 이름이 있거나 같은 내용이 텍스트로 있으면 비운다(이중 낭독 방지).
4. **버튼·링크에 이름을** — 텍스트 없는 버튼·링크에는 `aria-label`(또는 `aria-labelledby`)을 준다.
   - 이름에 역할을 넣지 않는다("공유 버튼" X → "공유").
   - 같은 버튼이 여러 개면 맥락을 넣는다(`${label} 삭제`).
   - 토글은 이름을 '대상'으로 하고 상태는 `aria-pressed`로 표현한다(이름에 동작을 넣지 않는다).
   - 카드 전체가 링크면 내부 텍스트를 요약한 이름을 링크에 준다.
5. **종류와 상태를 전달** — 역할(`role="switch"`·`tab` 등)과 상태(`aria-checked`·`aria-pressed`·`aria-selected`)를 함께 노출한다. 색·위치로만 상태를 표현하지 않는다. 동적 알림은 `role="status"` + `aria-live="polite"`, 에러성은 `role="alert"` + `aria-live="assertive"`.

## 코드 규칙 (Convention DB)

### 컴포넌트 / Ref

- ForwardRef를 적용한다.
- 컴포넌트명은 PascalCase, 의미 기반(형제 컴포넌트 관례 준수).

### Props

| 규칙                                                              | 예                                                      |
| ----------------------------------------------------------------- | ------------------------------------------------------- |
| HTML Element 속성을 상속(충돌 시 `Omit`)                          | `ButtonProps extends HTMLAttributes<HTMLButtonElement>` |
| 타입명 = 컴포넌트명 + `Props`                                     | `ButtonProps`                                           |
| 각 prop에 JSDoc(description) 추가                                 | —                                                       |
| 선언 순서: 데이터/표시 props 먼저 → `on*` 핸들러는 맨 아래로 분리 | 아래 코드 참고                                          |
| Boolean prop에 `is` 접두사 금지                                   | `disabled` (O) / `isDisabled` (X)                       |
| 이벤트 핸들러 1번째 인자는 이벤트 객체                            | —                                                       |
| 이벤트 로깅 전용 props·인자 추가 금지                             | —                                                       |
| 디자인과 무관한 데이터(로깅 등)는 `data-*`로 받는다               | `extends HTMLAttributes<…>, DataAttributes` (아래 참고) |
| 내부에서 가공한 참조/디스플레이 데이터는 오버라이드용 props 제공  | —                                                       |

```ts
export interface CardContentProps extends HTMLAttributes<HTMLSpanElement> {
  size?: CardContentSize; // 데이터/표시 props 먼저
  image: ImageProps;
  title: string;
  disabled?: boolean;
  onClickLink?: (event, item) => void; // on* 핸들러는 맨 아래로 분리
  onClickBookmark?: BookmarkProps["onClick"];
}
```

#### 디자인과 무관한 데이터는 `data-*` 어트리뷰트로 받는다

도메인 필드를 props에 추가하면 `...rest`로 DOM에 새어 나가 `React does not recognize the prop` 경고가 난다. `DataAttributes`(`@pui/_types`)를 확장해 `data-*`로 받고, 루트 요소에 `{...rest}`를 스프레드한다 — 그러면 DOM에도 실리고, 콜백 2번째 인자(`props`, 아래 규칙)로 그대로 꺼내 쓸 수 있다.

```tsx
// 👎 Bad — ui에 필요 없는 정보를 props로 정의
interface GoodsSmallProps extends HTMLAttributes<HTMLDivElement> {
  name: string;
  goodsStatus?: string;
}

// 👍 Good — data-* 로 받는다
import type { DataAttributes } from '@pui/_types';

interface GoodsSmallProps extends HTMLAttributes<HTMLDivElement>, DataAttributes {
  name: string;
}

// 도메인 - 매퍼: 로깅 등 UI 외 정보는 data-* 로 실어 보낸다
{ name, 'data-goods-status': status }
```

#### 이벤트 핸들러 2번째 인자

**기본: props 전체를 그대로 넘긴다.** 파라미터에서 바로 구조분해하지 말고 `props`로 받아 내부에서 분해해야 원본 참조가 유지된다.

```ts
forwardRef((props, ref) => {
  const { onClickLink } = props;
  // ...
  onClickLink?.(e, props); // 원본 props 객체를 통째로
});
// 타입: (event, item: {Name}Props) => void
```

**예외 — 식별 필드 묶음:** 넘길 데이터가 소수 식별자뿐이거나 props 전체 노출이 부적절할 때만 `onClick?.(e, { id, code, ... })` 형태를 쓴다(기본이 아님).

| 케이스          | 컴포넌트                     | 시그니처 → 호출                                                                         |
| --------------- | ---------------------------- | --------------------------------------------------------------------------------------- |
| 기본            | `liveCard`                   | `onClickLink?: (event, item: LiveCardProps) => void` → `onClickLink?.(e, props)`        |
| 예외(식별 필드) | `contentListItem`            | `onClick?: (event, info) => void` → `onClick?.(e, { id, code, contentType, ... })`      |
| 재노출          | `@pui/bookmark`의 `Bookmark` | 기존 콜백 타입 재사용 — `BookmarkProps['onClick']` (`(event, { type, code, isAdded })`) |

### 스타일 (styled-components)

- styled 컴포넌트는 변수로 선언한다(익명함수 금지).
- color 값은 `@hooks/useTheme`가 아닌 styled 내부 `${({ theme }) => ...}`로 접근한다.
- CSS 선택자에 태그명을 쓰지 않는다(클래스/컴포넌트 셀렉터 사용).
- 스타일 오버라이딩은 컴포넌트명을 블록 단위로 선언해서 처리한다.

#### 상태에 따라 색을 바꿀 때 (disabled·selected 등)

세 규칙 모두 **위반해도 에러가 나지 않고 화면만 조용히 틀어진다** — 정적 검사로는 못 잡는다.

1. **색은 "그 색을 선언한 요소"에서 바꾼다 — 부모에 걸어도 상속되지 않는다.**
   자식이 `color`를 명시 선언했으면, 부모에 상태 색을 걸어도 **specificity 이전에 "상속 vs 명시 선언"** 문제로 항상 진다.
2. **자기 마크업이면 별도 오버라이드 규칙 대신 base 선언을 조건부로 만든다.**
   base가 이미 그 요소를 잡고 있는데 상태 블록에서 다시 잡으면 stylelint `no-duplicate-selectors`가 뜬다. 삼항으로 파생하면 중복 규칙이 0이 된다.
   ```tsx
   & .benefit {
     color: ${({ theme, disabled }) => (disabled ? theme.color.text.textDisabled : theme.color.text.textPrimary)};
   }
   ```
   (styled 인터폴레이션은 컴포넌트 prop을 모두 받으므로 base 어디서든 분기할 수 있다.)
3. **다른 컴포넌트를 오버라이드할 땐 그쪽 셀렉터 깊이(specificity)를 맞추거나 더 깊게 쓴다.**
   대상이 `.info .text .name`(클래스 4개)으로 잡은 것을 `${Child} .name`(3개)으로 덮으면 **아무 에러 없이 적용만 안 된다.** 대상 파일에서 그 규칙의 중첩 경로를 확인하고 그 이상으로 잡는다(부스트가 필요하면 `&&`).

> 상태를 색으로만 바꾸고 `:active`/`:hover` 피드백을 두면 **disabled인데 눌러서 press 회색이 뜨는** 모순이 생긴다. `&:not(:disabled):active`처럼 상태 가드를 함께 건다.
>

### import / export

- import는 root 레벨 공통 모듈만 한다.
- export는 index.ts에서 필요한 모듈만 명시적으로 한다(`export *` 지양). ※ 현 코드베이스는 순환참조로 `export *` 사용 중 — 형제 패턴 우선.

### 기타

- 배열의 key 값으로 index를 사용하지 않는다.
- 신규/비표준 DOM 속성(리소스 힌트 `fetchpriority`·`decoding` 등)은 **소문자**로 넘긴다. `@types/react`에 camelCase(`fetchPriority`) 타입이 있어 tsc는 통과하지만, 현 react-dom은 런타임에서 인식하지 못해 `React does not recognize the prop` 경고 + DOM 미반영이 된다. JSX에는 소문자로 스프레드하거나(`{...(cond && { fetchpriority: 'high' })}`), ref + `setAttribute('fetchpriority', ...)`로 붙인다.
