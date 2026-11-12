# Phase 0 — 인테이크: URL 1개 → probe → 확정 카드

> 로드 시점: Phase 0. 게이트 규칙 전반은 [common/gates.md](../common/gates.md), 호출측 인자는 [common/input-contract.md](../common/input-contract.md).

**목표: 사용자에게 물어보는 걸 최소화한다.** Figma URL 하나만 있으면 파일 타입·마스터·Doc·서브·기존 구현 충돌까지 **도구로 도출**되고, 사람에게 남는 건 도구가 알 수 없는 것뿐이다.

```
URL → 파싱(fileKey/nodeId) → get_metadata probe → 판정표 → 후보 확정
                                                          → 확정 카드 + 🚦Gate 1
```

---

## 1. URL 확보

우선순위대로:

1. **스킬 인자** — `/figma-to-component <url>` (→ [common/input-contract.md](../common/input-contract.md))
2. **사용자 메시지** — 붙여넣은 Figma URL
3. **없으면 Gate 0** — `AskUserQuestion`으로 URL을 묻는다. **파일 타입을 묻지 말 것** — URL에 이미 들어 있다. 값은 "Other(기타)" 자유입력 칸으로 받는다.
   > 안내 문구: "Figma에서 컴포넌트(또는 그 상위 섹션)를 선택 → 우클릭 → Copy link to selection 으로 복사한 URL을 주세요. **섹션 URL을 주시면 Doc과 서브 컴포넌트까지 자동으로 잡힙니다.** 마스터 URL을 주실 때 `Order_Voucher / item_stay`처럼 **이름이 슬래시로 나뉜 서브 컴포넌트가 있으면 그 URL도 함께** 주세요."

---

## 2. URL 파싱

`src/pui/_utils/meta.ts:115-122`의 `parseFigmaUrl`과 **동일한 규칙**을 쓴다.

| 추출 | 규칙 |
|---|---|
| fileKey | `/figma\.com\/(?:file\|design)\/([^/?]+)/` → `FIGMA_FILES`에서 id 역조회 → `pds` \| `prizmApp` \| `prizmWeb` |
| nodeId | `/[?&]node-id=([^&]+)/` → `decodeURIComponent` |

- **매핑 테이블은 `src/pui/_utils/types.ts`의 `FIGMA_FILES`를 Read해 확인한다.** 이 문서에 하드코딩 복제하지 않는다(단일 원본 유지).
- **이 역조회가 "파일 타입" 질문을 없앤다.** fileKey → 키는 결정적 함수라 사람이 더 잘 알 수 없다. 묻지 말 것.

> ⚠️ **포맷 함정 — colon vs dash.** `get_metadata` 응답의 id는 **colon**(`1782:2695`), URL·스토리는 **dash**(`1782-2695`)다.
> - MCP 도구 입력: 둘 다 허용(`^\d+[:-]\d+$`)
> - `defineMeta`의 `design.nodeId`: **dash로 박는다**(스토리 89건 전부 dash 관행. 런타임 `normalizeNodeId`가 흡수하지만 관행을 따른다)
> - **grep은 항상 양쪽 포맷으로**: `grep -rnE "1782[-:]2695"` — 한 포맷만 찾으면 기존 구현을 놓친다

### 예외 처리

| 케이스 | 처리 |
|---|---|
| **fileKey가 `FIGMA_FILES`에 없음** | 중단. `defineMeta.design.file`은 `FigmaFileKey`만 받으므로(`types.ts:15,18`) 미등록 파일은 스토리로 표현 불가다. 추측 금지 — 등록된 파일의 URL을 재요청하거나, "`types.ts`에 파일 등록"이 필요하다고 사용자에게 에스컬레이트한다. |
| **node-id 없는 파일 링크** | probe 불가(nodeId 없는 `get_metadata`는 최상위 페이지 목록만 준다). "노드를 선택해 Copy link" 안내 후 재요청. |
| **figma URL이 아님** | Gate 0으로. |
| **node-id만 옴(파일 불명)** | 파일 타입을 묻지 말고 **URL을 묻는다** — 질문 1회로 같고 정보량이 크다. |
| **node-id + `--file=` 인자** | `buildFigmaUrl(nodeId, file)`(`meta.ts:109-112`)로 URL 복원 후 진행. 질문 0회. |
| **probe 응답이 과대(섹션이 너무 큼)** | 응답 크기 자체가 "URL이 너무 넓다"는 신호. 후보 표만 요약 제시하고 범위를 좁혀 달라고 요청한다. |

---

## 3. probe — `get_metadata`

```
get_metadata(fileKey, nodeId)   # clientFrameworks: react, clientLanguages: typescript
```

응답 맨 위에 **`Currently selected nodes:` 블록**이 붙을 때가 있다. 사용자가 Figma에서 지금 선택 중인 노드다.

> ⚠️ **이 블록은 "확인 신호"일 뿐 "불일치 감지기"가 아니다(실측).** 도구는 **선택이 조회 요청과 관련될 때만** 이 블록을 붙인다. 실측: 섹션 `29920:137618`을 선택한 채 같은 노드를 조회하면 블록이 뜨지만, **그 자식인 `1782:2695`를 조회하면 블록이 아예 안 뜬다.**
> - 블록이 **있고 URL nodeId와 같다** → 사용자가 의도한 노드가 맞다는 약한 확인. 카드에 표기해도 좋다.
> - 블록이 **없다** → **오입력 신호가 아니다.** 선택이 없거나 다른 노드일 뿐이다. **없다는 것으로 아무 결론도 내리지 말 것.**
>
> 즉 이걸로 오입력을 잡으려 하지 말고, **질문거리로도 삼지 않는다.** 대상 확정은 어디까지나 판정표 + Gate 1이다.

## 4. 판정표 — 노드 정체 분류

> PDS 전체 덤프(2.8MB/63만 토큰) 실측으로 검증된 규칙을 f2c의 좁은 서브트리 조회용으로 옮긴 표다.

대상 노드와 자식 1~2레벨에 위에서부터 적용:

| 트리 신호 | 판정 | 처리 |
|---|---|---|
| 이름 토큰에 독립 `Doc` (예: `Card_Brand Doc`) | **Doc 시트** | **이름 규칙이 최우선** — 마스터 후보에서 제외하고 Doc 후보로 등록 |
| `<instance>` | **인스턴스(사용처)** | 마스터가 아니다. 후보에서 제외 |
| `<symbol name="축=값">` (예: `Size=medium`) | **variant** | 마스터가 아니다 → **부모 `<frame>`이 F.M.C. 세트** → 부모 id로 승격 |
| 직속 `<symbol>` 자식 2개+ 또는 자식 이름이 `키=값` | **마스터 세트(F.M.C.)** | 마스터 후보. variant 축 = 자식 symbol 이름들 |
| 직속 `<symbol>` 자식 1개 + plain 이름 (예: `❖ Goods_Mini`) | **단일 마스터** | 마스터 후보 |
| `<section>` 부모 아래 단독 `<symbol>` plain (예: `Menu_AOS`) | **단일 마스터** | 마스터 후보 |
| `<section>` / 위 어디에도 안 걸리는 `<frame>` | **컨테이너** | 자식 1레벨 스캔 → 규칙 재적용 |

**실측 확인 (PDS `Brand` 섹션 — f2c의 좁은 서브트리 조회로 재현됨)**

```
get_metadata(29920:137618) → <section name="Brand">          = 컨테이너 → 자식 스캔
  <frame name="Card_Brand Doc">                              = Doc 시트 (이름 토큰)
  <frame id="1782:2695"   name="Brand_profile">              = 마스터 세트 ← 세트 id
     <symbol id="225:413"   name="Size=medium"/>             = variant (부모로 승격)
     <symbol id="1761:2652" name="Size=small"/>
  <frame id="58743:48543" name="Brand_img">                  = 마스터 세트
     <symbol name="Shadow=Off"/> <symbol name="Shadow=On"/>

get_metadata(65873:57908) → <frame name="Brand_small">       = 단일 마스터
  <symbol id="65873:57906" name="Brand_small"/>              = 심볼 1개 + plain 이름
```

- **세트/단일 마스터 모두 `design`에 박는 id는 바깥 `<frame>` id다**(`1782-2695`·`65873-57908`). 안쪽 `<symbol>` id가 아니다.
- `Brand_small`의 frame `57908` / symbol `57906`처럼 **id가 우연히 가까울 수 있으나 그건 우연이다** — 관계는 트리로만 읽는다.

**보조 신호**
- **`❖ ` 접두사 = 발행 마스터 표식** → 신뢰도 `HIGH`, 이름에서 제거하고 `published=true`. ⚠️ **부재는 반증이 아니다** — 실측한 `Brand_profile`엔 `❖`가 없었지만 정상 마스터 세트였다. 없으면 구조로 판정하되 신뢰도 `MEDIUM`.
- **제외 마커** — 이름에 `[as-is]`·`sample`·`example`·`deprecated`·`폐기`·`보관`·`[fade out]`, 또는 `[aos]`/`[ios]`(네이티브 전용) 같은 토큰이 붙은 후보는 **카드에 경고 표기**한다. 전체 목록(실제 PDS 오탐을 잡으며 축적):
  - 섹션 이름 부분일치: `sample` · `example` · `deprecated` · `do not use` · `폐기` · `보관` · `[fade out]`
  - 컴포넌트 이름 선두 대괄호 토큰: `as-is` · `as is` · `old` · `deprecated` · `폐기` · `보관` · `fade out` · `예전` · `구버전` (`[Mweb]`처럼 폐기성이 아닌 토큰은 제외 대상 아님)
  - 네이티브 전용 섹션: `[aos]` · `[ios]` · `[android]`
- **`Doc` 토큰은 단어 경계로 판정** — `Card_Brand Doc` ✓ / `DocumentCard` ✗.

> ### 🚫 폐기된 규칙 — variant ±1 추정
> 예전 이 스킬은 *"서브 마스터 세트 id는 자동 도출 불가, variant id의 인접 ±1로 추정"* 이라고 적고 있었다. **반증됐다.**
> 실측(`Brand` 섹션): 세트 `1782:2695`의 자식 variant는 `225:413`·`1761:2652` — **인접하지 않는다.**
> 세트 id는 **`get_metadata` 트리의 부모-자식 관계로 정확히 읽힌다.** ±1 추정도, "후보 id를 사용자에게 확인받는 질문"도 하지 않는다.
>
> 또한 *"이름이 `부모 / 자식`으로 맞아 보여도 실제 F.M.C.가 아닐 수 있다"* 던 과거 실패의 원인은 **원리적 불가가 아니라 태그를 안 본 것**이었다 — `<instance>`(사용처)와 `<symbol>`(마스터 정의)은 태그로 구별된다. 규칙을 정확히 쓰면 재현되지 않는다.

---

## 5. 마스터 후보 0 / 1 / 2+

### 2개 이상 — 질문 1문항, 옵션 = 후보 자체

```
① 1782-2695   Brand_profile  set · Size=medium|small
② 58743-48543 Brand_img      set · Shadow=Off|On
```

- **옵션을 후보 그 자체로 만든다** → 카드를 읽지 않으면 답할 수 없어 rubber-stamp가 구조적으로 불가능하다(→ [common/gates.md](../common/gates.md) 강제 독해).
- 후보 5개 이상이면 옵션 3개 + Other(id 직접 입력), 전체 표는 카드에.
- **하나만 골라 순차 처리한다.** 다 만들려면 끝난 뒤 "다음 것도 만들까요?"로 이어간다. 한 번에 N개를 만들면 네이밍·category·랜딩 게이트가 N배가 되어 이 스킬의 목적과 정면 충돌한다.

### 1개 — 2지선다 (비용 0)

`이 마스터로 진행: 1782-2695 Brand_profile (set, ❖발행)` / `아니다 — 다른 노드(Other)`

신뢰도가 높아도 **"확정은 사용자 선택의 결과"** 불변식은 지킨다. 어차피 열려 있는 Gate 1에 배칭되므로 **상호작용 비용이 0**이다.

### 0개 — 에러가 아니다

| 상황 | 안내 |
|---|---|
| **Doc 시트만 가리킴** | "이건 `{name} Doc` 시트입니다(마스터가 아닙니다). **상위 섹션 URL을 주시면 Doc과 마스터가 함께 잡힙니다.**" → URL 재요청 |
| **`<instance>`만** | 사용처를 가리키고 있다. 마스터 URL 재요청 |
| **로컬 프레임(화면 시안)** | **정당한 입력이다.** PUI 원칙 1 불충족([build/pui-policy.md](../build/pui-policy.md))이므로 **pui 경로는 막고 비즈니스 경로(`features`/`apps`)로 진행** 옵션을 준다. `prizmApp`/`prizmWeb` 시안은 마스터가 아니지만 비즈니스 컴포넌트로는 정상이다 |

**이게 "잘못된 URL" 문제의 답이다** — probe가 모호함을 *"무엇이 왜 잘못됐고 어떻게 고치나"* 로 바꾼다. 에러로 튕기지 않는다.

---

## 6. Doc 자동 감지 — 그리고 정직한 한계

**규칙**: probe 서브트리 안에서 이름 토큰에 독립 `Doc`이 있는 `<frame>` → Doc 후보. 확정되면 Phase 1에서 마스터와 **함께 추출**한다.

**한계**: `get_metadata(nodeId)`는 **그 노드의 서브트리만** 준다 → **형제는 못 본다.**

| URL을 어디로 주나 | 마스터 | Doc | Gate 1 문항 |
|---|---|---|---|
| **섹션**(부모) | 후보 2+ → 질문 1 | 자식이므로 **자동 감지** | **1** |
| **마스터** 직접 | 확정 → 확인 1 | 형제라 **감지 불가** → 질문 1 | **2**(배칭하면 실질 1회) |

어느 쪽이든 Gate 1은 1회다. 카드에 "섹션 URL을 주시면 Doc까지 자동으로 잡힙니다"를 안내해 **다음 호출을 더 싸게** 만든다.

> **미감지 시 질문은 반드시 남긴다.** `Doc 노드 미감지 ≠ Doc 없음`(다른 섹션·다른 파일에 있을 수 있다). 감지 실패와 부재를 구별할 수 없으므로 물어야 한다 — 랜딩의 *"미명시 ≠ 랜딩 없음"* 과 **정확히 같은 구조**다(→ [common/gates.md](../common/gates.md)).
> 예전 문서의 *"Doc은 자동 탐색하지 않고 사용자가 명시"* 는 **설계 선택이었지 도출 불가라서가 아니었다** — 그 전제만 무효화하고 폴백 질문은 보존한다.

## 6-2. 서브 컴포넌트 감지 — Doc과 같은 한계, 신호는 있다

PDS의 서브(`Order_Voucher / item_stay`처럼 **슬래시로 나뉜 이름**)는 마스터 세트 **안이 아니라 옆에** 독립 마스터로 놓인다. 그래서 Doc과 똑같이 **마스터 URL만 받으면 서브 마스터는 서브트리에 없다.**

| URL을 어디로 주나 | 서브 | 처리 |
|---|---|---|
| **섹션**(부모) | 형제 마스터 중 이름이 `<마스터명> / …`인 것 → **자동 감지** | 판정표(§4)로 세트 id까지 확정. 질문 없음 |
| **마스터** 직접 + 서브 URL도 받음 | 받은 URL로 probe | 질문 없음 |
| **마스터 + Doc** URL | Doc 시트 안에 서브 노드가 들어 있으면 그 id로 확보(실측: `Order_Voucher` Doc URL로 서브 id 추출 → 서브 URL 요청 없이 진행) | 질문 없음 |
| **마스터** 직접만 | 아래 **인스턴스 신호**로 존재만 감지 | 신호 있으면 **Gate 1에서 서브 URL 요청** |

**인스턴스 신호(실측)** — 세트 frame의 `get_metadata`는 variant `<symbol>`까지만 보여준다. **대표 variant 하나를 한 번 더 probe**하면, 마스터가 쓰는 서브가 `<instance name="<마스터명> / …">`로 나온다.

```
get_metadata(49492:56329) → <frame name="Order_Voucher"> → variant <symbol> 12개만 (서브 안 보임)
get_metadata(49492:56330) → <symbol name="type=stay, ...">
  <instance name="Title_regular"/>                   ← 다른 마스터. 접두가 달라 서브 아님
  <instance name="Order_Voucher / item_stay"/> ×12   ← 서브 신호 (접두 = 마스터명)
```

- **인스턴스 id는 서브 마스터 id가 아니다** — 추출·스토리 `design`에 쓸 수 없다. 그래서 신호만으로 끝내지 않고 **서브 URL을 받는다.**
- 이름 접두가 **마스터명과 같은 인스턴스만** 서브로 본다(`Title_regular` 같은 다른 PUI 인스턴스는 재사용 매핑 대상이지 서브가 아니다).
- **Doc 질문과 합친다(순서).** 마스터 URL만 받으면 Doc도 미감지라 어차피 Doc을 묻는다(§6). 서브 신호가 있으면 그 문항을 **"Doc URL 또는 섹션 URL을 주세요 — 서브(`<마스터명> / …`)도 함께 잡힙니다"**로 묻는다. 받은 노드에서 서브 id가 나오면(실측: `Order_Voucher` Doc URL → 서브 id 추출) **서브 URL은 따로 묻지 않는다.** Doc이 없다고 하거나 받은 노드에도 서브가 없을 때만 서브 URL 문항(Gate 1 #3-2)을 연다.
- 신호가 없으면 카드에 `서브 미감지 (대표 variant 1개 probe)`로 적고 **묻지 않는다.** variant마다 쓰는 서브가 다를 수 있으니 한계를 카드에 그대로 드러낸다 — 사용자가 Gate 1에서 Other로 URL을 보탤 수 있다.

## 6-3. componentGroup — 섹션 이름, 같은 한계

스토리 `componentGroup`은 **PDS 섹션 이름**이다(컴포넌트명 아님 → [common/gates.md](../common/gates.md) Q3). 섹션은 마스터의 **부모**라서 Doc·서브와 똑같이 URL 범위에 따라 보이거나 안 보인다.

| URL을 어디로 주나 | componentGroup |
|---|---|
| **섹션**(부모) | probe 루트 `<section name="Goods">` → **자동**. 카드에 `[자동]` |
| **마스터 / Doc** | `get_metadata`는 자식만 보여줘 부모 섹션이 안 보인다 → **미감지.** 카드에 `componentGroup 미감지 (마스터 URL)`로 적고 Gate 2 category 문항에서 함께 확정 |

- 섹션 URL 안내(§1)가 이 값까지 공짜로 준다 — Doc·서브·componentGroup이 한 번에 잡힌다.
- 미감지를 **컴포넌트명으로 메우지 않는다.** 미감지 ≠ 그룹 없음이다(§6과 같은 구조).

---

## 7. 질문 0회로 도출되는 나머지

| 항목 | 도출 방법 |
|---|---|
| 파일 타입 | fileKey 역조회 (§2) |
| 서브 컴포넌트 세트 id | 섹션 URL이면 probe 트리의 부모-자식(§4). 마스터 URL이면 인스턴스 신호로 존재만 감지 → Gate 1에서 URL 요청(§6-2) |
| componentGroup | 섹션 URL이면 `<section name>`(§6-3). 미감지면 Gate 2 category 문항에서 함께 확정 |
| **기존 구현 충돌** | `grep -rnE "1782[-:]2695" src --include=*.stories.tsx` — **nodeId만 있으면 되고 Explore 서브에이전트 불필요, 비용 ~0**. 그래서 Phase 1의 매핑 조사에서 **Phase 0으로 앞당겼다**. 히트하면 Gate 1에 3-way 문항 추가(→ [common/gates.md](../common/gates.md)) |
| 경로 1차(pui인가 아닌가) | `fileKey=pds` + F.M.C. 확정 → PUI 원칙 1 객관적 충족. **비즈니스면 `features`/`apps` 갈림과 그 이름은 도출 불가 → Gate 1 문항**(→ [common/gates.md](../common/gates.md) Q2) |
| 네이밍 추천값 | 마스터명 → PascalCase (variant·상태 토큰 제거) |
| category 추천값 · 배치 폴더 | `src/stories/menu.ts`의 `StoriesMenu.PDS.*`를 읽고 컴포넌트 성격으로. 폴더는 category에서 1:1로 정해진다 |
| 서브 컴포넌트 여부 | Figma 이름이 `Master / sub`처럼 슬래시로 나뉘면 서브 → 마스터 폴더 안 `MasterSub.tsx` |

---

## 8. 확정 카드

```
📋 대상 확정 카드
파일       pds  ← fileKey G08zxeg… (types.ts:10 역조회)          [자동]
대상 노드  29920-137618  <section name="Brand"> = 컨테이너       [자동]
현재 선택  29920:137618 (Figma 선택과 일치 ✓ — 블록이 있을 때만)  [자동]
마스터 후보 ① 1782-2695   Brand_profile  set · Size=medium|small
           ② 58743-48543 Brand_img      set · Shadow=Off|On
Doc        29920-137619 `Card_Brand Doc` — 자동 감지 → 함께 추출 [자동]
서브        없음 (섹션 URL → 형제 마스터 `Brand_profile / …` 0건) [자동]
componentGroup 'Brand'  ← <section name="Brand">                  [자동]
기존 구현   없음 (grep 1782[-:]2695 → 0건)                        [자동]

제안 (Gate 2에서 확정)
  경로 src/pui/dataDisplayCard/brandProfile/  ← 원칙 1: pds + F.M.C. · 폴더는 category 따라감
  이름 BrandProfile
  category DataDisplay(CardType)                                 [추천]
```

**카드 규약** — 상세는 [common/gates.md](../common/gates.md):
- 카드에 오를 자격 = **ⓐ 도구 응답 원문 인용** 또는 **ⓑ 리포지토리 file:line 인용**이 가능한 것. **근거를 못 다는 항목은 카드가 아니라 질문으로 간다.**
- 각 줄에 출처 라벨: `[자동]` / `[추천]` / `[사용자 제공]` / `[호출측 확정]`. **라벨 없는 값은 카드에 못 올린다.**

카드를 제시한 뒤 **🚦Gate 1**(→ [common/gates.md](../common/gates.md))으로 확정받고 Phase 1로 넘어간다.
