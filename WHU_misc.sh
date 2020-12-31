#!/bin/sh

# Copyright: (C) 2020 Duama
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

BASE_URL='http://172.19.1.9:8080/eportal'
API_URL="$BASE_URL/InterFace.do?method="
UA='Mozilla/5.0 (X11; Linux x86_64; rv:82.0) Gecko/20100101 Firefox/82.0'
COMMAND="$1"
OPT_ARG1="$2"
OPT_ARG2="$3"
set -- --compressed --max-time 5 \
       -H "User-Agent: $UA" \
       -H 'Accept: */*' \
       -H 'Accept-Encoding: gzip, deflate' \
       -H 'Accept-Language: zh-CN;q=0.8,zh;q=0.5' \
       -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
       -H 'Connection: keep-alive'

help() {
    echo "WHU_misc.sh <COMMAND> [<OPT_ARG1> <OPT_ARG2>]"
    echo ""
    echo "  COMMAND: info, logout, reg, dereg, deregmac, kickall, switch."
    echo "    info:    Print user info."
    echo "    logout:  Logout current device."
    echo "    reg:     Register MAC address of current device."
    echo "    dereg:   Deregister MAC address of current device."
    echo "    deregmac <USERNAME> <MAC>:     Deregister MAC address of specified device."
    echo "    kickall <USERNAME> <PASSWORD>: Kick all device of your acount."
    echo "    switch <ISP>:                  Switch to another ISP."
    echo "      ISP: CERNET, CT, CU, CMCC."
    exit 1
}

check_error() {
    if [ $1 -ne 0 ]
    then
        echo "Connection error. Have you connected to WHU network?"
        exit 1
    fi
}

set_type() {
    case $1 in
        CERNET)
            TYPE='Internet'
            ;;
        CT)
            TYPE='dianxin'
            ;;
        CU)
            TYPE='liantong'
            ;;
        CMCC)
            TYPE='yidong'
            ;;
        *)
            help
            ;;
    esac
}

get_user_index() {
    curl -I -s "$BASE_URL/redirectortosuccess.jsp" "$@" | grep '^Location: ' | grep -o 'userIndex=[^=].*' | sed 's/userIndex=//' | tr -d '\r\n'
}

get_info() {
    n=0
    until [ "$n" -ge 5 ]
    do
        RESULT=$(curl -s "${API_URL}getOnlineUserInfo" "$@" --data-urlencode userIndex="$userIndex")
        STATUS=$(echo "$RESULT" | tr ',' '\n' | grep '^"result"' | sed 's/"result"://' | tr -d \"'\n')
        MSG=$(echo "$RESULT" | tr ',' '\n' | grep '^"message"' | sed 's/"message"://' | tr -d \"'\n')
        if [ "$STATUS" = "success" ]
        then
            break
        elif [ "$STATUS" = "wait" ]
        then
            continue
        else
            echo "Failed to get user info: $MSG"
            exit 1
        fi
    done

    if ! type jq > /dev/null 2>&1
    then
        echo "$RESULT"
    else
        echo "$RESULT" | jq 'del(.ballInfo)|del(.serviceList)|del(.announcement)|del(.mabInfo)'
        echo "$RESULT" | jq -j '.mabInfo' | jq
    fi
}

if ! type curl > /dev/null 2>&1
then
    echo '"curl" is required to run the script'
    exit 1
fi

case "$COMMAND" in
    info)
        userIndex=$(get_user_index "$@")
        check_error $?
        get_info "$@"
        ;;
    logout)
        userIndex=$(get_user_index "$@")
        check_error $?
        curl -s "$BASE_URL/InterFace.do?method=logout" "$@" \
             --data-urlencode userIndex="$userIndex"
        check_error $?
        ;;
    reg)
        userIndex=$(get_user_index "$@")
        check_error $?
        curl -s "$BASE_URL/InterFace.do?method=registerMac" "$@" \
             --data-urlencode userIndex="$userIndex" \
             --data-urlencode mac=""
        check_error $?
        ;;
    dereg)
        userIndex=$(get_user_index "$@")
        check_error $?
        curl -s "$BASE_URL/InterFace.do?method=cancelMac" "$@" \
             --data-urlencode userIndex="$userIndex" \
             --data-urlencode mac=""
        check_error $?
        ;;
    deregmac)
        curl -s "$BASE_URL/InterFace.do?method=cancelMacWithUserNameAndMac" "$@" \
             --data-urlencode userId="$OPT_ARG1" \
             --data-urlencode usermac="$OPT_ARG2"
        check_error $?
        ;;
    kickall)
        curl -s "$BASE_URL/InterFace.do?method=logoutByUserIdAndPass" "$@" \
             --data-urlencode userId="$OPT_ARG1" \
             --data-urlencode pass="$OPT_ARG2"
        check_error $?
        ;;
    switch)
        userIndex=$(get_user_index "$@")
        check_error $?
        set_type "$OPT_ARG1"
        curl -s "$BASE_URL/InterFace.do?method=switchService" "$@" \
             --data-urlencode userIndex="$userIndex" \
             --data-urlencode serviceName="$TYPE"
        check_error $?
        ;;
    *)
        help
        ;;
esac

