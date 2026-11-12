# 공통 UI(pui) 코드 작성 가이드 — Figma 생성 시 부가 컨벤션 (인덱스)

> **기본 vs 부가 — 두 문서의 관계**
> - **기본(baseline)**: `src/pui`를 생성하든 수정하든, `figma-to-component` 스킬을 쓰든 안 쓰든 **항상** 지켜야 할 규칙은 [`rules/pui-code-convention.md`](../../../../rules/pui-code-convention.md)다(세션에 자동 로드, 단일 기준). ForwardRef·Props 선언 순서·이벤트 핸들러 시그니처·styled 변수 선언·import/export·key 규칙 등. **여기서 중복하지 않는다.**
> - **부가(additional)**: **아래 `guide/` 4종**이 그 기본 위에 **Figma 디자인 → 코드 생성 워크플로에서만** 추가로 필요한 내용을 담는다 — 코딩 골격·예시, Figma 값(색상/폰트/간격) → 토큰 매핑, 이미지·아이콘·액션 사용법, 조합 패턴, 실패 사례 등. 생성 흐름 밖(단순 수정 등)에서는 기본만으로 충분하다.
> - 전사 일반 코드 컨벤션(alias·JSDoc·any 최소화 등) → **프로젝트 코드 컨벤션**(프로젝트 저장소 `CLAUDE.md`/`AGENTS.md`) (중복 금지, 그쪽을 따른다)
> - pui **정책**(이게 pui인가·어디 만드나·무엇이 필수인가·검증) → [pui-policy.md](pui-policy.md)

## 라우팅 — 지금 하는 일에 맞는 문서만 읽는다

이 가이드는 **로드 시점**으로 4분할되어 있다. Phase 2(코드 생성)에서 아래 표대로 필요한 것만 Read한다.

| 문서 | 담는 것 | 언제 |
|---|---|---|
| [guide/structure.md](guide/structure.md) | 1 파일/폴더 구성 · 2 컴포넌트 골격(forwardRef/Props/styled) · 4 스토리(`defineMeta`) | **항상** |
| [guide/figma-to-css.md](guide/figma-to-css.md) | **codegen이 변환의 입력(강제)** · 3 토큰 · 3-0 색 변수→토큰 · 3-3 수치 grep 도출 · 3-6 치수/간격/radius/반응형 · 3-8 캐러셀 마스크 | **항상** — Figma 값을 코드로 옮기는 모든 순간 |
| [guide/composition.md](guide/composition.md) | 3-1 이미지 · 3-2 아이콘 · 3-4 랜딩/`Action` · 3-7 자식 pui 조합 · 3-7-1 오버라이드 · 3-7-2 자식 목록 렌더 | **거의 항상** — 기존 pui를 하나라도 쓰면 |
| [guide/policy.md](guide/policy.md) | 3-5 외부 표기 정책 하이브리드 · 3-5-1 상태는 파생하라 | **조건부** — 날짜/통화/상태 문구 표기가 있을 때 |

> **섹션 번호(3-0·3-4·3-6 …)는 분할 전 체계를 그대로 유지한다** — 다른 문서·실패사례 아카이브가 그 번호로 참조하므로 파일만 바뀌고 번호는 안 바뀐다. 인용은 `guide/figma-to-css.md 3-0` 형태로.

## 어디에도 안 들어간 것

- **생성 직전 체크 · 컨벤션 준수 검사** → [review.md](review.md) (Phase 2 리뷰에서 쓰는 체크리스트로 승격)
- **PUI Convention 세부 규칙**(ForwardRef·Props 선언 순서·이벤트 핸들러 시그니처·styled 변수 선언·import/export·key) → **PUI 코드 컨벤션**이 단일 기준. `src/pui` 파일을 다루면 세션에 자동 로드되므로(paths 스코프 rule) 생성이든 스킬 없이 하는 수정이든 항상 적용된다.

## 모든 문서에 공통인 것

> **실전 디테일**: 생성 직전 **같은 성격의 형제 컴포넌트 1개를 반드시 Read**해 네이밍·스타일링·export를 그대로 맞춘다. 아래 패턴들은 그 요약일 뿐, **최종 기준은 실제 코드다.**

대표 참고: 단순형 `src/pui/button/`, 중간형 `src/pui/contentCard/`, 복합형 `src/pui/drawer/`·`src/pui/tabs/`.

> ⚠️ **코드 작성의 근거는 `get_design_context`의 codegen이다** — Phase 1의 설계 명세(텍스트 요약)만으로 추정해 짜면 variant가 통째로 누락된다. 강제 규칙·변환 순서·서브에이전트 첨부 데이터는 [guide/figma-to-css.md](guide/figma-to-css.md) "변환의 입력은 codegen이다"가 소유한다.
