#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 데이터 디렉토리
DATA_DIR="$HOME/.fastgithub-issue"
FAVORITES_FILE="$DATA_DIR/favorites.json"
PRESETS_FILE="$DATA_DIR/label-presets.json"
HISTORY_FILE="$DATA_DIR/history.json"
CONFIG_FILE="$DATA_DIR/config.json"

# 데이터 디렉토리 초기화
init_data_dir() {
    if [ ! -d "$DATA_DIR" ]; then
        mkdir -p "$DATA_DIR"
        echo "[]" > "$FAVORITES_FILE"
        # 기본 Label 프리셋 추가
        cat > "$PRESETS_FILE" << 'EOF'
[
  "💡 idea",
  "🐛 bug",
  "✨ feature",
  "📝 documentation"
]
EOF
        echo "[]" > "$HISTORY_FILE"
        echo "{}" > "$CONFIG_FILE"
    else
        # 프리셋 파일이 비어있으면 기본 프리셋 추가
        if [ ! -s "$PRESETS_FILE" ] || [ "$(cat "$PRESETS_FILE")" = "[]" ]; then
            cat > "$PRESETS_FILE" << 'EOF'
[
  "💡 idea",
  "🐛 bug",
  "✨ feature",
  "📝 documentation"
]
EOF
        fi
    fi
}

# GitHub CLI 확인
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI(gh)가 설치되어 있지 않습니다.${NC}"
        echo -e "${YELLOW}다음 명령어로 설치해주세요:${NC}"
        echo -e "  macOS: ${GREEN}brew install gh${NC}"
        exit 1
    fi
}

# GitHub 로그인 확인
check_gh_auth() {
    echo -e "${BLUE}🔐 GitHub 로그인 상태 확인 중...${NC}"
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  GitHub에 로그인되어 있지 않습니다.${NC}"
        echo -e "${GREEN}로그인을 시작합니다...${NC}\n"
        gh auth login

        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ 로그인에 실패했습니다.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ 로그인 상태 확인 완료${NC}\n"
    fi
}

# JSON 배열에서 항목 추가 (jq 사용)
json_array_add() {
    local file=$1
    local value=$2

    if command -v jq &> /dev/null; then
        jq ". += [\"$value\"]" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    else
        # jq가 없으면 간단하게 처리
        content=$(cat "$file")
        if [ "$content" = "[]" ]; then
            echo "[\"$value\"]" > "$file"
        else
            echo "$content" | sed "s/\]$/,\"$value\"\]/" > "$file"
        fi
    fi
}

# JSON 배열에서 항목 제거
json_array_remove() {
    local file=$1
    local value=$2

    if command -v jq &> /dev/null; then
        jq "map(select(. != \"$value\"))" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    else
        content=$(cat "$file")
        echo "$content" | sed "s/,\"$value\"//g" | sed "s/\"$value\",//g" | sed "s/\"$value\"//g" > "$file"
    fi
}

# JSON 배열 읽기
json_array_read() {
    local file=$1

    if command -v jq &> /dev/null; then
        jq -r '.[]' "$file"
    else
        cat "$file" | tr -d '[]"' | tr ',' '\n' | sed '/^$/d'
    fi
}

# 문자열을 배열로 변환 (readarray 대체)
string_to_array() {
    local input="$1"
    local -a result=()

    while IFS= read -r line; do
        [ -n "$line" ] && result+=("$line")
    done <<< "$input"

    # 배열을 전역 변수로 반환
    eval "$2=(\"\${result[@]}\")"
}

# 화살표 키로 선택 가능한 인터랙티브 메뉴
# 사용법: interactive_menu "선택된_인덱스를_저장할_변수명" "옵션1" "옵션2" ...
# 리턴: 선택된 인덱스를 지정된 변수에 저장
interactive_menu() {
    local result_var=$1
    shift
    local options=("$@")
    local selected=0
    local key

    # 커서 숨기기
    tput civis

    # 메뉴 그리기 함수
    draw_menu() {
        local sel=$1
        for i in "${!options[@]}"; do
            if [ $i -eq $sel ]; then
                # 선택된 항목 - 밝은 녹색으로 표시
                echo -e "\033[1;32m▶ ${options[$i]}\033[0m"
            else
                # 일반 항목
                echo -e "  ${options[$i]}"
            fi
        done
    }

    # 초기 메뉴 그리기
    draw_menu $selected

    while true; do
        # 키 입력 받기
        read -rsn1 key

        # ESC sequence 처리
        if [ "$key" = $'\x1b' ]; then
            read -rsn2 key
            case "$key" in
                '[A') # Up arrow
                    ((selected--))
                    [ $selected -lt 0 ] && selected=$((${#options[@]}-1))

                    # 메뉴 개수만큼 위로 이동
                    for ((i=0; i<${#options[@]}; i++)); do
                        tput cuu1
                    done
                    # 현재 위치로 이동
                    tput cr
                    # 메뉴 다시 그리기
                    draw_menu $selected
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    [ $selected -ge ${#options[@]} ] && selected=0

                    # 메뉴 개수만큼 위로 이동
                    for ((i=0; i<${#options[@]}; i++)); do
                        tput cuu1
                    done
                    # 현재 위치로 이동
                    tput cr
                    # 메뉴 다시 그리기
                    draw_menu $selected
                    ;;
            esac
        elif [ "$key" = "" ]; then
            # Enter 키
            tput cnorm
            eval "$result_var=$selected"
            return 0
        elif [[ "$key" =~ ^[0-9]$ ]]; then
            # 숫자 직접 입력 (메뉴 번호와 매칭)
            local menu_num=$key
            for i in "${!options[@]}"; do
                # ANSI 코드 제거 후 메뉴 텍스트에서 숫자 추출
                local clean_text=$(echo -e "${options[$i]}" | sed 's/\x1b\[[0-9;]*m//g')
                if [[ "$clean_text" =~ ^[^0-9]*([0-9]+)\. ]]; then
                    if [ "${BASH_REMATCH[1]}" = "$menu_num" ]; then
                        tput cnorm
                        # 메뉴를 지우고 커서를 원위치로
                        for ((j=0; j<${#options[@]}; j++)); do
                            tput cuu1
                        done
                        tput cr
                        eval "$result_var=$i"
                        return 0
                    fi
                fi
            done
        fi
    done
}

# 즐겨찾기 Repository 목록 가져오기
get_favorites() {
    json_array_read "$FAVORITES_FILE"
}

# 즐겨찾기 추가
add_favorite() {
    local repo=$1
    json_array_add "$FAVORITES_FILE" "$repo"
    echo -e "${GREEN}✅ 즐겨찾기에 추가되었습니다: ${repo}${NC}"
}

# 즐겨찾기 제거
remove_favorite() {
    local repo=$1
    json_array_remove "$FAVORITES_FILE" "$repo"
    echo -e "${GREEN}✅ 즐겨찾기에서 제거되었습니다: ${repo}${NC}"
}

# 이력 추가
add_history() {
    local repo=$1
    local title=$2
    local url=$3
    local timestamp=$(date +%s)

    if command -v jq &> /dev/null; then
        local entry="{\"repo\":\"$repo\",\"title\":\"$title\",\"url\":\"$url\",\"timestamp\":$timestamp}"
        jq ". += [$entry]" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        # 최근 20개만 유지
        jq '.[-20:]' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Repository 선택
select_repository() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   📦 Repository 선택${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    # 즐겨찾기 목록
    favorites=$(get_favorites)
    declare -a fav_array
    declare -a menu_items

    if [ -n "$favorites" ]; then
        string_to_array "$favorites" fav_array
        echo -e "${CYAN}⭐ 즐겨찾기 Repository:${NC}"
        for i in "${!fav_array[@]}"; do
            menu_items+=("${YELLOW}$((i+1)).${NC} ⭐ ${fav_array[$i]}")
            echo -e "  ${YELLOW}$((i+1)).${NC} ${fav_array[$i]}"
        done
        echo ""

        # 검색 및 전체 목록 옵션 추가
        menu_items+=("${CYAN}🔍 검색하기${NC}")
        menu_items+=("${GREEN}📋 전체 목록 보기${NC}")

        echo -e "${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 숫자 입력)${NC}\n"

        local choice
        interactive_menu choice "${menu_items[@]}"

        # 즐겨찾기 직접 선택
        if [ $choice -lt ${#fav_array[@]} ]; then
            selected_repo="${fav_array[$choice]}"
            echo -e "\n${GREEN}✅ 선택된 Repository: ${selected_repo}${NC}\n"
            return 0
        fi

        # 검색 선택
        if [ $choice -eq ${#fav_array[@]} ]; then
            echo -e "\n${YELLOW}검색어를 입력하세요:${NC}"
            read -p "> " search_query
            repos=$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | grep -i "$search_query")
        # 전체 목록 선택
        elif [ $choice -eq $((${#fav_array[@]} + 1)) ]; then
            repos=$(gh repo list --limit 30 --json nameWithOwner --jq '.[].nameWithOwner')
        fi
    else
        # 즐겨찾기가 없는 경우
        echo -e "${YELLOW}검색어를 입력하거나 엔터를 눌러 전체 목록 보기:${NC}"
        read -p "> " search_query

        if [ -z "$search_query" ]; then
            repos=$(gh repo list --limit 30 --json nameWithOwner --jq '.[].nameWithOwner')
        else
            repos=$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | grep -i "$search_query")
        fi
    fi

    # 검색 결과 처리
    if [ -z "$repos" ]; then
        echo -e "${RED}❌ Repository를 찾을 수 없습니다.${NC}"
        read -p "$(echo -e "\n엔터를 눌러 계속...")"
        return 1
    fi

    declare -a repo_array
    string_to_array "$repos" repo_array

    # Repository 목록 메뉴 생성
    declare -a all_repos
    declare -a result_menu_items

    echo -e "\n${GREEN}사용 가능한 Repository:${NC}"
    for i in "${!repo_array[@]}"; do
        all_repos+=("${repo_array[$i]}")
        result_menu_items+=("${YELLOW}$((i+1)).${NC} ${repo_array[$i]}")
        echo -e "  ${YELLOW}$((i+1)).${NC} ${repo_array[$i]}"
    done

    echo -e "\n${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 숫자 입력)${NC}\n"

    local result_choice
    interactive_menu result_choice "${result_menu_items[@]}"

    selected_repo="${all_repos[$result_choice]}"
    echo -e "\n${GREEN}✅ 선택된 Repository: ${selected_repo}${NC}\n"
}

# Label 프리셋 선택
select_labels() {
    local repo=$1

    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   🏷️  Label 선택${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    # Label 프리셋 표시
    presets=$(json_array_read "$PRESETS_FILE")
    declare -a preset_array

    if [ -n "$presets" ]; then
        string_to_array "$presets" preset_array
    fi

    # Repository의 Label 가져오기
    labels=$(gh api "/repos/${repo}/labels" --jq '.[].name' 2>/dev/null)

    if [ -z "$labels" ]; then
        echo -e "${YELLOW}⚠️  Label을 가져올 수 없습니다. Label 없이 진행합니다.${NC}\n"
        selected_labels=""
        return
    fi

    declare -a label_array
    string_to_array "$labels" label_array

    # 메뉴 생성
    declare -a menu_items
    menu_items+=("${YELLOW}0.${NC} Label 없이 진행")

    # 프리셋 추가
    if [ ${#preset_array[@]} -gt 0 ]; then
        for i in "${!preset_array[@]}"; do
            menu_items+=("${CYAN}p$((i+1)).${NC} ${preset_array[$i]}")
        done
    fi

    # 개별 라벨 목록
    for i in "${!label_array[@]}"; do
        menu_items+=("${YELLOW}$((i+1)).${NC} ${label_array[$i]}")
    done

    menu_items+=("${MAGENTA}🔧 직접 입력 (여러 개 선택)${NC}")

    echo -e "${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 번호/p번호 입력)${NC}\n"

    local choice
    interactive_menu choice "${menu_items[@]}"

    # 선택 처리
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   🏷️  Label 선택 결과${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    if [ $choice -eq 0 ]; then
        # Label 없이 진행
        selected_labels=""
        echo -e "${GREEN}✅ Label 없이 진행합니다.${NC}\n"
    elif [ $choice -eq $((${#menu_items[@]}-1)) ]; then
        # 직접 입력
        echo -e "${YELLOW}여러 개 선택 가능 (쉼표로 구분, 예: 1,3,5 또는 p1):${NC}"
        read -p "> " label_choices

        if [ -z "$label_choices" ]; then
            selected_labels=""
            echo -e "\n${GREEN}✅ Label 없이 진행합니다.${NC}\n"
        else
            selected_label_names=()

            # 프리셋 선택 처리
            if [[ "$label_choices" =~ ^p[0-9]+$ ]]; then
                preset_idx=${label_choices#p}
                if [ "$preset_idx" -ge 1 ] && [ "$preset_idx" -le "${#preset_array[@]}" ]; then
                    selected_labels="${preset_array[$((preset_idx-1))]}"
                    echo -e "\n${GREEN}✅ 선택된 프리셋: ${selected_labels}${NC}\n"
                    return
                fi
            fi

            IFS=',' read -ra label_indices <<< "$label_choices"

            for idx in "${label_indices[@]}"; do
                idx=$(echo "$idx" | xargs)
                if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#label_array[@]}" ]; then
                    selected_label_names+=("${label_array[$((idx-1))]}")
                fi
            done

            if [ ${#selected_label_names[@]} -gt 0 ]; then
                selected_labels=$(IFS=,; echo "${selected_label_names[*]}")
                echo -e "\n${GREEN}✅ 선택된 Labels: ${selected_labels}${NC}\n"
            else
                selected_labels=""
                echo -e "\n${YELLOW}⚠️  유효한 Label이 선택되지 않았습니다. Label 없이 진행합니다.${NC}\n"
            fi
        fi
    elif [ $choice -ge 1 ] && [ $choice -le ${#preset_array[@]} ]; then
        # 프리셋 선택
        selected_labels="${preset_array[$((choice-1))]}"
        echo -e "${CYAN}선택한 프리셋:${NC} ${preset_array[$((choice-1))]}"
        echo -e "${GREEN}✅ 선택된 Label: ${selected_labels}${NC}\n"
    else
        # 개별 라벨 선택
        local label_idx=$((choice - ${#preset_array[@]} - 1))
        if [ $label_idx -ge 0 ] && [ $label_idx -lt ${#label_array[@]} ]; then
            selected_labels="${label_array[$label_idx]}"
            echo -e "${CYAN}선택한 Label:${NC} ${label_array[$label_idx]}"
            echo -e "${GREEN}✅ 선택된 Label: ${selected_labels}${NC}\n"
        else
            selected_labels=""
            echo -e "${YELLOW}⚠️  유효한 선택이 아닙니다. Label 없이 진행합니다.${NC}\n"
        fi
    fi
}

# Issue 생성
create_issue() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   🚀 Issue 빠르게 등록${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    # Issue 타입 선택
    echo -e "${CYAN}Issue 생성 방식을 선택하세요:${NC}"
    local type_items=(
        "${YELLOW}1.${NC} 제목만"
        "${YELLOW}2.${NC} 제목 + 본문"
    )
    echo -e "${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 숫자 입력)${NC}\n"

    local type_choice
    interactive_menu type_choice "${type_items[@]}"
    issue_type=$((type_choice + 1))

    # Repository 선택
    select_repository
    if [ -z "$selected_repo" ]; then
        return
    fi

    # Label 선택
    select_labels "$selected_repo"

    # 제목 입력
    echo -e "${BLUE}📝 Issue 제목 입력${NC}"
    read -p "> " issue_title

    if [ -z "$issue_title" ]; then
        echo -e "${RED}❌ 제목이 비어있습니다.${NC}"
        read -p "메인 메뉴로 돌아가려면 엔터를 누르세요..."
        return
    fi

    # 본문 입력 (선택사항)
    issue_body=""
    if [ "$issue_type" = "2" ]; then
        echo -e "${BLUE}📄 Issue 본문 입력 (완료하려면 빈 줄에서 Ctrl+D):${NC}"
        issue_body=$(cat)
    fi

    # Issue 생성
    echo -e "\n${BLUE}🚀 Issue 생성 중...${NC}"

    # 🔍 검수필요 라벨이 Repository에 있는지 확인
    repo_labels=$(gh api "/repos/${selected_repo}/labels" --jq '.[].name' 2>/dev/null)
    if echo "$repo_labels" | grep -q "^🔍 검수필요$"; then
        # 라벨이 이미 존재함
        :
    else
        # 라벨이 없으면 생성
        echo -e "${YELLOW}🔍 검수필요 라벨이 없습니다. 자동으로 생성합니다...${NC}"
        gh label create "🔍 검수필요" --repo "${selected_repo}" --color "FBCA04" --description "검수가 필요한 이슈" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 🔍 검수필요 라벨이 생성되었습니다.${NC}"
        else
            echo -e "${YELLOW}⚠️  라벨 생성에 실패했습니다. 계속 진행합니다.${NC}"
        fi
    fi

    # 🔍 검수필요 라벨 자동 추가
    if [ -n "$selected_labels" ]; then
        selected_labels="${selected_labels},🔍 검수필요"
    else
        selected_labels="🔍 검수필요"
    fi

    create_cmd="gh issue create --repo \"${selected_repo}\" --title \"${issue_title}\""

    if [ -n "$selected_labels" ]; then
        create_cmd+=" --label \"${selected_labels}\""
    fi

    if [ -n "$issue_body" ]; then
        create_cmd+=" --body \"${issue_body}\""
    else
        create_cmd+=" --body \"\""
    fi

    issue_url=$(eval $create_cmd)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Issue가 성공적으로 생성되었습니다!${NC}"
        echo -e "${BLUE}🔗 ${issue_url}${NC}"

        # 이력 추가
        add_history "$selected_repo" "$issue_title" "$issue_url"
    else
        echo -e "${RED}❌ Issue 생성에 실패했습니다.${NC}"
    fi

    read -p "$(echo -e "\n메인 메뉴로 돌아가려면 엔터를 누르세요...")"
}

# 즐겨찾기 관리
manage_favorites() {
    while true; do
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}   ⭐ 즐겨찾기 Repository 관리${NC}"
        echo -e "${BLUE}========================================${NC}\n"

        # 현재 즐겨찾기 목록 표시
        favorites=$(get_favorites)
        if [ -z "$favorites" ]; then
            echo -e "${YELLOW}현재 즐겨찾기가 비어있습니다.${NC}\n"
        else
            declare -a fav_array
            string_to_array "$favorites" fav_array

            echo -e "${GREEN}현재 즐겨찾기 (${#fav_array[@]}개):${NC}"
            for i in "${!fav_array[@]}"; do
                echo -e "  ${CYAN}$((i+1)).${NC} ${fav_array[$i]}"
            done
            echo ""
        fi

        echo -e "${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 숫자 입력)${NC}\n"

        local menu_items=(
            "${CYAN}1.${NC} 즐겨찾기 추가"
            "${CYAN}2.${NC} 즐겨찾기 삭제"
            "${CYAN}0.${NC} 뒤로가기"
        )

        local choice
        interactive_menu choice "${menu_items[@]}"

        case $choice in
            0)  # 즐겨찾기 추가
                echo -e "\n${YELLOW}검색어를 입력하거나 엔터를 눌러 내 Repository 목록 보기:${NC}"
                read -p "> " search_query

                if [ -z "$search_query" ]; then
                    # 내 repository 목록
                    repos=$(gh repo list --limit 30 --json nameWithOwner --jq '.[].nameWithOwner')
                else
                    # 전체 목록을 가져와서 로컬에서 필터링
                    repos=$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | grep -i "$search_query")
                fi

                if [ -z "$repos" ]; then
                    echo -e "${RED}❌ Repository를 찾을 수 없습니다.${NC}"
                else
                    # 이미 즐겨찾기에 있는 Repository 필터링
                    declare -a repo_array
                    declare -a filtered_array
                    string_to_array "$repos" repo_array

                    # 현재 즐겨찾기 목록 가져오기
                    current_favorites=$(get_favorites)
                    declare -a fav_array
                    if [ -n "$current_favorites" ]; then
                        string_to_array "$current_favorites" fav_array
                    fi

                    # 중복 제거
                    for repo in "${repo_array[@]}"; do
                        local is_duplicate=0
                        for fav in "${fav_array[@]}"; do
                            if [ "$repo" = "$fav" ]; then
                                is_duplicate=1
                                break
                            fi
                        done
                        if [ $is_duplicate -eq 0 ]; then
                            filtered_array+=("$repo")
                        fi
                    done

                    if [ ${#filtered_array[@]} -eq 0 ]; then
                        echo -e "${YELLOW}⚠️  모든 Repository가 이미 즐겨찾기에 추가되어 있습니다.${NC}"
                    else
                        echo -e "\n${GREEN}Repository 목록 (즐겨찾기 제외):${NC}"
                        for i in "${!filtered_array[@]}"; do
                            echo -e "  ${YELLOW}$((i+1)).${NC} ${filtered_array[$i]}"
                        done

                        read -p "$(echo -e "\n${BLUE}추가할 번호:${NC} ")" repo_choice

                        if [[ "$repo_choice" =~ ^[0-9]+$ ]] && [ "$repo_choice" -ge 1 ] && [ "$repo_choice" -le "${#filtered_array[@]}" ]; then
                            add_favorite "${filtered_array[$((repo_choice-1))]}"
                        fi
                    fi
                fi

                read -p "$(echo -e "\n엔터를 눌러 계속...")"
                ;;
            1)  # 즐겨찾기 삭제
                favorites=$(get_favorites)
                if [ -z "$favorites" ]; then
                    echo -e "\n${YELLOW}삭제할 즐겨찾기가 없습니다.${NC}"
                else
                    declare -a fav_array
                    string_to_array "$favorites" fav_array

                    echo -e "\n${GREEN}삭제할 즐겨찾기를 선택하세요:${NC}"
                    for i in "${!fav_array[@]}"; do
                        echo -e "  ${YELLOW}$((i+1)).${NC} ${fav_array[$i]}"
                    done

                    read -p "$(echo -e "\n${BLUE}삭제할 번호:${NC} ")" fav_choice

                    if [[ "$fav_choice" =~ ^[0-9]+$ ]] && [ "$fav_choice" -ge 1 ] && [ "$fav_choice" -le "${#fav_array[@]}" ]; then
                        remove_favorite "${fav_array[$((fav_choice-1))]}"
                    fi
                fi

                read -p "$(echo -e "\n엔터를 눌러 계속...")"
                ;;
            2)  # 뒤로가기
                break
                ;;
        esac
    done
}

# Label 프리셋 관리
manage_label_presets() {
    while true; do
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}   🏷️  Label 프리셋 관리${NC}"
        echo -e "${BLUE}========================================${NC}\n"

        # 현재 프리셋 목록 표시
        presets=$(json_array_read "$PRESETS_FILE")
        if [ -z "$presets" ]; then
            echo -e "${YELLOW}현재 프리셋이 비어있습니다.${NC}\n"
        else
            declare -a preset_array
            string_to_array "$presets" preset_array

            echo -e "${GREEN}현재 프리셋 (${#preset_array[@]}개):${NC}"
            for i in "${!preset_array[@]}"; do
                echo -e "  ${CYAN}p$((i+1)).${NC} ${preset_array[$i]}"
            done
            echo ""
        fi

        echo -e "${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 숫자 입력)${NC}\n"

        local menu_items=(
            "${CYAN}1.${NC} 프리셋 추가"
            "${CYAN}2.${NC} 프리셋 삭제"
            "${CYAN}0.${NC} 뒤로가기"
        )

        local choice
        interactive_menu choice "${menu_items[@]}"

        case $choice in
            0)  # 프리셋 추가
                echo -e "\n${YELLOW}프리셋 이름을 입력하세요 (예: bug,enhancement):${NC}"
                read -p "> " preset_name

                if [ -n "$preset_name" ]; then
                    json_array_add "$PRESETS_FILE" "$preset_name"
                    echo -e "${GREEN}✅ 프리셋이 추가되었습니다.${NC}"
                fi

                read -p "$(echo -e "\n엔터를 눌러 계속...")"
                ;;
            1)  # 프리셋 삭제
                presets=$(json_array_read "$PRESETS_FILE")
                if [ -z "$presets" ]; then
                    echo -e "\n${YELLOW}삭제할 프리셋이 없습니다.${NC}"
                else
                    declare -a preset_array
                    string_to_array "$presets" preset_array

                    echo -e "\n${GREEN}삭제할 프리셋을 선택하세요:${NC}"
                    for i in "${!preset_array[@]}"; do
                        echo -e "  ${YELLOW}$((i+1)).${NC} ${preset_array[$i]}"
                    done

                    read -p "$(echo -e "\n${BLUE}삭제할 번호:${NC} ")" preset_choice

                    if [[ "$preset_choice" =~ ^[0-9]+$ ]] && [ "$preset_choice" -ge 1 ] && [ "$preset_choice" -le "${#preset_array[@]}" ]; then
                        json_array_remove "$PRESETS_FILE" "${preset_array[$((preset_choice-1))]}"
                        echo -e "${GREEN}✅ 프리셋이 삭제되었습니다.${NC}"
                    fi
                fi

                read -p "$(echo -e "\n엔터를 눌러 계속...")"
                ;;
            2)  # 뒤로가기
                break
                ;;
        esac
    done
}

# 최근 사용 이력
show_history() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   📊 최근 사용 이력${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq가 설치되어 있지 않습니다.${NC}"
        echo -e "${YELLOW}이력 기능을 사용하려면 jq를 설치해주세요: brew install jq${NC}"
        read -p "$(echo -e "\n엔터를 눌러 계속...")"
        return
    fi

    history=$(jq -r '.[-10:] | reverse | .[] | "\(.timestamp)|\(.repo)|\(.title)|\(.url)"' "$HISTORY_FILE" 2>/dev/null)

    if [ -z "$history" ]; then
        echo -e "${YELLOW}최근 이력이 없습니다.${NC}"
    else
        echo -e "${GREEN}최근 생성한 Issue:${NC}\n"
        while IFS='|' read -r timestamp repo title url; do
            date_str=$(date -r "$timestamp" "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$timestamp" "+%Y-%m-%d %H:%M" 2>/dev/null)
            echo -e "${CYAN}[$date_str]${NC}"
            echo -e "  ${YELLOW}Repository:${NC} $repo"
            echo -e "  ${YELLOW}Title:${NC} $title"
            echo -e "  ${BLUE}🔗 $url${NC}\n"
        done <<< "$history"
    fi

    read -p "$(echo -e "엔터를 눌러 계속...")"
}

# 설정 메뉴
settings_menu() {
    while true; do
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}   ⚙️  설정${NC}"
        echo -e "${BLUE}========================================${NC}\n"
        echo -e "${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 숫자 입력)${NC}\n"

        local menu_items=(
            "${CYAN}1.${NC} 데이터 초기화"
            "${CYAN}2.${NC} GitHub CLI 재로그인"
            "${CYAN}0.${NC} 뒤로가기"
        )

        local choice
        interactive_menu choice "${menu_items[@]}"

        case $choice in
            0)  # 데이터 초기화
                echo -e "\n${RED}⚠️  모든 데이터가 삭제됩니다. 계속하시겠습니까? (y/N)${NC}"
                read -p "> " confirm

                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    rm -rf "$DATA_DIR"
                    init_data_dir
                    echo -e "${GREEN}✅ 데이터가 초기화되었습니다.${NC}"
                fi

                read -p "$(echo -e "\n엔터를 눌러 계속...")"
                ;;
            1)  # GitHub CLI 재로그인
                gh auth logout
                gh auth login
                read -p "$(echo -e "\n엔터를 눌러 계속...")"
                ;;
            2)  # 뒤로가기
                break
                ;;
        esac
    done
}

# 메인 메뉴
main_menu() {
    while true; do
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}   GitHub Issue 빠른 생성 도구${NC}"
        echo -e "${BLUE}========================================${NC}\n"
        echo -e "${YELLOW}↑↓ 화살표로 이동, Enter로 선택 (또는 숫자 입력)${NC}\n"

        # 메뉴 항목 배열
        local menu_items=(
            "${CYAN}1.${NC} 🚀 Issue 빠르게 등록"
            "${CYAN}2.${NC} ⭐ 즐겨찾기 Repository 관리"
            "${CYAN}3.${NC} 🏷️  Label 프리셋 관리"
            "${CYAN}4.${NC} 📊 최근 사용 이력 보기"
            "${CYAN}5.${NC} ⚙️  설정"
            "${CYAN}0.${NC} 종료"
        )

        local choice
        interactive_menu choice "${menu_items[@]}"

        case $choice in
            0) create_issue ;;
            1) manage_favorites ;;
            2) manage_label_presets ;;
            3) show_history ;;
            4) settings_menu ;;
            5)
                clear
                echo -e "\n${GREEN}👋 안녕히 가세요!${NC}"
                exit 0
                ;;
        esac
    done
}

# 메인 실행
check_gh_cli
init_data_dir
check_gh_auth
main_menu
