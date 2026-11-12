# Phase 1 — 추출 & 설계

> 로드 시점: Phase 1. 게이트는 [common/gates.md](../common/gates.md), 코드화 규칙은 [guide/](../build/pui-generation-guide.md).

Gate 1에서 확정된 마스터(+Doc)를 도구로 추출하고, 재사용 매핑을 조사한 뒤 **🚦Gate 2**로 넘긴다.

```
추출(마스터+Doc+서브) → 재사용 매핑(Explore) → 랜딩·정책 신호 수집 → 🚦Gate 2
```

---

## 1. 추출 도구

Gate 1에서 확정한 `fileKey` + 마스터 `nodeId`로:

| 도구 | 얻는 것 |
|---|---|
| `get_design_context` | 디자인→코드 컨텍스트(레이아웃/구조/스타일) |
| `get_variable_defs` | 디자인 토큰/변수(색상·간격·타이포) — **토큰 "이름"이 핵심**(→ [build/guide/figma-to-css.md](../build/guide/figma-to-css.md) 3-0) |
| `get_screenshot` | **필수. 레이아웃/모양/비율 대조의 ground truth** |

### 스크린샷 교차대조 (필수)

추출 직후 `get_screenshot`을 받아 `get_design_context`(코드 텍스트)와 **반드시 교차 대조**한다. 코드 텍스트만으로는 다음을 오독한다:

- ⓐ **요소 모양** — 원/라운드사각/스트립. 코너 반경을 텍스트로 추정하면 타원·알약화가 난다(→ [build/guide/figma-to-css.md](../build/guide/figma-to-css.md) 3-6 ⓒ)
- ⓑ **상대 비율·정렬** — 형제 아이템 폭이 균일한지
- ⓒ **프레임 폭이 "고정 px 캔버스"인지** — 그렇다면 절대값 복사 금지, 반응형 변환(→ 3-6 ⓐ)
- ⓓ **`mask-*`/`maskImage`/`carousel 시 mask` 같은 마스크·스크롤 어포던스 래퍼** — 캐러셀을 `children`으로 단순화하더라도 이 마스크를 버리지 말고 코드로 이관한다(실제 실패 사례: 페이드 마스크 누락). 마스크의 **동적 노출 정책**은 Figma에 없으므로 Gate 2에서 확인(→ 3-8)

### MCP가 흘리는 속성 체크리스트 (필수)

`get_design_context`는 **요약·가공된 결과**다. 아래 속성들은 원본 노드에 있어도 컨텍스트에서 빠지거나 뭉개져 나오는 것들이다. 추출 후 이 표를 훑어 **"이 정보가 내 손에 있나"를 항목별로 판정**한다.

| 속성 | 확인할 것 | 놓치면 생기는 결함 | 판정 수단 |
|---|---|---|---|
| 캐러셀 마스크 | 가장자리 페이드/클리핑 유무 | gradient mask 미구현 | 스크린샷 |
| 정렬 모드 | main/cross축 정렬(center·flex-start) | 아이템 적을 때 center vs 넘칠 때 flex-start 규칙 누락 | 스크린샷(정적) + **Gate 2**(개수별 규칙) |
| 아이템 간격 | gap 수치 | gap 오류 | `get_design_context` |
| 패딩 | 상하좌우 여백 | 여백 불일치 | `get_design_context` |
| 오버플로우 | 넘친 콘텐츠가 잘리는지 | `overflow: hidden` 누락 | 스크린샷 |
| 고정 크기 vs 채우기 | 고정 px / 남는 폭 채움 / 콘텐츠 맞춤 | 반응형 크기 규칙 오류 | 스크린샷(형제 폭 균일성) + **Gate 2** |
| border/stroke | 선 두께·점선 패턴 | 점선 테두리 스타일 누락 | 스크린샷 |
| 텍스트 말줄임 | 몇 줄에서 자르는지, 자르긴 하는지 | 말줄임 미구현 | **Gate 2** (정적 스크린샷으로 판정 불가) |

**판정 규칙:**

1. `get_design_context`에 값이 명시돼 있으면 그대로 쓴다.
2. 없으면 `get_screenshot`으로 **육안 확인**한다 — 위 표의 "판정 수단"이 스크린샷인 항목은 여기서 결론이 난다.
3. **스크린샷으로도 판정이 안 서면 추정하지 말고 Gate 2에서 사용자에게 질문한다.** 특히 아래는 정적 이미지 한 장으로는 원리적으로 알 수 없다:
   - 아이템 **개수에 따라 바뀌는** 정렬(적을 땐 center, 넘칠 땐 flex-start)
   - **말줄임 라인 수**와 발동 조건
   - 마스크의 **동적 노출 정책**(스크롤 끝에서 사라지는지 등 → 3-8)
4. 서브 컴포넌트도 variant별로 같은 표를 적용한다.
5. 판정 결과를 설계 노트에 반영한다.

**실측 실패 사례:**
- `Order_Voucher` 런: `get_design_context`만 믿고 추출 → 마스크 누락, 정렬 규칙 누락, 아이템 크기 규칙 부정확, 말줄임 미반영. 앞 세 개는 **스크린샷 한 장이면 잡혔고**, 말줄임은 Gate 2에서 물었어야 했다.

---

## 2. 서브 컴포넌트 — 트리에서 확정한다 (질문 없음)

PDS는 루트 안의 재사용 부품을 **독립 마스터 컴포넌트 세트로 분리**해 두는 경우가 많다(이름 `<마스터> / <서브>`, 마스터 옆에 형제로 배치). 코드도 마스터 폴더 안에 `MasterSub.tsx`로 나눈다.

**서브 URL·세트 id는 Phase 0에서 확보한다**(섹션 URL이면 자동, 마스터 URL이면 인스턴스 신호 → Gate 1에서 요청 → [intake.md](intake.md) §6-2). 받은 노드에 §4 판정표를 재적용해 정확히 읽는다:

```
<frame id="1782:2695" name="Brand_profile">     ← 세트 id = 이 frame
   <symbol id="225:413"   name="Size=medium"/>  ← variant
   <symbol id="1761:2652" name="Size=small"/>   ← variant
```

- **세트 id = variant `<symbol>`의 부모 `<frame>` id.** 트리에 그대로 있다.
- **variant symbol id**는 **정밀 추출용**으로 쓴다 — 그 id로 `get_design_context`/`get_variable_defs`를 **서브 단위로 다시 호출**해 레이아웃·변수·상태별 variant를 정확히 뜬다(루트 한 번 추출로는 서브 경계가 뭉개진다).
- **스토리 `design` 링크에는 세트 id를 dash 포맷으로 박는다.** variant에 대응하는 스토리는 그 variant symbol id를 story 단위로 추가 연결한다.
- **variant 배치(구역·행·열)를 마스터 실측에 기록한다** — 같은 트리의 symbol `x`·`y`로 디자이너가 나눈 구역(y 묶음)과 행·열 순서를 읽어 적는다. 스토리 순서·이름의 근거다(→ [build/guide/structure.md](../build/guide/structure.md) 4번 「스토리 순서·이름 = Figma 배치」).

> 🚫 **폐기된 규칙**: *"세트 id는 자동 도출 불가 → variant ±1 추정 → 후보를 사용자에게 확인"*. 반증됐다 — 실측에서 세트 `1782:2695`의 자식이 `225:413`으로 **인접하지 않았다**. 트리 부모-자식이 정답이고, **id 확인 질문은 하지 않는다**(→ [common/gates.md](../common/gates.md) 아카이브 #6·#7).

**서브 분리 여부는 여전히 설계 판단** → Gate 2 Q4에서 확정한다: ⓐ 각각 별도 파일로 분리 ⓑ 일부만 ⓒ 분리 없이 루트 한 파일. 파일 구성은 `components/{Name}{Sub}.tsx`, barrel은 형제 관례를 따른다.

**먼저 Code Connect·디자인시스템 매핑을 시도한다** — `get_code_connect_map`/`get_code_connect_suggestions`·`search_design_system`으로 서브가 이미 코드/라이브러리에 매핑돼 있으면 **그 컴포넌트를 재사용**하고 신규 생성하지 않는다.

---

## 3. Doc 노드 추출 — 행동 규칙 수집

Gate 1에서 Doc이 확정됐으면 **함께 추출**한다. Doc 시트는 텍스트 주석 위주라 `get_screenshot`(시각) + `get_metadata`(**텍스트 노드명에 정책이 그대로 박혀 있다**)가 핵심이다.

**마스터(정적 모양) + Doc(행동 규칙) = 완성.** 마스터만 보면 pressed·overflow 같은 정책이 누락된다.

뽑아서 Phase 2에 반영할 것:

| 종류 | 예 (실측: `Card_Brand Doc`) | 코드화 |
|---|---|---|
| **Interaction/Pressed** | `overlay: gray8 (pressed_media)`, `Profile 영역 터치 (live) scale down 96%` | `theme.color.states.*` 오버레이(`:active`) → [build/guide/composition.md](../build/guide/composition.md) 3-4 |
| **Overflow/제약** | "주소 최대 3줄, 초과 시 말줄임, Height 고정" | `theme.mixin.multilineEllipsis` + 슬롯 계산 → [build/guide/figma-to-css.md](../build/guide/figma-to-css.md) 3-3-1 |
| **시각 스펙** | `Shadow ios = 12 aos = 8dp`, `Image ratio 1:1 fill`, `Stroke 0.5`, `BG color white_varient_2(surface_high)` | 토큰 매핑 → [build/guide/figma-to-css.md](../build/guide/figma-to-css.md) 3-0 / 3-6 |
| **Anatomy** | 파트 네이밍(Container/Address/info) | 클래스명·구조 검증 |
| **Interaction 신호(랜딩 후보)** | `👆🏼`, 화살표, Pressed 오버레이 | **Gate 2 Q1 랜딩 추론의 입력** — Figma엔 랜딩 자체가 없으므로 이 신호를 모아 넘긴다 |
| **a11y/기타** | role·라벨·키보드 규칙 | 시맨틱 역할 판정의 입력 (아래) |

### 시맨틱 역할 판정 → 설계 노트 (Gate 2 전)

컨벤션 「시맨틱」은 **"PUI는 prop을 열고 값은 도메인이 정한다"**다. 그런데 **어떤 prop을 열지**는 Props 구조를 바꾸는 설계 결정이라 생성 뒤에 정하면 늦다(실측: 쿠폰명을 제목으로 볼지가 최종 보고에서야 [권장]으로 나왔다). 파트마다 아래를 판정해 설계 노트에 적는다.

| 판정 | 결과 → Props 설계 |
|---|---|
| **제목인가** — 섹션·카드의 이름 역할을 하는 텍스트인가 | 제목 → 헤딩 태그 prop(`titleIs`) 열기 / 라벨 → 일반 텍스트 |
| **조작 요소인가** — 탭·입력이 있는가(랜딩 신호와 함께 본다) | 이동 `<a>`(`Action`) · 클릭 `<button>` · 입력 `<input>` / 표시 전용이면 `div` 유지 |
| **이미지·아이콘·도형이 의미를 전하나** — 빈 슬롯·플레이스홀더(예: 미사용 점선 원)·구분선·배경 장식 같은 **도형도 포함** | 의미 → `alt`/`aria-label` prop / 장식 → `alt=""`·`aria-hidden` 고정. 빈 슬롯처럼 개수·상태 정보를 담는 도형은 "장식인가, 상태를 읽혀야 하나"를 여기서 정한다(실측: 미사용 점선 원의 낭독 여부가 최종 보고에서야 나왔다) |
| **상태를 전달해야 하나** — 선택·켜짐·소진 등을 색으로만 구분하는가 | role + `aria-*` 상태, 또는 텍스트 라벨로 전달 |

- Figma·Doc에서 **결론이 나면 카드에 근거와 함께 적고 묻지 않는다.** 애매한 것만 Gate 2 문항으로 올린다(→ [common/gates.md](../common/gates.md) Gate 2 문항 5).

### 외부 표기 정책 신호 → 정책문서 인테이크

Doc/마스터에 🔗·"정책문서/가이드/UX라이팅/날짜·시간 표기/통화 표기" 같은 **외부 문서 링크**가 박혀 있으면(예: `날짜/시간 표기 방식은 UX라이팅 🔗 날짜/시간 정책문서에 따라 표기됩니다`), 그 **표기 규칙은 Figma에 없고 별도 정책문서에 종속**된다. 추정으로 표기 로직을 지어내지 말 것.

1. 감지한 신호를 그대로 인용하며 **"이 표기는 외부 정책문서에 종속된다"**고 고지한다.
2. **Gate 2의 여유 슬롯**에서 `AskUserQuestion`으로 "정책문서(Notion/Figma 링크)나 규칙 내용을 주실 수 있나요?"를 묻는다(링크·내용은 Other 자유입력).
   - **주면** → 컴포넌트 로컬 유틸 단일원본 구현 근거로 삼는다
   - **없으면** → 임의 추정 금지. 골격 + `// TODO: 정책문서 반영` 주석을 남기고 오버라이드 props로 주입 가능하게 열어 둔다
3. 어느 경우든 **하이브리드 패턴**(원천 데이터 prop + 내부 유틸 호출 + 오버라이드 prop)으로 코드화 → [build/guide/policy.md](../build/guide/policy.md) 3-5. "오버라이드 prop만" 받는 설계는 금지.

---

## 4. 재사용 매핑 조사

**먼저 Code Connect 확인**: `get_code_connect_suggestions`/`get_code_connect_map`(등록된 노드↔코드 매핑), `search_design_system`(라이브러리 대응 컴포넌트).

그다음 **`Task`로 `Explore` 서브에이전트를 호출**해 `src/pui/`에서 재사용 후보를 병렬 조사(메인 컨텍스트 오염 방지):

> 조사 지시: "다음 Figma 요소들 `[버튼/뱃지/...]`에 대응하는 기존 컴포넌트를 `src/pui/*/*.stories.tsx`에서 찾아라. 각 스토리의 `defineMeta` `design` 배열에 박힌 Figma nodeId와 대조하면 역방향 매핑이 가능하다(`src/pui/_utils/meta.ts`·`_utils/types.ts` 참고). 컴포넌트명·경로·props를 보고하라."

> ℹ️ **"마스터 nodeId가 기존 stories에 박혀 있는지"는 여기서 조사하지 않는다** — Phase 0의 grep이 이미 했다(비용 ~0). Explore는 **부품 매핑**에만 쓴다.

### 🚨 Explore 보고는 후보지 근거가 아니다 — 실측 대조 필수 (강제)

**서브에이전트의 매핑 추천을 그대로 표에 올리지 말 것.** Explore는 "비슷해 보이는 컴포넌트"를 잘 찾지만 **스펙이 맞는지는 검증하지 않는다.** 표는 Gate 2로 사용자 앞에 나가고 그대로 계획서·코드가 되므로, 여기서 틀리면 Phase 2까지 산다.

**실측 실패 2건 (같은 런에서 동시 발생)**:

| 요소 | Explore 추천 | 실제 정답 | 무엇을 놓쳤나 |
|---|---|---|---|
| `사용` 버튼 | `ButtonBubble size="small"` (검정 pill) | `shape="squircle" size="medium"` | Figma는 `h-40`·`rounded-8`·`px-16` = squircle medium. **"pill"은 저해상도 스크린샷 인상**이었고, `button.ts`를 읽으면 `.is-small`=3.2rem이라 애초에 안 맞았다 |
| 헤더 | `TitleSub` | `TitleSection` | `TitleSub .title`=`fontType.medium`(15px)인데 마스터는 **18px Bold**. `TitleSection .title`=`largeB`(18)가 정답 |

→ **각 행은 아래 대조를 마친 뒤에만 표에 오른다:**

```
Figma 실측값 (get_design_context/get_variable_defs 원문)  ↔  대상 컴포넌트의 실제 CSS (file:line)
```

| 대조 축 | 확인법 |
|---|---|
| **폰트** | 마스터의 스타일명(`Small_b`·`Large_b`)/px ↔ 대상의 size css `font:` 토큰을 grep. **`Small_b`(14 Bold) vs `small`(14 Regular)는 다르다** |
| **치수** | 마스터 `h-[40px]`·`px-16` ↔ 대상 size css의 `height`·`padding` |
| **모양** | 마스터 `rounded-[...radius_8]`/노드명(`Button_Squircle`) ↔ 대상 shape css의 `border-radius` |
| **색** | `get_variable_defs`의 토큰 **이름** ↔ 대상 variant css의 `theme.color.*` |

> 이 대조 규칙은 [build/guide/composition.md](../build/guide/composition.md) 3-7-1 ⓐ에 이미 있었지만 **Phase 2 가이드에 있어 늦게 발동했다.** 매핑 표를 만드는 건 Phase 1이므로 **여기서 미리 건다.** 규칙이 없어서가 아니라 타이밍 때문에 틀렸다.

**대조가 어긋나면** → 다른 컴포넌트를 찾거나, 그대로 쓰되 delta만 오버라이드할지 판단한다(→ 3-7-1 ⓐ). **"비슷하니 맞겠지"로 넘기지 않는다.**

### 결과 표 (Gate 2 카드에 포함)

**근거 열은 선택이 아니라 필수다** — [common/gates.md](../common/gates.md) 카드 규약(ⓐ도구 원문 / ⓑfile:line)이 그대로 적용된다.

| Figma 요소 | 처리 | 매핑 대상 | 검증 근거 (실측 ↔ 코드) |
|-----------|------|----------|----------------------|
| 사용 버튼 | ♻️ 재사용 | `ButtonBubble shape="squircle" size="medium"` | h40·r8·px16·14Bold ↔ `button.ts:71,94,98` |
| 헤더 | ♻️ 재사용 | `TitleSection` | 18Bold/12 ↔ `TitleSection.tsx:134,141` |
| 가격 뱃지 | 🆕 신규 | (경로별 정책 따라 생성) | 대응 pui 없음 (grep 근거) |

**재사용 우선.** 공통 UI인데 유사 컴포넌트가 이미 있으면 신규 대신 **확장/variant를 제안**한다(pui 공식 목표).

---

## 5. → 🚦 Gate 2

랜딩 표 · 네이밍 · category · 서브 분리 · (조건부)정책문서·시맨틱 역할을 **한 호출에 배칭**해 확정받는다 → [common/gates.md](../common/gates.md).

**승인 전 코드 생성 금지.**
