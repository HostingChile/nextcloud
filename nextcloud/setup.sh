#!/bin/sh

run_occ() {
  su -p www-data -s /bin/sh -c "php /var/www/html/occ $1"
}


run_occ 'db:convert-filecache-bigint'
run_occ 'background:cron'
run_occ 'config:system:set overwriteprotocol --value="https"'
run_occ 'config:system:set forwarded_for_headers 0 --value=HTTP_X_FORWARDED_FOR'
run_occ 'config:system:set trusted_proxies 0 --value="$(hostname -i | cut -d. -f1-3).1"'
