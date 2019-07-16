vim /etc/crontab
30 4 * * * root /bin/sh /bin/mysql-backup > /dev/null 2>&1
