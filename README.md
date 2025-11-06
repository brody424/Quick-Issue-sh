# 🚀 Fast GitHub Issue Creator

GitHub 이슈를 빠르게 생성하는 대화형 CLI 도구입니다.

## ✨ 주요 기능

- ✅ GitHub 로그인 상태 자동 확인
- ⭐ 즐겨찾기 Repository 관리
- 🏷️ Label 프리셋으로 빠른 라벨 선택
- 📝 제목만 / 제목+본문 선택 가능
- 📊 최근 생성한 Issue 이력 조회
- ⚙️ 데이터 관리 및 설정

## 📋 사전 요구사항

### 필수
- **GitHub CLI (gh)** - GitHub API 사용

### 선택사항
- **jq** - 이력 조회 및 데이터 관리 기능 (권장)
- **iTerm2** - iTerm에서 실행하려는 경우 (macOS 전용)

### 설치

**macOS:**
```bash
brew install gh
brew install jq  # 선택사항
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install gh
sudo apt install jq  # 선택사항
```

**Linux (Fedora/CentOS):**
```bash
sudo dnf install gh
sudo dnf install jq  # 선택사항
```

## 🎯 사용법

### 1. 스크립트 실행

#### 방법 1: 일반 터미널에서 실행
```bash
cd /Users/brody/Desktop/FastGithubIssue
./create-issue.sh
```

현재 터미널에서 바로 실행됩니다.

#### 방법 2: iTerm 새 윈도우에서 실행 (권장)
```bash
cd /Users/brody/Desktop/FastGithubIssue
./open-in-iterm.sh
```

**`open-in-iterm.sh`의 역할:**
- iTerm이 자동으로 활성화됩니다
- **새로운 윈도우**가 생성되어 작업 공간이 분리됩니다
- 독립적인 환경에서 `create-issue.sh`가 실행됩니다
- 다른 프로그램이나 스크립트에서도 호출 가능합니다

**사용 시나리오:**
- IDE나 다른 도구에서 단축키로 실행하고 싶을 때
- 현재 터미널 세션을 유지하면서 Issue를 생성하고 싶을 때
- 깔끔한 새 윈도우에서 작업하고 싶을 때

**예시:**
```bash
# Raycast, Alfred 등의 스크립트 실행 도구에서
/Users/brody/Desktop/FastGithubIssue/open-in-iterm.sh

# 다른 프로그램에서 호출
open -a Terminal /Users/brody/Desktop/FastGithubIssue/open-in-iterm.sh
```

### 2. 메인 메뉴

```
========================================
   GitHub Issue 빠른 생성 도구
========================================

1. 🚀 Issue 빠르게 등록
2. ⭐ 즐겨찾기 Repository 관리
3. 🏷️ Label 프리셋 관리
4. 📊 최근 사용 이력 보기
5. ⚙️ 설정
0. 종료

선택하세요:
```

## 📖 기능 상세 가이드

### 🚀 1. Issue 빠르게 등록

개발 중 떠오른 아이디어를 즉시 Issue로 등록할 수 있습니다.

**플로우:**
1. **Issue 타입 선택**
   - `1. 제목만` - 빠르게 제목만 입력
   - `2. 제목 + 본문` - 제목과 본문을 함께 작성

2. **Repository 선택**
   - 즐겨찾기 Repository가 먼저 표시됩니다
   - 검색어로 Repository 필터링 가능
   - 번호를 입력하여 선택

3. **Label 선택**
   - 저장된 Label 프리셋 사용 가능 (`p1`, `p2`, ...)
   - 개별 Label 선택 가능 (쉼표로 구분: `1,3,5`)
   - `0` 또는 엔터로 Label 없이 진행

4. **제목 입력**
   - Issue 제목을 입력합니다

5. **본문 입력** (제목+본문 선택 시)
   - 여러 줄 입력 가능
   - 완료하려면 `Ctrl+D`를 누릅니다

6. **Issue 생성 완료!**
   - Issue URL이 표시됩니다
   - 자동으로 이력에 기록됩니다

**예시:**
```
Issue 생성 방식을 선택하세요:
  1. 제목만
  2. 제목 + 본문

선택: 1

📦 Repository 선택

⭐ 즐겨찾기 Repository:
  1. username/mytime-server

검색어를 입력하거나 엔터를 눌러 전체 목록 보기:
>

번호를 선택하세요: 1
✅ 선택된 Repository: username/mytime-server

🏷️ Label 선택
저장된 프리셋:
  p1. bug,high-priority

사용 가능한 Labels:
  0. Label 없이 진행
  1. bug
  2. enhancement
  3. documentation

여러 개 선택 가능 (쉼표로 구분, 예: 1,3,5 또는 p1):
> p1
✅ 선택된 프리셋: bug,high-priority

📝 Issue 제목 입력
> JWT 토큰 만료 시 자동 갱신 기능 추가

🚀 Issue 생성 중...
✅ Issue가 성공적으로 생성되었습니다!
🔗 https://github.com/username/mytime-server/issues/42
```

### ⭐ 2. 즐겨찾기 Repository 관리

자주 사용하는 Repository를 즐겨찾기에 등록하여 빠르게 접근할 수 있습니다.

**서브메뉴:**
- `1. 즐겨찾기 추가` - Repository 검색 후 추가
- `2. 즐겨찾기 삭제` - 등록된 즐겨찾기 제거
- `3. 즐겨찾기 목록 보기` - 현재 등록된 목록 확인

### 🏷️ 3. Label 프리셋 관리

자주 사용하는 Label 조합을 프리셋으로 저장할 수 있습니다.

**프리셋 예시:**
- `bug,high-priority` - 긴급 버그
- `enhancement,feature` - 기능 개선
- `documentation` - 문서 작업

**서브메뉴:**
- `1. 프리셋 추가` - 새로운 프리셋 등록
- `2. 프리셋 삭제` - 기존 프리셋 제거
- `3. 프리셋 목록 보기` - 저장된 프리셋 확인

**프리셋 형식:**
```
Label1,Label2,Label3
```
쉼표로 구분하여 여러 Label을 하나의 프리셋으로 저장합니다.

### 📊 4. 최근 사용 이력

최근 생성한 Issue 10개를 조회할 수 있습니다.

**표시 정보:**
- 생성 날짜/시간
- Repository 이름
- Issue 제목
- Issue URL

**예시:**
```
📊 최근 사용 이력

최근 생성한 Issue:

[2025-11-05 17:30]
  Repository: username/mytime-server
  Title: JWT 토큰 만료 시 자동 갱신 기능 추가
  🔗 https://github.com/username/mytime-server/issues/42

[2025-11-05 15:20]
  Repository: username/frontend-app
  Title: 다크모드 UI 개선
  🔗 https://github.com/username/frontend-app/issues/15
```

**참고:** 이력 기능은 `jq`가 설치되어 있어야 사용 가능합니다.

### ⚙️ 5. 설정

**서브메뉴:**
- `1. 데이터 초기화` - 모든 설정 및 이력 삭제
- `2. GitHub CLI 재로그인` - 계정 변경 시 사용

## 📁 프로젝트 구조

```
FastGithubIssue/
├── create-issue.sh      # 메인 스크립트 - Issue 생성 도구
├── open-in-iterm.sh     # iTerm Wrapper - 새 윈도우에서 실행
└── README.md            # 사용 설명서
```

**파일 설명:**
- **`create-issue.sh`**: GitHub Issue를 생성하는 메인 대화형 스크립트
- **`open-in-iterm.sh`**: iTerm 새 윈도우에서 `create-issue.sh`를 실행하는 Wrapper
- **`README.md`**: 사용 가이드 및 문서

## 💾 데이터 저장 위치

모든 설정 및 이력은 다음 디렉토리에 저장됩니다:

```
~/.fastgithub-issue/
├── favorites.json       # 즐겨찾기 Repository
├── label-presets.json   # Label 프리셋
├── history.json         # Issue 생성 이력 (최근 20개)
└── config.json          # 기타 설정
```

## 💡 사용 팁

### 빠른 워크플로우

**개발 중 Issue 등록 (iTerm 사용):**
1. `./open-in-iterm.sh` 실행 → 새 iTerm 윈도우 생성
2. `1` (Issue 등록)
3. `1` (제목만)
4. 즐겨찾기에서 Repository 선택
5. `p1` (자주 쓰는 프리셋)
6. 제목 입력
7. 완료!

**일반 터미널에서 빠른 등록:**
1. `./create-issue.sh` 실행
2. 위와 동일한 플로우

**초기 설정 권장사항:**
1. 자주 사용하는 Repository를 즐겨찾기에 등록
2. 자주 사용하는 Label 조합을 프리셋으로 등록
3. Raycast, Alfred 등의 도구에 `open-in-iterm.sh` 단축키 등록
4. 이후에는 빠르게 Issue 생성 가능

### iTerm 통합 활용

**Raycast에 등록하기:**
1. Raycast → Script Commands
2. 새 스크립트 추가: `/Users/brody/Desktop/FastGithubIssue/open-in-iterm.sh`
3. 단축키 설정 (예: `⌘⇧I`)
4. 어디서든 단축키로 Issue 생성 가능

**Alfred Workflow에 추가:**
1. Alfred → Workflows → 새 Workflow 생성
2. Hotkey Trigger 추가 → Run Script 액션 연결
3. Script: `/Users/brody/Desktop/FastGithubIssue/open-in-iterm.sh`
4. Hotkey 설정 완료

### Label 프리셋 활용

**시나리오별 프리셋 예시:**
```
p1: bug,urgent          # 긴급 버그
p2: enhancement,feature # 기능 추가
p3: bug,low-priority    # 일반 버그
p4: documentation       # 문서
p5: refactor,technical-debt  # 리팩토링
```

### 본문 작성 팁

제목+본문 모드에서 여러 줄 작성 후 완료:
```
📄 Issue 본문 입력 (완료하려면 빈 줄에서 Ctrl+D):
> ## 문제 상황
> JWT 토큰이 만료되면 사용자가 로그아웃됩니다.
>
> ## 해결 방안
> Refresh token을 활용한 자동 갱신
> [Ctrl+D 입력]
```

## 🐛 문제 해결

### "gh: command not found"
GitHub CLI가 설치되어 있지 않습니다.
```bash
brew install gh  # macOS
```

### 로그인 실패
수동으로 로그인 시도:
```bash
gh auth login
```

### Repository 목록이 비어있음
- GitHub에 접근 권한이 있는 Repository가 있는지 확인
- `gh repo list` 명령어로 직접 확인

### 이력 기능이 작동하지 않음
`jq`를 설치해야 합니다:
```bash
brew install jq  # macOS
```

### iTerm이 실행되지 않음
**증상:** `open-in-iterm.sh` 실행 시 아무 반응이 없음

**해결 방법:**
1. iTerm2가 설치되어 있는지 확인:
   ```bash
   ls /Applications/iTerm.app
   ```
2. iTerm2가 없다면 설치:
   ```bash
   brew install --cask iterm2
   ```
3. 실행 권한 확인:
   ```bash
   chmod +x /Users/brody/Desktop/FastGithubIssue/open-in-iterm.sh
   ```

### iTerm에서 기존 탭에 열림 (새 윈도우가 안 생김)
**원인:** iTerm 설정 문제

**해결 방법:**
- `open-in-iterm.sh`가 `create window with default profile`을 사용하므로 항상 새 윈도우가 생성되어야 합니다
- 만약 기존 탭에 열린다면 iTerm 환경설정 확인:
  - iTerm2 → Preferences → General → Startup → Window restoration policy

### 다른 프로그램에서 실행 시 권한 오류
**증상:** "Permission denied" 오류

**해결 방법:**
```bash
chmod +x /Users/brody/Desktop/FastGithubIssue/open-in-iterm.sh
chmod +x /Users/brody/Desktop/FastGithubIssue/create-issue.sh
```

### 데이터 초기화
모든 설정을 삭제하고 처음부터 시작:
```bash
rm -rf ~/.fastgithub-issue
```

## 🎨 주요 특징

### 직관적인 UI
- 🎨 색상으로 구분된 메뉴와 메시지
- ⬆️⬇️ 화살표 키 + 숫자 입력 듀얼 내비게이션
- 📍 명확한 단계별 안내
- ✅❌ 에러 메시지와 성공 메시지 시각적 구분

### 효율적인 워크플로우
- ⭐ 즐겨찾기로 빠른 Repository 접근
- 🏷️ 프리셋으로 Label 선택 간소화
- 📝 제목만 / 제목+본문 선택으로 유연한 사용
- 🖥️ iTerm 통합으로 독립적인 작업 환경 제공

### 외부 도구 통합
- 🚀 iTerm 새 윈도우 자동 실행
- ⌨️ Raycast, Alfred 등 단축키 도구 연동 가능
- 🔧 다른 스크립트나 프로그램에서 쉽게 호출 가능

### 데이터 관리
- 💾 모든 설정 자동 저장
- 📊 이력 관리로 과거 Issue 추적
- 🗑️ 필요시 데이터 초기화 가능

## 📝 향후 개선 계획

- [ ] 기본 Repository 설정 기능
- [ ] Assignee 자동 할당 기능
- [ ] Milestone 설정 기능
- [ ] Issue 본문 에디터 통합 (vim, nano 등)
- [ ] GitHub API 직접 사용 옵션 (gh CLI 대체)
- [ ] 일반 Terminal.app에서도 새 윈도우로 실행 (open-in-terminal.sh)

## 📄 라이선스

MIT License

## 🙌 기여

이슈 및 Pull Request는 언제나 환영합니다!
