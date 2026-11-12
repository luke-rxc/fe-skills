# Figma MCP 연동 안내

> 참고: 서버 등록은 fe-skills의 `fe-mobile` 플러그인에 포함되어 있습니다. 사용자는 **OAuth 인증만** 직접 수행하면 됩니다. (인증 토큰은 사용자별 로컬에 저장되며 repo에 공유되지 않습니다.)

## 안내 메시지

Figma 연동을 위해 OAuth 인증이 필요합니다. 인증은 인터랙티브 로그인이라 직접 수행해주셔야 합니다. 아래 절차를 따라주세요:

### 1단계: 세션에서 `/mcp` 실행

Claude Code 입력창에 `/mcp` 를 입력하고 목록에서 **figma** 를 선택합니다.

> figma 항목(플러그인 `fe-mobile` 소속)이 보이지 않으면 플러그인이 설치·활성화되지 않은 것입니다. `claude plugin install fe-mobile@fe-skills -s project` 후 세션을 재시작하세요.

### 2단계: 인증

1. **Authenticate** 선택
2. 브라우저가 열리면 **Allow Access** 클릭 (Figma 계정 로그인 필요)
3. "Authentication successful. Connected to figma" 메시지 확인

### 3단계: 시트/플랜 확인 (필요 시)

- Remote MCP 서버(`https://mcp.figma.com/mcp`)는 모든 시트/플랜에서 사용 가능합니다.
- 코드 추출(`get_design_context`)과 디자인 토큰(`get_variable_defs`)은 대상 파일에 대한 보기 권한이 있어야 동작합니다.

### 4단계: 재요청

인증 완료 후 Figma node-id 또는 URL과 함께 다시 요청해주세요.

---

## 참고: 연결 방식

- **전송 방식**: HTTP (Remote MCP, OAuth 인증)
- **엔드포인트**: `https://mcp.figma.com/mcp`
- **입력**: Remote 서버는 현재 선택(selection) 기반이 아니라 **프레임/레이어 링크(node-id 또는 URL)** 로 컨텍스트를 추출합니다. 따라서 요청 시 대상 노드 링크가 반드시 필요합니다.
