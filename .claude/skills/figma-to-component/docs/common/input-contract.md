# 스킬 진입 계약 (input contract)

> **이 문서의 독자는 다르다** — `figma-to-component`를 **호출하는 쪽**(다른 스킬·사람)이 읽는다. f2c 자신은 Phase 0 진입 시 참조한다.
>
> 이 계약의 **단일 원본은 이 문서**다. 호출측 문서는 여기를 **링크만** 하고 규약을 복사하지 않는다.

## 왜 필요한가

호출측은 인테이크에서 **이미 Figma 구조를 읽고 경로를 승인받은 채로** f2c에 도달하는데, 그 값을 넘길 규약이 없어 f2c가 처음부터 다시 물었다. 계약의 목적은 **이미 확정된 값의 재질문을 없애는 것**이다.

---

## 인자

```
/figma-to-component <figma-url>

  # ── 확정값 — 호출측이 사용자 승인 게이트를 통과시킨 값 → f2c가 재질문하지 않는다
  --path=pui | features/<featureName> | apps/<domain>
  --doc=<figma-url> | none
  --name=<PascalCase>
  --category=<StoriesMenu.PDS.* 키>

  # ── 제안값 — 호출측이 읽거나 추론만 한 값 → pre-fill로만, 확정은 f2c가 받는다
  --suggest-doc=<figma-url>
  --suggest-name=<PascalCase>

  # ── 실행 옵션 — 게이트 확정값이 아니라 진행 방식
  --verify=measure | manual     # Phase 3 검증 모드. 생략 시 Phase 3 진입 때 묻는다(기본 추천 measure)

  --via=<호출 스킬명> | user
```

`<figma-url>`은 **node-id를 포함한 URL**이어야 한다(`https://www.figma.com/design/<fileKey>/<name>?node-id=1782-2695`). Figma에서 노드 선택 → 우클릭 → **Copy link to selection**.

---

## 확정값 / 제안값 2계층 — 이게 핵심이다

호출측이 *추론한* 값을 "확정"으로 넘기면, **계약이 추측을 확정으로 세탁**해 f2c의 방어 규칙(네이밍·category는 사용자 확정 필수)을 우회한다 — 과거 실패([gates.md](gates.md) 아카이브)를 다른 경로로 재현하는 셈이다. 그래서 **인자 이름 자체로 출처를 강제**한다.

> **호출측 규칙**: 사용자 승인을 받지 않은 값을 `--path`/`--name`/`--category`/`--doc`으로 넘기지 않는다. 추론값은 `--suggest-*`로.
>
> **f2c 규칙**: 확정 인자가 오면 **재질문하지 않되** 확정 카드에 `[호출측 확정]` 라벨로 표기한다(사용자가 반증할 수 있게). `--suggest-*`는 해당 질문의 **첫 옵션(추천값)** 으로 pre-fill하되 **확정은 받는다**.

**애매하면 `--suggest-*`가 정답이다.** Gate 2는 랜딩·category 때문에 **어차피 열린다** — 열린 게이트에 질문 1개를 더하는 비용은 0이다(→ [gates.md](gates.md) 배칭). 배칭이 주는 이득은 "질문을 없애는 것"이 아니라 **"질문을 공짜로 만드는 것"**이다.

---

## f2c의 스킵 대상 — 3출처

f2c는 다음 세 출처에서 온 값을 인테이크에서 **다시 묻지 않는다**:

1. **사용자 메시지** — 사용자가 대화에서 직접 준 값
2. **스킬 인자(확정 계층)** — 위 `--path` 등
3. **probe로 도출된 값** — 파일 타입·마스터·Doc·서브 id·기존 충돌 (→ [plan/intake.md](../plan/intake.md))

---

## 호출측별 가이드

### 다른 스킬·워크플로우

**사용자 승인 게이트를 통과한 값만 확정 인자로 넘긴다.** 흔한 분류:

| 값 | 호출측 상태 | 넘기는 법 |
|---|---|---|
| 대상 경로 | 호출측 계획에서 확정받고 게이트 승인 | ✅ `--path=` (확정) |
| Figma URL·nodeId | 호출측 인테이크가 `get_metadata`로 확보 | ✅ `<url>` (사실) |
| Doc 프레임 | **읽었을 뿐 확정 아님** | ⚠️ `--suggest-doc=` |
| 컴포넌트명 | 승인된 적 없음 | ⚠️ `--suggest-name=` |
| category | 다룬 적 없음 | ❌ 안 넘김 |

호출 예:
```
/figma-to-component <figma-url-with-node-id> \
  --path=pui --suggest-doc=<doc-url> --via=<호출 스킬명>
```

**리뷰 중복 회피**: f2c는 생성 단계에서 **pui/도메인 컨벤션 특화 리뷰**를 자체 수행하고 그 결과를 보고한다(→ [build/review.md](../build/review.md)). 호출측 리뷰는 그 위에 **일반 리뷰**(정확성·재사용·성능)만 얹는다 — 컨벤션 체크를 다시 돌리지 않는다.

### 사람

URL만 주면 된다. `--via`도 생략 가능(기본 `user`).

```
/figma-to-component https://www.figma.com/design/G08zxegRFA3a1kF0ZMCaXa/PDS?node-id=29920-137618
```

> 💡 **섹션 URL을 주면 Doc과 서브 컴포넌트까지 자동으로 잡힌다** — `get_metadata`는 서브트리만 보므로, 마스터를 직접 가리키면 형제인 Doc·서브(`<마스터> / …`)는 감지되지 않아 질문이 는다(→ [plan/intake.md](../plan/intake.md) §6·§6-2). 마스터 URL을 줄 거면 **서브 URL도 함께** 주면 된다.
