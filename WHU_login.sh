#!/usr/bin/bash
unset http_proxy
unset https_proxy
DETECT_URL='http://conn1.oppomobile.com/generate_204'
LOGIN_POST_URL='http://172.19.1.9:8080/eportal/InterFace.do?method=login'
UA='Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0'
TYPE='Internet'

help() {
    echo "WHU_login.sh -u <USERNAME> -p <PASSWORD> [-t <TYPE>]"
    echo "             TYPE: CERNET, CT, CMCC."
    echo "                   CERNET: 教育网."
    echo "                   CT:     中国电信."
    echo "                   CMCC:   中国移动."
    echo "                   The default type is CERNET."
    exit 1
}

set_type() {
    case $1 in
        CERNET)
            TYPE='Internet'
            ;;
        CT)
            TYPE='dianxin'
            ;;
        CMCC)
            TYPE='yidong'
            ;;
        *)
            help
            ;;
    esac
}

detect() {
    curl -s -v "$DETECT_URL" --max-time 10 -H "User-Agent: $UA" 2>&1
}

login() {
    curl -s "$LOGIN_POST_URL" --compressed --max-time 15 \
        -H "User-Agent: $UA" \
        -H 'Accept: */*' \
        -H 'Accept-Encoding: gzip, deflate' \
        -H 'Accept-Language: zh-CN;q=0.8,zh;q=0.5' \
        -H "Referer: $LOGIN_PAGE_URL" \
        -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
        -H 'Connection: keep-alive' \
        --data-urlencode userId="$USERNAME" \
        --data-urlencode password="$PASSWORD" \
        --data-urlencode service="$TYPE" \
        --data-urlencode queryString="$queryString" \
        --data-urlencode operatorPwd="" \
        --data-urlencode operatorUserId="" \
        --data-urlencode validcode="" \
        --data-urlencode passwordEncrypt="false"
}

print_result() {
    if ! type jq > /dev/null 2>&1
    then
        echo $LOGIN_RESULT
        if echo "$LOGIN_RESULT" | grep --quiet '"result":"success"'
        then
            echo 'Success'
            exit 0
        elif echo "$LOGIN_RESULT" | grep --quiet '"result":"fail"'
        then
            echo 'Login failed'
            exit 1
        fi
    else
        RESULT=$(echo $LOGIN_RESULT | jq -j '.result')
        MESSAGE=$(echo $LOGIN_RESULT | jq -j '.message')
        if [ "$RESULT" = 'fail' ]
        then
            echo -n 'Login failed: '
            echo "$MESSAGE"
            exit 1
        elif [ "$RESULT" = 'success' ]
        then
            echo 'Success'
            exit 0
        else
            echo -n 'Unkown result: '
            echo "$RESULT"
            echo "$MESSAGE"
            exit 1
        fi
    fi
}

while getopts  "hu:p:t:" opt; do
    case $opt in
        h)
            help
            ;;
        u)
            USERNAME="$OPTARG"
            ;;
        p)
            PASSWORD="$OPTARG"
            ;;
        t)
            set_type $OPTARG
            ;;
        *)
            help
            ;;
    esac
done

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]
then
    help
fi

if ! type curl > /dev/null 2>&1
then
    echo '"curl" is required to run the script'
    exit 1
fi

#TEST_RESULT=$(curl -s -o /dev/null -I -w "%{http_code}" ${DETECT_URL})
TEST_RESULT="$(detect)"
if [ $? != 0 ]
then
    echo 'Connection error'
    exit 1
fi

STATUS_CODE="$(echo "$TEST_RESULT" | grep -oE 'HTTP/[.0-9]{1,5} ([0-9]{3}) ' | awk '{printf $NF}')"
LOGIN_PAGE_URL="$(echo "$TEST_RESULT" | grep 'script' | grep -o \''.*'\' | tr -d \''\n')"
queryString="$(echo "$LOGIN_PAGE_URL" | grep -o '?.*$' | tr -d '?\n')"

if [ "$STATUS_CODE" -eq "200" ]
then
    LOGIN_RESULT=$(login)
    if [ $? != 0 ]
    then
        echo 'Login failed: connection error'
        exit 1
    fi
    print_result
elif [ "$STATUS_CODE" -eq "204" ]
then
    echo 'Already logged in'
    exit 0
else
    echo -n 'Unknown status code: '
    echo "$STATUS_CODE"
    exit 1
fi

