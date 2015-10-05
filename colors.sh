# Code referenced from http://misc.flogisoft.com/bash/tip_colors_and_formatting

# Styles
NORM=$'\e[0m'
BOLD=$'\e[1m'
UNDR=$'\e[4m'

# Foreground Colors
DEF=$'\e[39m'
BLK=$'\e[30m'
RED=$'\e[31m'
GRN=$'\e[32m'
YLW=$'\e[33m'
BLU=$'\e[34m'
MAG=$'\e[35m'
CYN=$'\e[36m'
LGRY=$'\e[37m'
DGRY=$'\e[90m'
LRED=$'\e[91m'
LGRN=$'\e[92m'
LYLW=$'\e[93m'
LBLU=$'\e[94m'
LMAG=$'\e[95m'
LCYN=$'\e[96m'
WTE=$'\e[97m'

# Background Colors
BGDEF=$'\e[49m'
BGBLK=$'\e[40m'
BGRED=$'\e[41m'
BGGRN=$'\e[42m'
BGYLW=$'\e[43m'
BGBLU=$'\e[44m'
BGMAG=$'\e[45m'
BGCYN=$'\e[46m'
BGLGRY=$'\e[47m'
BGDGRY=$'\e[100m'
BGLRED=$'\e[101m'
BGLGRN=$'\e[102m'
BGLYLW=$'\e[103m'
BGLBLU=$'\e[104m'
BGLMAG=$'\e[105m'
BGLCYN=$'\e[106m'
BGWTE=$'\e[107m'

# Strips control sequences from the given string.
# Note this is not a comprehensive function its mainly here to strip colors.
function _strip_control_sequence {
    echo "$@" | sed $'s/\e\[[0-9][0-9]\\?[0-9]\\?m//g'
}
