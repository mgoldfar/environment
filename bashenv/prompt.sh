
function _git_status {

    # If git promp disabled then don't do anything
    if (( DISABLE_git_status == 1 )); then
        return;
    fi

    # If not git is installed then print in error
    if (( HAVE_git == 0 )); then
        if [[ -d "./.git" ]]; then
            echo -n "${RED}?? git not found ??${DEF}"
        fi
        return
    fi

    # Display nothing if we are not in a working tree
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        local branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD 2>/dev/null)

        # Truncate the branch name to 32 characters
        local len=${BASHENV_GIT_MAX_BRANCH_LEN:-32}
        if (( ${#branch} > $len )); then
            branch="${branch:0:$len}..."
        fi

        local staged_added=0
        local staged_modified=0
        local staged_deleted=0
        local unstaged_added=0
        local unstaged_modified=0
        local unstaged=deleted=0
        local untracked=0
        local unmerged=0
        while IFS= read line; do
            local c1=${line:0:1}
            local c2=${line:1:1}

            case "$c1$c2" in
                "DD"|"AU"|"UD"|"UA"|"DU"|"AA"|"UU") (( unmerged++ )) ;;
                "??") (( untracked++ )) ;;
            esac

            case "$c2" in
                "M") (( unstaged_modified++ )) ;;
                "A") (( unstaged_added++ )) ;;
                "D") (( unstaged_deleted++ )) ;;
            esac

            case "$c1" in
                "M") (( staged_modified++ )) ;;
                "A") (( staged_added++ )) ;;
                "D") (( staged_deleted++ )) ;;
            esac
        # TODO: This command may take _a long time_ when the repo is very
        # large or needs a GC. Consider replacing this command with some
        # timeout based command so that the user can get on with work.
        done < <(git status --porcelain 2>/dev/null)

        local status=""
        if (( untracked > 0 )); then
            status="${status}${YLW}?${DEF}${NORM}"
        fi

        if (( unstaged_modified > 0 && staged_modified > 0 )); then
            status="${status}${RED}M${DEF}${NORM}"
        elif (( unstaged_modified > 0 )); then
            status="${status}${RED}m${DEF}${NORM}"
        elif (( staged_modified > 0 )); then
            status="${status}${GRN}M${DEF}${NORM}"
        fi

        if (( unmerged > 0 )); then
            status="${BOLD}<<< ${status}${BOLD} >>${DEF}>${NORM}"
        elif [[ -n "$status" ]]; then
            status="-${status}-"
        fi

        local brcolor="${BGDEF}${DEF}"
        if (( unstaged_modified + unstaged_added + unstaged_deleted > 0 )); then
            brcolor="${BGRED}${BOLD}${WTE}"
        elif (( untracked > 0 )); then
            brcolor="${BGYLW}${BOLD}${WTE}"
        else
            brcolor="${BGGRN}${WTE}"
        fi

        echo -e -n "${brcolor}${branch}${BGDEF}${DEF}${NORM} ${status}"
    fi
}

function _cpu_utilization {
    local ncpu=1
    if (( IS_MACOSX == 1 )); then
        ncpu=$(sysctl hw.ncpu | cut -d' ' -f2)
    elif (( IS_LINUX == 1 )); then
        ncpu=$(nproc)
    fi

    local cpu_util=$(ps -eo "%cpu" | awk "{s+=\$0} END { printf \"%d\", s/$ncpu }")

    local color=""
    if (( $cpu_util > 75 )); then
        color=$BLD$RED
    elif (( $cpu_util > 50 )); then
        color=$LRED
    elif (( $cpu_util > 25 )); then
        color=$YLW
    else
        color=$GRN
    fi

    echo -e "${color}${cpu_util}%${NORM}"
}

function _mem_utilization {
    local mem_util="?"
    if (( IS_MACOSX == 1 )); then
        local total_hw_mem_bytes=$(sysctl hw.memsize | cut -d' ' -f2)
        local page_size=$(sysctl vm.pagesize | cut -d' ' -f2)
        local total_hw_pages=$((total_hw_mem_bytes / page_size))
        local num_page_free=$(sysctl vm.page_free_count | cut -d' ' -f2)
        local num_page_purgable=$(sysctl vm.page_purgeable_count | cut -d' ' -f2)
        local num_page_reusable=$(sysctl vm.page_reusable_count | cut -d' ' -f2)
        mem_util=$(( (num_page_free+num_page_purgable+num_page_reusable)*100/total_hw_pages))

    elif (( IS_LINUX == 1 )); then
        local awksrc='/total[[:space:]]memory/{tot=$1} '
        awksrc=$awksrc'/free[[:space:]]memory/{free=$1} '
        awksrc=$awksrc'END {p=free/tot; printf "%d", 100*p; }'
        mem_util=$(vmstat -s | awk "$awksrc" )
    fi

    local color=""
    (( mem_util = 100 - $mem_util ))
    if [[ $mem_util != "?" ]]; then
        if (( $mem_util > 90 )); then
            color=$BOLD$RED
        elif (( $mem_util > 75 )); then
            color=$LRED
        elif (( $mem_util > 50 )); then
            color=$YLW
        else
            color=$GRN
        fi
    fi

    echo -e "${color}${mem_util}%${NORM}"
}

function _prompt {
    local last_exit=$?
    local last_exit_fmt=$(printf "%3d" ${last_exit})
    local cpu_util=$(_cpu_utilization)
    local mem_util=$(_mem_utilization)
    local git_status=$(_git_status)
    local time=$(date +"%T")
    local user=$(whoami)
    local host=$(hostname -s)
    local pwd=$(pwd)
    if [[ $pwd == $HOME* ]]; then
        pwd='~'${pwd#${HOME}}
    fi

    local cols=$(tput cols)

    # Note: We do not use the PS1 escape strings because we will not
    # get an accurate string length
    local ps1="\\[[$time $cpu_util $mem_util] "
    ps1="${ps1}${BLU}${user}@${host}${DEF} ${BOLD}${pwd}${NORM} "

    if [[ -n "${git_status}" ]]; then
        local ps1_strip=$(_strip_control_sequence "${ps1}")
        local git_status_strip=$(_strip_control_sequence "${git_status}")
        if (( ${#ps1_strip} + ${#git_status_strip} > $cols )); then
            ps1="${ps1}\\n${git_status}"
        else
            ps1="${ps1}${git_status}"
        fi
    fi
    ps1="${ps1}\\n"

    # Add last command exit status to prompt line
    if (( ${last_exit} == 0 )); then
	     ps1="${ps1}\[${GRN}\](${last_exit_fmt})\[${DEF}\]"
    else
	     ps1="${ps1}\[${RED}\](${last_exit_fmt})\[${DEF}\]"
    fi

    # Finally add prompt designator
    ps1="${ps1}\\$ "

    export PS1="${ps1}"
}

export PROMPT_COMMAND=_prompt
