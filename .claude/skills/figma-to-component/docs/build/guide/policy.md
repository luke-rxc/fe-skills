# 가이드 — 외부 표기 정책에 종속된 표시값

> 부가 컨벤션 중 **"Figma 밖 정책문서가 정하는 표시값"**. 로드 시점: Phase 2 코드 생성 **조건부** — 날짜/시간·통화·D-day·"공개 예정/종료" 같은 표기가 있거나, Phase 1에서 외부 정책 신호(🔗·"UX라이팅"·"정책문서")를 감지했을 때만.
> 문서 관계·라우팅은 [pui-generation-guide.md](../pui-generation-guide.md).

---

## 3-5. 외부 표기 정책에 종속된 표시값 — 하이브리드(유틸 + 내부 가공 + 오버라이드) (필수)

날짜/시간·통화·D-day·"공개 예정/종료" 문구처럼 **표기 규칙이 외부 정책문서(UX라이팅 등)에 정의된 표시값**은, 컴포넌트가 가공된 문자열(`dateText` 등)만 받게 만들지 말 것. 그러면 도메인마다 포맷이 갈리고, 개발자가 빠뜨리면 **빈 값/불일치**가 난다. PUI Convention("참조 데이터를 내부 가공해 쓰면 대체 props를 제공", "디스플레이 데이터는 내부 가공하되 오버라이드 제공")이 가리키는 정석은 **셋을 모두** 두는 하이브리드다:

1. **정책 로직은 컴포넌트 로컬 유틸로 단일원본화** — 표기 규칙(상태별 분기·포맷)을 **컴포넌트 폴더의 `utils/{name}.ts`(컴포넌트 로컬)** 의 순수 함수로 추출한다([structure.md](structure.md) 1번의 utils 규칙). root `@utils`에 만들지 않는다. 예: `getContentReleaseLabel({ startDate, endDate, now }) → string`. (그 정책이 실제로 여러 도메인에서 재사용되는 단계가 오면 그때 root로 승격하되, 출발은 로컬이다.)
2. **컴포넌트는 원천 데이터(시간 등)를 받아 내부에서 그 유틸을 호출** — `startDate?`/`endDate?`(number) 같은 **원천값 prop**을 받고, 렌더 시 유틸로 가공해 기본 표기한다. → 도메인이 라벨을 안 넘겨도 **정책대로 표기되어 누락이 사라진다**.
3. **오버라이드 prop 제공** — 예외 케이스용 `dateText?`(또는 `dateLabel?`) 를 열어 두되, **기본은 내부 유틸**이고 오버라이드는 있을 때만 우선한다.

```tsx
// 1) 유틸 (단일원본) — src/pui/{category}/{name}/utils/{name}.ts (컴포넌트 로컬)
export const getContentReleaseLabel = ({ startDate, endDate }: {...}) => { /* UX라이팅 정책 */ };

// 2)+3) 컴포넌트: 원천 데이터 prop + 내부 호출 + 오버라이드
export interface CardContentProps ... {
  startDate?: number;   // 원천 데이터(표시·카운트다운 기준)
  dateText?: string;    // 오버라이드(예외 케이스 전용)
}
const label = dateText ?? getContentReleaseLabel({ startDate, endDate });
```

- **금지**: 표시값을 **오버라이드 prop만**(`dateText`만) 받는 설계 — 정책이 도메인으로 새어 나가고 누락 위험이 크다.
- **정책문서가 없으면**: Phase 1의 정책문서 인테이크로 유저에게 요청한다(→ [plan/extraction.md](../../plan/extraction.md)). 끝내 없으면 유틸에 임시 포맷 + `// TODO: 정책문서 반영` 주석을 남기고, **구조(유틸+원천 prop+오버라이드)는 그대로 유지**한다(나중에 유틸 내부만 갈아끼우면 됨).

### 3-5-1. "상태"는 주입받지 말고 파생하라 — 런타임 파생 상태 vs 호출자-사실 변형 (필수)

표기에 따라붙는 **상태**(공개 예정 / 진행중 / 종료, D-day, "오늘", 신규 N일 배지 등)는 **현재 시각 등 런타임 정보로 결정**된다. 이걸 `type: 'scheduled' | 'live' | 'ended'` 같은 **enum prop으로 호출자에게 주입받으면 안 된다**(도메인마다 비교 로직이 갈리고, 시간이 흘러 상태가 바뀌어도 prop은 그대로라 틀어진다 — Figma Doc의 variant 이름을 그대로 prop으로 옮기는 흔한 실수).

**변형을 두 종류로 구분한다:**
| 종류 | 결정 주체 | 처리 |
|---|---|---|
| **호출자-사실 변형** | 호출 시점에 이미 확정 (size, 콘텐츠 종류=라이브/스토리, 노출 영역 등) | **prop으로 받는다** |
| **런타임 파생 상태** | 현재 시각 등 외부 상태로 결정 (예정/진행/종료, D-day, 오늘) | **prop 금지 — 원천 데이터(타임스탬프)로부터 유틸 내부에서 파생** |

- **원천 데이터만 받는다**: `startDate?`/`endDate?`(number) 같은 **타임스탬프**를 받고, 상태(예정/진행/종료)는 **유틸이 `now`와 비교해 결정**한다.
- **`now`는 유틸 인자로 주입 가능하게**(기본 `Date.now()`) — 스토리/테스트에서 특정 시점을 재현하려면 필요(`getContentReleaseLabel({ startDate, endDate, now = Date.now() })`).
- **시각으로 결정 안 되는 분기는 prop**: 예) "라이브 예정"과 "공개 예정"의 갈림은 *시각*이 아니라 *콘텐츠가 라이브인가*라는 사실 → `live?: boolean`(또는 종류 enum)으로 받고, **예정/진행/종료(언제)** 는 타임스탬프로 파생. 둘을 한 enum에 섞지 않는다.
- **오버라이드(`dateText?`)는 그대로 유지**(예외 케이스).

```tsx
// 유틸이 now와 비교해 상태까지 파생 (호출자는 상태를 모른다)
export const getContentReleaseLabel = (
  { startDate, endDate, live = false, now = Date.now() }:
  { startDate: number; endDate?: number; live?: boolean; now?: number },
): string => {
  if (now < startDate) return live ? `${fmtDateTime(startDate)} 라이브 예정` : `${fmtDate(startDate)} 공개 예정`;
  if (endDate && now > endDate) return '공개 종료';
  return fmtDateTime(startDate); // 진행중
};
// 컴포넌트 props: 원천 데이터 + 호출자-사실(live) + 오버라이드 — '상태' enum은 없다
// startDate?: number; endDate?: number; live?: boolean; dateText?: string;
const label = dateText ?? (startDate ? getContentReleaseLabel({ startDate, endDate, live }) : '');
```

> 같은 원리로 **종료=disabled 디밍** 같은 *시각 의존 표시 상태*도 가능한 한 원천 데이터에서 파생한다(다만 종료 외 사유로도 비활성화한다면 `disabled` prop도 함께 둔다 — 파생 + 명시 오버라이드 병행).
