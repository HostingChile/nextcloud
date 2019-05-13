#!/bin/bash

run_occ() {
  su -p www-data -s /bin/sh -c "php /var/www/html/occ $1"
}

# Maintenance mode on
run_occ 'maintenance:mode --on'

# Needed config
run_occ 'db:convert-filecache-bigint -n'
run_occ 'background:cron'
run_occ 'config:system:set overwriteprotocol --value="https"'
run_occ 'config:system:set forwarded_for_headers 0 --value=HTTP_X_FORWARDED_FOR'
run_occ 'config:system:set trusted_proxies 0 --value="$(hostname -i | cut -d. -f1-3).1"'

# Install selected doc editor
if [ "$DOCS_EDITOR" == "collabora" ];then
    run_occ "app:install richdocuments"
elif [ "$DOCS_EDITOR" == "onlyoffice" ];then
    run_occ "app:install onlyoffice"
fi

# Apps install
for APP in ${DEFAULT_APPS//,/ } ${DEFAULT_ADMIN_APPS//,/ };do
    run_occ "app:install $APP"
done;

# Apps for admin only
for APP in ${DEFAULT_ADMIN_APPS//,/ };do
    run_occ "app:enable $APP -g admin"
done;

# Maintenance mode off
run_occ 'maintenance:mode --off'
