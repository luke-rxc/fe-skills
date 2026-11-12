# 가이드 — 파일 구성 · 컴포넌트 골격 · 스토리

> 부가 컨벤션 중 **"무엇을 어디에 어떤 형태로 배치하나"**. 로드 시점: Phase 2 코드 생성 **항상**.
> 문서 관계·라우팅은 [pui-generation-guide.md](../pui-generation-guide.md).

대표 참고(파일 구성만 — 기존은 평평한 구조라 **위치는 따르지 않는다**): 단순형 `src/pui/button/`, 중간형 `src/pui/contentCard/`, 복합형 `src/pui/drawer/`·`src/pui/tabs/`.

> **실전 디테일**: 생성 직전 **같은 성격의 형제 컴포넌트 1개를 반드시 Read**해 네이밍·스타일링·export를 그대로 맞춘다(아래 패턴은 그 요약일 뿐, 최종 기준은 실제 코드다).

---

## 1. 파일/폴더 구성

```
src/pui/{category}/{name}/         # 카테고리 = 스토리 category와 1:1 (컨벤션 「배치」)
├── index.ts                       # barrel export (서브 컴포넌트도 export)
├── README.md                      # Changelog (필수, 정책은 pui-policy 5번)
└── components/
    ├── {Name}.tsx                 # 메인 컴포넌트 (+ styled)
    ├── {Name}{Sub}.tsx            # Figma `Master / sub` 서브 (해당 시)
    ├── {Name}{Sub}.stories.tsx    # 서브 스토리 — 서브마다 별도 파일 (해당 시)
    └── {Name}.stories.tsx         # 스토리 (필수)
```
복잡도에 따라 추가: `constants/{name}.ts`(`as const` 기본값/매직넘버), `hooks/use{X}.ts`(로직 분리), `styles/{name}.ts`(css 모듈 분리), `utils/{name}.ts`(컴포넌트 전용 순수 함수). 단순 컴포넌트는 추가 폴더 없이 한 파일로 충분.

> **컴포넌트 전용 유틸은 무조건 컴포넌트 로컬 `utils/`에 만든다(필수).** 컴포넌트가 필요로 해 **새로 만드는** 순수 함수(표기 라벨 생성·포맷·변환 등)는 root `src/utils`(`@utils`)에 추가하지 말고 **반드시 컴포넌트 폴더의 `utils/{name}.ts`** 에 둔다(형제 선례: `src/pui/liveCard/utils/liveCard.ts`의 `toDisplayDate`·`toGradient`). 단, 이미 존재하는 **공용 인프라 유틸**(`@utils/link`의 `getLink`, `@utils/date`의 `toDateFormat` 등)을 **재사용**하는 것은 그대로 허용 — 금지 대상은 "이 컴포넌트를 위해 새 유틸을 root에 만드는 것"이다.

**barrel export(index.ts)**: PUI Convention은 명시적 named export를 지향하지만, 현재 코드베이스는 vite 순환참조 이슈로 `export *`를 쓴다. **형제 컴포넌트의 실제 index.ts 패턴을 따르되**, 순환참조가 없으면 named export를 우선한다.
```ts
export * from './components/{Name}';   // 현 코드베이스 관례(순환참조 회피)
```

---

## 2. 컴포넌트 골격 (forwardRef + Props + styled 래핑)

거의 모든 pui 컴포넌트가 따르는 형태:
```tsx
import { forwardRef, HTMLAttributes } from 'react';
import styled from 'styled-components';
import classnames from 'classnames';

/** {컴포넌트 한 줄 설명} */
export interface {Name}Props extends HTMLAttributes<HTMLDivElement> {
  /** 사이즈 */
  size?: 'small' | 'medium' | 'large';
  /** 스타일 변형 */
  variant?: 'primary' | 'secondary';
  // ... 모든 prop에 한국어 JSDoc 주석 (필수)
}

const {Name}Component = forwardRef<HTMLDivElement, {Name}Props>(
  ({ className, size = 'small', variant = 'primary', children, ...props }, ref) => {
    const classNames = classnames(className, `is-${size}`, `is-variant-${variant}`);
    return (
      <div ref={ref} className={classNames} {...props}>
        {children}
      </div>
    );
  },
);

export const {Name} = styled({Name}Component)`
  /* styles — theme 토큰 사용 */
`;
```

규칙 요약:
- **`forwardRef<RefType, PropsType>` 제네릭 명시**. ref는 항상 루트 DOM(또는 `useImperativeHandle`로 커스텀 핸들)에 연결.
- **Props는 `export interface {Name}Props`로 파일 상단 정의**(별도 `types/` 파일 생성 금지 — code-conventions 규칙). 적절한 `HTMLAttributes<...>`를 확장하고, 충돌 시 `Omit`.
- **내부 함수 컴포넌트는 `{Name}Component`**, styled 래핑 후 **공개 이름은 `{Name}`**으로 export.
- **상태/옵션은 `classnames`로 `is-{state}`·`is-{type}-{value}` 클래스** 부여(스타일은 그 셀렉터로).
- `displayName`은 대부분 생략(편차 — 필요 시에만).
- 기본값은 구조분해 기본값 또는 `styled(...).attrs(...)`(변형 래퍼)로.

**변형 래퍼 패턴**(Button 계열): 베이스를 `.attrs`로 좁혀 재export.
```tsx
export const {Name}General = styled({Name}).attrs<{Name}GeneralProps>(
  ({ size, variant }) => ({ size: size || 'medium', variant: variant || 'primary' }),
)<{Name}GeneralProps>``;
```

**styled 선언 위치**: styled 선언은 **같은 파일** 끝에 두는 게 기본. 스타일이 크면 `styles/{name}.ts`에 `css` 모듈로 쪼개 조합(Button 사례: `baseCss`/`sizeCss`/`variantCss` …). 토큰 사용법은 → [figma-to-css.md](figma-to-css.md).

---

## 4. 스토리 (defineMeta) — 작성 패턴

> 섹션 번호는 원본 가이드 체계를 유지한다(다른 문서가 "4번"으로 참조).

정책상 pui는 스토리 **필수**(필수 여부·구성 규칙은 pui-policy 4번). 작성은 `@pui/_utils`의 `defineMeta`로 통일(eslint 커스텀 룰 `custom-rules/design-system`이 pui 스토리에 강제한다):
```tsx
import { defineMeta } from '@pui/_utils';
import { StoriesMenu } from '@stories/menu';
import { {Name} } from './{Name}';

export default defineMeta({
  component: {Name},
  category: StoriesMenu.PDS.{카테고리},   // Gate 2에서 확정 (Figma에 없는 코드베이스 taxonomy)
  componentGroup: '{섹션명}',            // PDS 섹션 이름 (컴포넌트명 아님) — gates.md Q3
  name: '{Name}',
  design: [{ file: 'pds', nodeId: '{node-id}' }],  // file: pds | prizmApp | prizmWeb | prizmContent (FIGMA_FILES 키)
});

const Template: StoryFn<typeof {Name}> = (args) => <{Name} {...args} />;
// 스토리 목록·이름·순서 → 아래 「스토리 순서·이름 = Figma 배치」 ({범주}_{케이스})
```

- **`file`·`nodeId`는 Phase 0에서 URL로 확정된 값**을 쓴다. `file`은 URL의 fileKey를 `src/pui/_utils/types.ts`의 `FIGMA_FILES`로 역조회한 키다.
- ⚠️ **`nodeId`는 dash 포맷(`1782-2695`)으로 박는다.** `get_metadata` 응답은 colon(`1782:2695`)이지만 스토리 관행은 dash다(89건 전부). 런타임 `normalizeNodeId`가 흡수하긴 하나 관행을 따른다.
- **스토리 구성 = Figma 배치 매트릭스 + Figma 밖 케이스(상태·랜딩·엣지)** — 아래 「스토리 순서·이름 = Figma 배치」. **케이스마다 story 하나**(「팀 작성 규칙」 2). 매트릭스가 Default·Variant를 모두 덮으므로 `기본` 스토리를 따로 두지 않는다.
  - **부모가 자식 pui를 조합하고 자식 variant마다 상태 표현이 달라질 수 있으면**, 그 상태(disabled 등)를 **자식 variant별로 스토리를 만든다**(→ [composition.md](composition.md) 3-7-1 ⓑ). 자식 type/variant를 한 케이스로만 검증하면 다른 케이스의 오버라이드 누락을 못 잡는다. 예: `Disabled가격형`·`Disabled옵션형`·`Disabled수량형`.
- **enum/유한값 variant prop은 값마다 story를 둔다(필수)** — 한 스토리에서 controls로만 바꾸게 두지 않는다. 대개 **Figma 구역·행·열 축이 곧 enum**이라 아래 「스토리 순서·이름 = Figma 배치」를 따르면 자동으로 충족된다.
  - **Figma 축에 없는 enum**(다른 pui에서 위임받은 `GoodsMedium.tagType: PrizmOnlyTagType` 등 — 소비 컴포넌트도 대상)은 Figma 밖 케이스로 `{prop 범주}_{값}` 범주를 만든다. `'none'`처럼 "미노출" 값은 기본 케이스가 겸할 수 있다.
  ```tsx
  export const 태그_프리즘온리 = Template.bind({});
  태그_프리즘온리.args = { ...기본값, tagType: 'prizmOnly' };
  export const 태그_라이브온리 = Template.bind({});
  태그_라이브온리.args = { ...기본값, tagType: 'liveOnly' };
  ```
- **export명 lint 규칙 (실측)** — eslint `@typescript-eslint/naming-convention`은 **언더스코어가 들어간 이름에 영문이 한 글자라도 있으면** 대소문자·위치와 무관하게 에러다. 범주 규칙상 언더스코어를 쓰므로 **이름은 전부 한글**로 쓴다.
  | 통과 | 에러 |
  |---|---|
  | `그룹오프_버튼_기본` · `태그_프리즘온리` · `상품명_긴텍스트` | `그룹Off_기본` · `Small_판매중` · `스몰_Small` · `태그_PrizmOnly` · `태그_prizmOnly` · `이미지없음_bg노출` |
  - 언더스코어가 **없는** 이름은 영문을 섞어도 통과한다(`판매중Small` · `태그PrizmOnly`) — 범주 접두를 쓰지 않는 예외 케이스에서만.
- 상태가 필요한 컴포넌트(Drawer 등)는 Template 내부에서 `useState`로 제어한다. 이때도 **args는 가공 없이 그대로** 넘긴다(「팀 작성 규칙」 3).
- `design` 배열에 **원본 Figma nodeId 연결**(재사용 역방향 매핑의 근거가 된다 — Phase 1 매핑 조사가 이걸 역으로 읽는다).

### 팀 작성 규칙 (원본: Notion PUI Storybook)

> 원본: https://www.notion.so/rxc/PUI-Storybook-8e005c60a5834b60b8cbdcf9f2d10cd2 「작성 규칙」 DB(5건, 동기화 2026-09-29). 규칙이 바뀌면 원본을 먼저 확인한다.

1. **컴포넌트 하나 = stories 파일 하나.** 케이스별로 파일을 쪼개지 않는다(`Case1.stories.tsx` ✗). 서브 컴포넌트는 별개 컴포넌트라 자기 파일을 갖는다(pui-policy 4번).
2. **디자인 케이스 하나 = story(named export) 하나.** 한 story 안에 여러 케이스를 나열하지 않는다 — `cases.map(...)`으로 그리는 "케이스 보드", 제목(`<h2>`)을 붙여 여러 인스턴스를 늘어놓는 Template 모두 위반. 비교용 모아보기가 필요해도 story를 나눈다(Storybook 사이드바가 곧 목록이다).
3. **Template은 args를 받아 그대로 넘긴다.** `const Template = (args) => <{Name} {...args} />`. Template 안에서 args를 병합·가공하지 않는다(`{...args, ...other}` ✗). 케이스 간 공통값은 **story의 `.args`에서** `...기본값`으로 합친다.
4. **title = `category / componentGroup / name`(PDS) · `category / name`(Non-PDS).** `defineMeta`가 조합한다(`title` 직접 지정 금지). Non-PDS는 **`componentGroup`을 넣지 않는다** — 예: `${StoriesMenu.NonPDS}/Bookmark`.
5. **`design`은 배열이다** — Figma(`{ file, nodeId }`)와 비-Figma 링크(`{ url, type: 'link' }`, 예: Notion 모션 가이드)를 한 배열에 섞을 수 있다. Doc 외에 참고 문서가 있으면 함께 연결한다.

```tsx
// ❌ 케이스 보드 — 한 story에 케이스 N개 (규칙 2 위반)
export const Small케이스: StoryFn = () => <Board>{cases.map((c) => <{Name} {...c.props} />)}</Board>;

// ✅ 케이스마다 story (이름·순서는 아래 「스토리 순서·이름 = Figma 배치」)
const 스몰기본값 = { status: 'onSale', size: 'small', price: 22500 } as const;
export const 스몰_할인율가격 = Template.bind({});
스몰_할인율가격.args = { ...스몰기본값, discountRate: 20 };
export const 스몰_매진 = Template.bind({});
스몰_매진.args = { ...스몰기본값, status: 'soldOut' };
```

- 레이아웃 폭 같은 **표시용 래퍼가 필요하면 Template이 아니라 `decorators`**로 준다(Template을 규칙 3대로 순수하게 유지).

### 스토리 순서·이름 = Figma 배치 (필수)

사이드바에서 케이스를 찾기 쉬우려면 **디자이너가 마스터 캔버스에 나열한 분류·순서를 그대로 옮긴다**. 이름이 제각각이거나 순서가 섞이면 규칙 1~3을 지켜도 목록을 읽을 수 없다(실패 이력: FE-6555 `GoodsSmall` 19개·`PriceArea` 10개를 사용자가 "나열해서 보기 어렵다"며 전면 재작성).

1. **큰 범주 = 마스터 캔버스의 구역.** 디자이너가 라벨을 붙이거나 위치로 묶은 단위(예: `Grouped off`/`Grouped on`, `small`/`mini`)다. `get_metadata`의 symbol **y 좌표 묶음**(구역·행)과 **x 좌표 순서**(열), 스크린샷의 구역 라벨로 읽는다. 구역 안에서는 **행 → 열 순서**로 export한다.
   - 실측: `Goods_Small`은 Grouped off(y 100~354) / on(y 552~806) 구역, 행 = Trailing None → button → badge, 열 = info Default → Brand → Option → Brand + Price. `price area`는 small(y 23·54) / mini(y 104·135), 구역 안 on sale → sold out.
2. **이름 = `{범주}_{케이스}` 또는 `{범주}_{하위}_{케이스}`.** 예: `스몰_판매중`, `그룹오프_버튼_브랜드`. 사이드바에는 `스몰 판매중`처럼 보인다.
   - ⚠️ 언더스코어가 들어가면 **영문이 섞인 순간 lint 에러**다(`그룹Off_기본` ✗) — 범주·케이스 모두 한글(`그룹오프_`·`스몰_`). 실측 표는 위 「export명 lint 규칙」.
3. **export 순서 = 사이드바 순서.** `.storybook/preview.jsx`의 `storySort`에 `includeNames`가 없어 story 이름은 정렬되지 않는다. 가나다순으로 이름을 맞출 필요 없이 **Figma 순서대로 export**한다.
4. **Figma에 없는 케이스는 매트릭스 뒤에 성격별 범주로 붙인다** — `상태_`(매진 등 Doc 규칙) · `랜딩_`(링크 유무·비활성) · `썸네일_` 같은 기능 범주 · 마지막에 `엣지_`(긴 텍스트·큰 값·1개/다수).
   - **예외 — 구역 안 prop 조합은 그 구역 범주에 둔다.** Figma variant 축이 적고(예: `price area`는 on sale / sold out뿐) 구역 차이가 폰트·노출 규칙처럼 **구역마다 다르게 보이는 것**이면, 선택 prop 조합(할인율·최저가·수량 유무)과 그 구역의 엣지 값도 **구역 범주 안**에 둔다 — 구역별로 같은 조합을 나란히 봐야 비교된다. 순서는 **variant 순서를 골격으로**, 각 variant 뒤에 그 variant의 조합을 잇고 구역 엣지를 끝에 둔다.
     - 실측(`PriceArea`): `스몰_판매중`(variant) → `스몰_할인율가격` · `스몰_할인없음` · `스몰_최저가` · `스몰_수량` → `스몰_매진`(variant) → `스몰_품절문구` → `스몰_긴금액`, 이어서 `미니_…` 같은 순서.
     - 구분 기준: **어느 구역에서 보든 결과가 같은 케이스**(링크 유무·썸네일 숨김 등 — GoodsSmall)는 구역 밖 기능 범주로, **구역에 따라 모양이 달라지는 케이스**는 구역 안으로.
   - **Doc 행동규칙 커버리지(필수)** — Doc 규칙 중 **화면으로 확인되는 것은 규칙마다 story를 1개 이상** 둔다(문구 분기·상태별 노출·여백 조건 등). 스토리 JSDoc에 규칙 번호를 적는다(`/** … (Doc R12) */`). 실패 이력: FE-6555 `GoodsSmall`에서 R12(배송 "품절"/티켓 "매진")·R13(바우처 사용 가능=버튼/그 외=배지)를 사용자 지시 후에야 추가.
5. **Figma variant에 대응하는 스토리는 story 단위 `design`에 variant nodeId를 연결한다** — Design 패널에 마스터 세트 전체가 아니라 그 variant가 떠 1:1 대조가 된다. `@pui/_utils`의 `figma()`를 쓴다. Figma 밖 케이스는 meta의 세트 nodeId를 그대로 상속한다.
6. **샘플 값은 Figma 텍스트를 그대로 쓴다** — `상품명`·`Brand`·`option name`·`Button`처럼. 스크린샷과 나란히 볼 때 차이만 눈에 띈다. **구역마다 값이 다르면 구역 값대로** 쓴다(예: `Goods_Small` Grouped off `249,500원~` / on `249,000원~`).
7. **표시용 `decorators`는 Figma 캔버스만 재현한다** — 캔버스 배경색·폭 정도까지. **Figma에 없는 박스(흰 카드·radius·여백)를 덧대지 않는다.** 투명 배경 variant(Grouped on 등)를 "실제 쓰임처럼" 보이려고 흰 박스에 얹으면 점선 외곽 바깥에 디자인에 없는 흰 영역이 생겨 대조가 틀어진다(실패 이력: FE-6555 `GoodsSmall` `GroupBox` 데코레이터 → 제거).
   - 구성: **캔버스 div(여백 + 배경색)** → **경계 컨테이너(점선 `border`, 컴포넌트에 딱 맞게)** → Story. 경계는 래퍼가 그리고 **컴포넌트 셀렉터(`${Name} { outline }`)로 컴포넌트 스타일을 건드리지 않는다**(사용자 확정). border 1px는 컨테이너 쪽에 붙어 컴포넌트 치수에는 영향이 없다.

8. **스토리 목록은 코드보다 먼저 표로 확정한다** — 배치 실측 직후 「스토리 구성」 표(범주 · 케이스 · 연결 variant · 근거 R#)를 설계 노트에 쓰고 **Gate 2에서 재사용 매핑과 함께 제시**한다(→ [common/gates.md](../../common/gates.md) Gate 2). 목록을 코드로 다 만든 뒤에 보여주면 분류가 어긋났을 때 전면 재작성이 된다(실패 이력: FE-6555 두 컴포넌트 전면 재작성). Phase 3는 이 표와 사이드바를 대조한다(→ [verify/verification.md](../../verify/verification.md) 「스토리 검증」).

```tsx
import { defineMeta, figma } from '@pui/_utils';

/* small 구역 → mini 구역, 각 구역 안 on sale → sold out (Figma 배치) */
const 스몰기본값 = { status: 'onSale', size: 'small', price: 22500 } as const;

export const 스몰_판매중 = Template.bind({});
스몰_판매중.args = { ...스몰기본값, discountRate: 20, minPrice: true, quantity: '2박' };
스몰_판매중.parameters = { design: [figma({ file: 'pds', nodeId: '64337-56229' })] }; // variant 노드

export const 스몰_할인율가격 = Template.bind({});
스몰_할인율가격.args = { ...스몰기본값, discountRate: 20 };
// … 스몰_매진(variant 노드) · 스몰_긴금액 → 미니_판매중 …
```

- 레퍼런스: `src/pui/dataDisplay/priceArea/components/PriceArea.stories.tsx`(1축 구역), `src/pui/dataDisplay/goodsSmall/components/GoodsSmall.stories.tsx`(구역 × 행 × 열 매트릭스 24개 + Figma 밖 케이스).

**엣지 케이스 스토리(필수)** — 정적 검사(type/lint/stylelint)는 줄간격·고정높이·말줄임 같은 **픽셀 정합을 못 잡는다.** 아주 긴 텍스트·빈 값 등 동적 콘텐츠를 일부러 깨뜨리는 스토리를 만들어 Storybook에서 확인한다(짧은 더미로는 안 드러난다). `design`에 nodeId가 연결돼 있으면 Storybook **Design 패널에 Figma 임베드가 같이 떠** 별도 캡처 없이 대조할 수 있다. 확인 방법(측정 주·육안 보조)은 → [verify/verification.md](../../verify/verification.md), 컨벤션 체크는 → [review.md](../review.md).

### ⚠️ `argTypesRegex` — 핸들러 유무로 노출하는 패턴은 스토리에서 항상 노출된다 (실측 함정)

`.storybook/preview.jsx`에 **`actions: { argTypesRegex: '^on[A-Z].*' }`** 가 걸려 있다. Storybook이 **`on*` prop 전부에 액션 핸들러를 자동 주입**하므로, `onClickXxx` 유무로 요소를 노출하는 컴포넌트는 **args에 안 넘겨도 항상 노출된다.**

- 실측: `OrderVoucher`의 `사용` 버튼(`onClickUse` 있을 때만 렌더)이 **버튼이 없어야 할 dining·전체사용 스토리에서도 렌더**됐다. Figma 대조가 불가능해진다.
- 해결: 그 케이스의 args에 **`onClickUse: undefined`를 명시**한다. 명시적 `undefined`가 자동 주입을 이긴다.
- 형제 선례: `orderVoucherListItem/components/OrderVoucherListItem.stories.tsx`의 `공통`이 `onClickUsable: undefined`를 박아둔 게 같은 문제를 겪은 흔적이다.

```tsx
/** 핸들러 유무로 노출되는 요소는 미노출 케이스에 undefined를 명시해야 Storybook에서도 확인된다 */
const 사용버튼없음 = { onClickUse: undefined };

export const Dining일부사용 = Template.bind({});
Dining일부사용.args = { ...(공통), ...사용버튼없음 };
```

### 스토리 샘플 이미지는 "그 크기에서 사진으로 읽히는 것"으로 (필수)

썸네일이 작을수록(64px 등) **어떤 사진이냐가 육안 검증을 좌우한다.** 흰 배경 제품컷의 중앙 크롭은 **깨진 이미지 아이콘처럼 보인다** — 실측에서 같은 오판을 3회 반복했고, `complete`·`naturalWidth`를 측정하고서야 정상임이 확인됐다. 리뷰어도 똑같이 오판한다. 샘플은 그 크기에서 사진으로 읽히는 것으로 고른다.
