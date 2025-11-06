#!/bin/bash
# open-in-iterm.sh
# iTerm에서 create-issue.sh를 실행하는 Wrapper 스크립트

SCRIPT_PATH="/Users/brody/Desktop/FastGithubIssue/create-issue.sh"

osascript <<EOF
tell application "iTerm"
    activate
    create window with default profile
    tell current window
        -- 윈도우 크기 설정: {x, y, x+width, y+height}
        -- 화면 좌측 상단에서 시작, 넓고 큰 크기
        set bounds to {100, 100, 1400, 900}
    end tell
    tell current session of current window
        write text "cd \"$(dirname "$SCRIPT_PATH")\" && bash \"$SCRIPT_PATH\""
    end tell
end tell
EOF
