# WHU_captive_portal_login

用于登录武汉大学校园网的 Shell 脚本，依赖于 `curl` 。

## 用法

    WHU_login.sh -u <USERNAME> -p <PASSWORD> [-t <TYPE>]
    
                 TYPE: CERNET, CT, CU, CMCC.
                       CERNET: 教育网.
                       CT:     中国电信.
                       CU:     中国联通.
                       CMCC:   中国移动.
                       默认选项是教育网.

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
