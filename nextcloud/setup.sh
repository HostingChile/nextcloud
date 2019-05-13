#!/bin/sh

run_occ() {
  su -p www-data -s /bin/sh -c "php /var/www/html/occ $1"
}

run_occ 'maintenance:mode --on'
run_occ 'db:convert-filecache-bigint -n'
run_occ 'background:cron'
run_occ 'config:system:set overwriteprotocol --value="https"'
run_occ 'config:system:set forwarded_for_headers 0 --value=HTTP_X_FORWARDED_FOR'
run_occ 'config:system:set trusted_proxies 0 --value="$(hostname -i | cut -d. -f1-3).1"'
run_occ 'app:install occweb'
run_occ 'app:install apporder'
run_occ 'app:install external'
run_occ 'app:install drawio'
run_occ 'app:install extract'
run_occ 'app:install files_accesscontrol'
run_occ 'app:enable occweb -g admin'
run_occ 'maintenance:mode --off'
