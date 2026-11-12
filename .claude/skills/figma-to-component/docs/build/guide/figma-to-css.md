# 가이드 — Figma 값 → 코드 값 변환 (색·수치·치수·마스크)

> 부가 컨벤션 중 **"Figma의 숫자와 색을 코드로 어떻게 옮기나"**. 로드 시점: Phase 2 코드 생성 **항상**.
> 문서 관계·라우팅은 [pui-generation-guide.md](../pui-generation-guide.md).

**이 문서의 한 줄 요약: Figma 절대값을 그대로 박지 않는다.** 색은 토큰 이름으로, 수치는 형제 관행값으로, 폭은 반응형으로 변환한다. 정적 검사(type/lint)는 이 위반을 **전부 통과**시키므로 화면만 조용히 틀어진다.

---

## ⚠️ 변환의 입력은 codegen이다 — 설계 명세가 아니다 (강제)

> **실측 실패**: Phase 1에서 추출한 "설계 명세(텍스트 요약)"만으로 코드를 생성하면 실제 디자인과 심각하게 어긋난다(variant별 케이스 전혀 미구현, 레이아웃 구조 불일치, DOM 계층 오류). 거의 100% 구현을 달성한 런의 핵심 차이는 **`get_design_context`의 codegen을 직접 변환 기반으로 삼았다**는 점이다.

1. **`get_design_context`가 반환한 참조 코드(Tailwind/React)를 반드시 기반으로 삼는다.** 명세 텍스트만으로 "추정"해 작성하지 않는다.
2. **variant별 codegen을 모두 확보한다** — 마스터 세트의 각 variant 조합에서 나온 참조 코드를 수집해 styled-components + theme 토큰으로 **1:1 변환**한다.
3. **변환 순서**:
   ```
   Figma codegen (Tailwind/React)
   → DOM 구조 파악 (어떤 요소가 어떤 관계로 중첩되는지)
   → Tailwind 클래스 → theme 토큰 매핑 (아래 3-0·3-3)
   → styled-components 작성 (형제 컴포넌트 패턴 참조)
   → variant 조건 분기 적용 (classnames / props 기반)
   ```
4. **설계 노트와 codegen은 역할이 다르다** — 설계 노트는 **설계 판단용 정리**(행동규칙·수용기준)이고, 코드 작성의 근거는 **codegen 원본**이다. 혼동하지 않는다.

**서브에이전트에 위임할 때도 codegen을 첨부한다** — 명세만 전달하면 서브가 구조를 추정해 오류가 증폭된다. 최소 첨부: 대표 variant 2~3개 codegen(DOM+CSS) · variant 간 **차이점** 명시 · 토큰 매핑 표 · 형제 컴포넌트 코드. **codegen 없이 "명세만"으로 위임하는 것은 규칙 위반이다.**

---

## 3. 토큰 (theme.ts)

**토큰 하드코딩 절대 금지** — 모두 `${({ theme }) => theme.x}`로 접근:
- 색상 `theme.color.*` (예: `theme.color.brand.tint`, `theme.color.text.textPrimary`, `theme.color.background.surface`, `theme.color.states.pressedPrimary`)
- 간격 `theme.spacing.s4|s8|s12|s16|s24`, 반경 `theme.radius.r8`
- 타이포 `theme.fontType.small|medium|mediumB`
- 믹스인 `theme.mixin.center()`, `theme.mixin.ellipsis()`, `theme.mixin.absolute({ t, r, b, l })`, `theme.mixin.safeAreaValue('bottom')`

반복 수치는 컴포넌트 스코프 **CSS 변수**(`--{name}-x`)로 두고 셀렉터에서 재사용.

### 3-0. Figma 색상 변수 → theme 토큰 매핑 (하드코딩 절대 금지, 강제)

🚫 **`#fff`·`#ffffff`·`rgba(...)` 같은 hex/리터럴 색을 코드에 절대 박지 않는다.** Figma의 색은 거의 항상 **이름 있는 변수(토큰)** 에 바인딩돼 있고, `get_variable_defs`는 **그 토큰 이름**(예: `Color/Neutral/fixed/white_light`)과 해석값(`#ffffff`)을 같이 준다. **해석된 hex를 그대로 쓰지 말고, 토큰 "이름"을 `theme.ts`의 토큰으로 매핑**한다.

- **확인 방법**: `get_variable_defs` 결과 또는 Figma 변수 패널의 **"Text colors / Fill" 토큰 이름**을 본다. 이름이 `.../fixed/...`면 **다크모드에서도 고정되는 NeutralFixed 토큰**이다(특히 미디어 위 텍스트·아이콘에서 흔함). 해석값이 `#ffffff`라고 `#fff`를 박으면 다크모드·테마 변경에 깨진다.
- **대표 매핑(`src/styles/theme.ts`)**:
  | Figma 변수 이름 | theme 토큰 |
  |---|---|
  | `Color/Neutral/fixed/white_light` | `theme.color.whiteLight` |
  | `Color/Neutral/white` | `theme.color.white` |
  | `Color/Text/black (text_primary)` | `theme.color.text.textPrimary` |
  | `Color/Text/gray50 (text_tertiary)` | `theme.color.text.textTertiary` |
  | `Color/Text/gray20 (text_disabled)` | `theme.color.text.textDisabled` |
  | `Color/Background/gray_bg (bg)` | `theme.color.background.bg` |
  | `Color/States/.../disabled_media` | `theme.color.states.disabledMedia` |
  매핑이 불명확하면 **임의값 금지 → 사용자 확인**. (필요하면 `grep`으로 `src/styles/theme.ts`에서 토큰명을 찾는다.)
- **prop으로 색을 받는 자식 컴포넌트도 hex 금지.** 예: `@pui/countDown`의 `textColor`에 `"#fff"`를 넘기지 말고, **부모 styled에서 `${CountDown}` 블록으로 토큰 색을 오버라이드**한다(컴포넌트명 블록 오버라이딩 = PUI Convention):
  ```tsx
  // ❌ <CountDown textColor="#fff" />
  // ✅ prop 생략 + 부모 styled에서 토큰으로 오버라이드
  ${CountDown}.thumbnail-countdown {
    color: ${({ theme }) => theme.color.whiteLight};
  }
  ```
- ⚠️ **기존 컴포넌트가 `#ffffff` 등을 하드코딩하고 있어도 그대로 따라하지 말 것**(예: `contentCard`의 `textColor="#ffffff"`는 알려진 안티패턴). 신규/리디자인은 토큰으로 만든다.

---

## 3-3. mixin/토큰 인자 수치는 추정 금지 → `grep`으로 도출 (필수)

폰트/말줄임/고정높이 같은 **수치는 Figma 값이나 감으로 임의 입력하지 말고, 기존 컴포넌트의 관행값을 `grep`으로 확인해 맞춘다.** (수치가 어긋나면 정적 검사(type/lint)는 통과해도 화면이 디자인과 미묘하게 틀어진다.)

- **폰트 크기·굵기 → `theme.fontType` 매핑표로 확정(감으로 고르지 않는다, 필수)**: Figma 텍스트의 `font-size(px)`·굵기를 아래 표로 토큰에 매핑한다(`src/styles/theme.ts`). 굵기 Bold는 `*B` 변형을 쓴다. 표에 없는 크기(예: 13·16·17px)면 임의 근사 금지 → 형제 `grep` + 불명확 시 사용자 확인.

  | Figma font-size | Regular 토큰 | Bold 토큰 |
  |---|---|---|
  | 10px | `theme.fontType.micro` | `theme.fontType.microB` |
  | 12px | `theme.fontType.mini` | `theme.fontType.miniB` |
  | 14px | `theme.fontType.small` | `theme.fontType.smallB` |
  | 15px | `theme.fontType.medium` | `theme.fontType.mediumB` |
  | 18px | `theme.fontType.large` | `theme.fontType.largeB` |
  | 20px | `theme.fontType.title2` | `theme.fontType.title2B` |
  | 24px | `theme.fontType.title` | `theme.fontType.titleB` |
  | 28px | `theme.fontType.headline2` | `theme.fontType.headline2B` |
  | 32px | `theme.fontType.headline` | `theme.fontType.headlineB` |

- **`fontType`에는 line-height가 없다**: `theme.fontType.medium` 등은 CSS `font` 단축속성(`normal 400 1.5rem family`)이라 **line-height 슬롯이 비어 있다**(맨 앞 `normal`은 `font-style`). 즉 줄간격은 정의하지 않고 브라우저 `normal`에 위임한다.
- **다중행 말줄임은 `fontType` + `multilineEllipsis`를 함께 쓴다(정석, 충돌 아님)**: `font:`로 폰트/크기/굵기를 주고, **줄간격은 `theme.mixin.multilineEllipsis(line, lineHeight)`의 2번째 인자로 별도 지정**한다(`-webkit-line-clamp`의 `max-height = line × lineHeight` 계산에 필요).
- **lineHeight 값은 `grep`으로 형제 관행값을 도출**:
  ```bash
  grep -rn "multilineEllipsis" src/pui --include="*.tsx"
  ```
  폰트 크기별 표준 줄간격(px) 관행: **15px → 18, 14px → 16~17, 12px → 14** (Figma 타이포의 `line height 100%`를 그대로 쓰지 않는다 — 한글 가독성 위해 폰트보다 살짝 큰 값으로 고정하는 게 팀 관행). 고정 `height`·`padding`도 동일하게 형제 카드값을 grep해 맞춘다.

> ⚠️ **mixin 숫자 인자는 "px"로 해석되어 `/10`되어 rem으로 변환된다(함정).** `theme.mixin.absolute/relative/fixed/position({ t, r, b, l })`와 `multilineEllipsis(line, lineHeight)`의 **숫자** 인자는 내부에서 `num / 10`rem 처리된다(`src/styles/mixin.ts`). 즉 `absolute({ t: 12 })` = `top: 1.2rem`, `multilineEllipsis(2, 18)` = `line-height: 1.8rem`. **`1.2rem`을 의도하고 `{ t: 1.2 }`를 넣으면 `0.12rem`이 되는 버그**가 난다(정적 검사 통과 → 화면만 틀어짐). rem 그대로 쓰려면 **문자열**로 넣는다(`{ t: '50%' }`, `multilineEllipsis(2, '1.8rem')`). 생성 전 형제값을 grep해 단위 감각을 맞춘다.

### 3-3-1. 고정 높이 카드의 다중행 말줄임 — 슬롯 계산 필수(잘림 방지)

카드 높이가 고정(예: Figma "Height 106 고정")이고 그 안에 N줄 말줄임 텍스트가 있으면, **`height: N×lineHeight`를 하드코딩하지 말 것.** `multilineEllipsis(N, lineHeight)`의 `max-height = N×lineHeight`가 **가용 슬롯보다 크면 마지막 줄이 `overflow:hidden`에 잘린다**(한글 받침/디센더가 픽셀 단위로 잘려도 **type-check·lint·stylelint 전부 통과** → 정적 검사로는 절대 못 잡는다).

- **가용 슬롯 계산**: `슬롯 = 카드높이 − 패딩(상+하) − 형제요소 높이합 − gap합`.
  - 예) Address: 카드 106 − 패딩 32 − info 14 − gap 8 = **주소 슬롯 52px**.
- **규칙**: `N × lineHeight ≤ 슬롯` 을 만족하도록 lineHeight를 정한다. 위 "15px→18" 관행값이라도 슬롯을 초과하면(예 3×18=54 > 52) **줄여야 한다**(3×17=51 ≤ 52). 관행값은 출발점일 뿐, 슬롯이 최종 제약이다.
- **구조는 Figma를 따른다(권장)**: Figma가 텍스트를 `flex:1`(슬롯을 자동 점유)로 두면 코드도 **`flex: 1; min-height: 0;`** 로 두고 고정 `height`를 박지 않는다. 그러면 ⓐ 짧은 텍스트에도 형제(info 등)가 바닥에 고정되고 ⓑ 슬롯 초과 오버플로가 원천 차단된다. `get_design_context` 결과의 `flex-[1_0_0]`가 이 신호다.
- ⚠️ 이 잘림은 **엣지 스토리(아주 긴 텍스트)로만 육안에 드러난다** — Phase 3 검증에서 **마지막 줄 받침이 온전한지** 반드시 확인한다.

### 3-3-2. 가로 말줄임이 안 걸리면 — auto-width 컨테이너가 텍스트에 맞춰 늘어난 건 아닌지 (필수)

`ellipsis()`(overflow:hidden + nowrap + text-overflow)를 걸었는데도 **긴 텍스트가 말줄임 없이 영역을 밀어내면**, 대개 텍스트의 **부모 컨테이너에 폭 상한이 없어** 컨테이너가 텍스트 길이만큼 늘어난 것이다(그러면 자식의 `width:100%`도 그 늘어난 폭이라 ellipsis가 무력화). 특히 `flex-direction:column` 세로 스택에서 **폭을 정하는 형제(썸네일·스트립 등)** 가 있는데 텍스트 줄이 그보다 길 때 발생한다(실제 사례: `OrderVoucherItemStay` info 텍스트가 날짜 스트립보다 길어 아이템 전체가 텍스트 폭까지 늘어나 → 다수 배열 시 영역 밖으로 삐져나감).
- 해결: **텍스트 블록이 컨테이너 폭을 밀어내지 못하게 클램프** — `width: 0; min-width: 100%`. width:0이라 intrinsic 폭 기여가 0 → 컨테이너는 폭-결정 형제(스트립 등)에 맞춰지고, `min-width:100%` 로 그 폭까지 늘어나 그 안에서 각 줄이 말줄임된다(flex 가로 말줄임의 `min-width:0` 과 같은 결의 트릭, cross-axis 버전).
- 점검: 다수 배열/긴 텍스트 엣지 스토리에서 **아이템이 서로 균일 폭이고 영역을 안 넘는지** 육안 확인(Phase 3).

---

## 3-6. 치수·간격·반응형·모양: Figma 절대값 → 토큰/반응형 변환 (필수)

색상(3-0)·폰트(3-3)처럼 **정량적 시각 요소(폭·간격·모양)** 도 Figma 절대값을 그대로 박으면 안 된다. `get_design_context`는 프레임의 고정 px를 그대로 내려주는데, 이를 rem으로 옮겨 박으면 **소형/대형 기기에서 레이아웃이 깨진다**(실제 실패 사례: 카드 폭 `34.5rem` 고정 → 320px 기기 오버플로우, 셀 모양 오독 → 타원/알약화).

### ⓐ 폭(width)은 절대값 금지 — 반응형으로 변환 (핵심)

**Figma 프레임의 고정 px width는 "디자인 캔버스 기준 폭"일 뿐 컴포넌트 고정폭이 아니다.** `width: 34.5rem`처럼 박지 말 것.

- **카드/리스트 아이템 폭**: 형제 선례를 따라 반응형으로. `src/pui/goodsCardSmall/components/GoodsCardSmall.tsx`의 `width: calc((100vw - 8rem) / 2); max-width: 16.7rem;`가 대표 패턴이다. 부모 폭을 채우면 되는 컴포넌트는 `width: 100%`, 뷰포트 비례가 필요하면 `calc(...)` + `max-width`.
- **캐러셀/그리드 아이템은 형제 간 동일 규격 폭**을 부여해 정렬을 맞춘다. 한 아이템은 고정폭인데 다른 아이템은 내용에 따라 폭이 결정되면(예: `testOrder`의 stay used=넓은 스트립 / unused=작은 원) 캐러셀이 불균일해진다.
- 반응형 분기가 필요하면 `theme.mediaQuery`(breakpoint `[320, 375, 414, 768]`)를 쓴다. 절대값만으로 도배하지 않는다.

### ⓑ 간격(spacing/padding/gap) 픽셀 → 토큰 매핑 + 중복 점검

Figma의 gap/padding px를 아래 `theme.spacing` 토큰으로 매핑한다(`src/styles/theme.ts`).

| Figma px | 토큰 | | Figma px | 토큰 |
|---|---|---|---|---|
| 2 | `theme.spacing.s2` | | 16 | `theme.spacing.s16` |
| 4 | `theme.spacing.s4` | | 24 | `theme.spacing.s24` |
| 8 | `theme.spacing.s8` | | 32 | `theme.spacing.s32` |
| 12 | `theme.spacing.s12` | | | |

- **대응 토큰이 없는 값(10·14·18·20px 등)은 임의 반올림 금지** → 형제 `grep`으로 관행 확인, 그래도 불명확하면 사용자 확인(색상 3-0과 동일 원칙).
- **패딩 중복 점검(필수)**: 컴포넌트가 패딩을 넣는 wrapper(예: `GridCarousel`의 4방향 일괄 `padding`)를 쓰면, 루트/자식에서 **같은 방향 패딩을 또 주지 말 것**. 겹치면 여백이 배가된다(실제 실패 사례: 루트 `padding-bottom: s16` + `GridCarousel padding={16}` + 아이템 `padding-bottom` = 하단 3중). 방향별로 분리(예: `paddingBottom={0}`)하거나 한쪽에만 준다.
  - ⚠️ **`GridCarousel`의 폴백이 함정이다** — `paddingTop: paddingTop ?? padding ?? 기본값` 구조라(`GridCarousel.tsx:37-45`) **`padding={16}`만 주면 상하도 16이 된다**(기본값 0이 아니라 `padding`이 먼저 먹는다). 좌우만 주려면 `paddingTop={0} paddingBottom={0} paddingLeft={16} paddingRight={16}`처럼 **방향을 전부 명시**한다. 입력은 px number(내부에서 `/10` rem 변환).
  - `GridCarousel`은 `styled()`가 아니라 `forwardRef` 함수다 → `${GridCarousel}` **컴포넌트 셀렉터가 안 먹는다.** `className`으로 잡는다(`className`·`ref`·`data-*`는 내부 styled div로 전달됨. 단 `GridCarouselProps`는 `data-*`를 타입으로 안 받으므로 상태 토글은 `is-*` 클래스로).

### ⓑ-1. 전역 CSS를 먼저 확인한다 — 중복 선언 방지

`src/styles/global.ts`가 이미 전역 규칙을 깔고 있다. 모르고 다시 선언하면 **무효 중복**이 된다.

- **`img { object-fit: cover; object-position: center; }`** (`global.ts:59-61`) — 이미지 크롭은 **전역이 이미 처리한다.** `${Image}`에 `object-fit`을 또 걸지 말 것(게다가 `Image`는 `<span>` 래퍼라 **span에 건 `object-fit`은 애초에 아무 효과가 없다** — 실제 `<img>`는 그 안의 `.image-sauce`다).
- `ul, ol, li { list-style: none }` 등도 마찬가지. 생성 전 `global.ts`를 훑는다.

### ⓒ 모양·radius는 개별 요소 기준 — 타원/알약화 금지

`border-radius`는 그룹 전체가 아니라 **셀·썸네일 개별 요소 기준**으로 판단한다.

- **비정사각(width≠height) 영역에 `50%`·`theme.radius.r100(...)` 금지** — 넓은 영역에 주면 **원이 아니라 타원/알약**이 된다(실제 실패 사례: stay 날짜 셀 `.thumb`에 `r100(64)` + `Image radius="50%"` → 알약+타원).
  - **원형 의도**면 먼저 `width === height`(정사각)를 보장한 뒤 `50%`/`r100`.
  - **라운드 사각**이면 디자인 코너값에 맞는 `theme.radius.r*`(r2~r16)를 쓴다.
- **원 vs 라운드사각 판별은 `get_screenshot` 육안 확인으로 확정**한 뒤 코드화한다(코드 텍스트만으로 코너 반경을 추정하지 않는다 — Phase 1 스크린샷 필수).

---

## 3-8. 캐러셀/스크롤 마스크 — 정적 마스크 이관 + 동적 노출 정책 확인 (필수)

가로 캐러셀·롤링 리스트는 양끝을 **페이드 아웃하는 마스크**(더 있음을 알리는 어포던스)를 갖는 경우가 많다. 두 층위를 구분해 다룬다(실제 실패 사례: `Order_Voucher` 캐러셀 양옆 페이드 마스크 통째 누락).

**ⓐ 정적 마스크는 design_context에 있다 → 반드시 코드로 이관 (놓침 금지)**
- `get_design_context` 출력에 `mask-alpha`/`mask-image`/`maskImage: url(...)` 이나 `data-name="carousel 시 mask"`(… `mask`) 같은 **래퍼 노드**가 나오면, 그것이 캐러셀 페이드 마스크다. 캐러셀을 `children` 스캐폴딩으로 단순화할 때 **이 마스크를 흘려버리지 말 것.**
- Figma는 alpha 마스크를 **이미지(url)** 로 주지만, 코드는 **형제 관행인 `mask-image: linear-gradient(...)`** 로 변환한다(포터블). 가로 페이드는 `90deg`, 세로는 `180deg`. 페이드 폭은 형제 grep(예: `paymentList`·`goodsCardSmall`·`selectFlight` 는 좌우 패딩과 같은 1.2~1.6rem)으로 맞춘다 — 임의 추정 금지(3-3).
  ```
  mask-image: linear-gradient(90deg, transparent 0%, rgba(0,0,0,1) 1.6rem, rgba(0,0,0,1) calc(100% - 1.6rem), transparent 100%);
  ```

**ⓑ 동적 노출 정책(on/off·좌/우/양쪽)은 Figma에 없다 → Gate 2에서 확인**
- "스크롤 불가면 마스크 off, 스크롤 위치에 따라 시작=오른쪽·끝=왼쪽·중간=양쪽" 같은 **토글 정책은 node/metadata/design_context 어디에도 없다**(Figma는 정적 페이드 한 장만 보여줌). 랜딩과 동일하게 **"미명시 ≠ 없음"** — 마스크가 감지되면 사용자에게 노출 정책을 확인한다(→ [common/gates.md](../../common/gates.md)).
- 구현: 스크롤 컨테이너의 `scrollLeft`/`scrollWidth`/`clientWidth` 를 관찰하는 훅(`hooks/useScrollMask.ts`)으로 `none`/`left`/`right`/`both` 상태를 파생하고, `data-mask` 속성(또는 클래스)으로 CSS 마스크를 토글한다. `scroll`(passive) + `ResizeObserver`(뷰포트) + `MutationObserver`(자식 추가/제거) 를 함께 관찰해 오버플로우 변화에 반응한다.
  ```tsx
  const { ref, mask } = useScrollMask<HTMLDivElement>();
  <div ref={ref} className="carousel" data-mask={mask}>{children}</div>
  // CSS: & .carousel[data-mask='both'|'left'|'right'] { mask-image: linear-gradient(90deg, …); }  // 'none'은 마스크 없음
  ```
- 상태별 마스크는 **정적 `& .carousel` 과 셀렉터를 분리**(`&[data-mask='…']`)해 stylelint `no-duplicate-selectors` 를 피한다.

**ⓒ "다 들어오면 vs 넘치면" 정렬 정책도 Figma에 없다 → 확인 후 오버플로우 상태로 토글**
- 캐러셀은 **콘텐츠가 가로 영역에 다 들어올 때(스크롤 없음)의 정렬**(가운데/왼쪽)과 **넘칠 때(스크롤)의 정렬**이 다른 경우가 많다(실제 사례: `Order_Voucher` 는 다 들어오면 가운데, 넘치면 `flex-start`+스크롤). 이 역시 정적 디자인엔 안 드러나니 사용자에게 확인한다.
- 구현: 마스크와 **같은 오버플로우 신호를 재사용**한다 — `useScrollMask` 의 `mask==='none'`(=오버플로우 없음)일 때 가운데 정렬, 그 외엔 `flex-start`. `&[data-mask='none'] { justify-content: center; }` 로 토글(개별 아이템은 고정 폭이면 그 폭 유지). `justify-content: center` 를 상시 걸면 오버플로우 시 스크롤 시작점이 잘리므로 반드시 "안 넘칠 때만" 적용한다.

**ⓓ 측정 기반 시각 상태는 `useLayoutEffect` 로 — `useEffect` 면 새로고침 때 시프트/깜빡임**
- 마스크·정렬처럼 **DOM 측정(`scrollWidth`/`clientWidth` 등) 결과로 시각 상태를 정하는 훅**을 `useEffect`(페인트 *후* 실행)로 두면, 첫 페인트가 초기 상태(예: `mask='none'`→가운데 정렬)로 그려졌다가 측정 후 바뀌어 **콘텐츠가 순간 이동**한다(실제 실패 사례). `useLayoutEffect` 로 바꿔 **첫 페인트 전에 측정·확정**하면 시프트가 사라진다. (이 앱은 CSR/WebView라 SSR 경고 없음; 아이템이 고정 폭이면 이미지 로딩과 무관하게 측정값 안정적이라 `ResizeObserver`/`MutationObserver` 는 이후 변화 대응용으로 유지.)
