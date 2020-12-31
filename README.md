# WHU_captive_portal_login

用于登录武汉大学校园网的 Shell 脚本，依赖于 `curl` 。

## 用法

    WHU_login.sh -u <USERNAME> -p <PASSWORD> [-t <ISP>]
    
                 ISP: CERNET, CT, CU, CMCC.
                       CERNET: 教育网.
                       CT:     中国电信.
                       CU:     中国联通.
                       CMCC:   中国移动.
                       默认选项是教育网.

---

    WHU_misc.sh <COMMAND> [<OPT_ARG1> <OPT_ARG2>]

        COMMAND: info, logout, reg, dereg, deregmac, kickall, switch.

            info:  打印当前用户信息.
                注: 安装 jq 之后更易读.

            logout:  下线当前设备.

            reg:  注册当前设备的 MAC 地址，开启无感认证.

            dereg:  取消当前设备的无感认证.
                注: 此命令貌似总返回 {"result":"success","message":"取消无感认证失败"}

            deregmac <USERNAME> <MAC>:  取消指定设备的无感认证.
                注: 此命令貌似也总返回 {"result":"success","message":"取消无感认证失败"}

            kickall <USERNAME> <PASSWORD>:  下线当前用户的所有设备.

            switch <ISP>:  切换 ISP.
                ISP: CERNET, CT, CU, CMCC

## 自动执行

### cron

每分钟执行一次：

<pre>
*/1 * * * * <em>/path/to/WHU_login.sh</em> -u <em>username</em> -p <em>password</em>
</pre>

### systemd

每 30 秒执行一次：

`/etc/systemd/system/WHU_login.service`

<pre>
[Unit]
Description=Log in to WHU campus network

[Service]
Type=oneshot
User=nobody
ExecStart=<em>/path/to/WHU_login.sh</em> -u <em>username</em> -p <em>password</em>

[Install]
WantedBy=default.target
</pre>

`/etc/systemd/system/WHU_login.timer`

<pre>
[Unit]
Description=Check if logged in to WHU campus network every 30 seconds
After=network-online.target

[Timer]
OnBootSec=10
OnUnitActiveSec=30

[Install]
WantedBy=timers.target
</pre>

启动 timer: `$ sudo systemctl enable --now WHU_login.timer`
