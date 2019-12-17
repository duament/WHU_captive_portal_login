# WHU_captive_portal_login

用于登录武汉大学校园网的 Shell 脚本，依赖于 `curl` 。

## 用法

    WHU_login.sh -u <USERNAME> -p <PASSWORD> [-t <TYPE>]
    
                 TYPE: CERNET, CT, CMCC.
                       CERNET: 教育网.
                       CT:     中国电信.
                       CU:     中国联通.
                       CMCC:   中国移动.
                       默认选项是教育网.
