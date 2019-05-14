#!/bin/bash

run_occ() {
  su -p www-data -s /bin/sh -c "php /var/www/html/occ $1"
}

# Check if NextCloud is installed
run_occ 'status' | head -n1 | grep -q true || (echo "Nextcloud is not installed yet" && exit 1)

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
    run_occ "config:app:set onlyoffice DocumentServerInternalUrl --value=https://$ONLYOFFICE_VIRTUAL_HOST/"
    run_occ "config:app:set onlyoffice DocumentServerUrl --value=https://$ONLYOFFICE_VIRTUAL_HOST/"
    run_occ "config:app:set onlyoffice StorageUrl --value=https://$VIRTUAL_HOST/"
    run_occ 'config:app:set onlyoffice defFormats --value={\"csv\":\"true\",\"doc\":\"true\",\"docm\":\"true\",\"docx\":\"true\",\"dotx\":\"true\",\"epub\":\"true\",\"html\":\"true\",\"odp\":\"true\",\"ods\":\"true\",\"odt\":\"true\",\"pdf\":\"true\",\"potm\":\"true\",\"potx\":\"true\",\"ppsm\":\"true\",\"ppsx\":\"true\",\"ppt\":\"true\",\"pptm\":\"true\",\"pptx\":\"true\",\"rtf\":\"true\",\"txt\":\"true\",\"xls\":\"true\",\"xlsm\":\"true\",\"xlsx\":\"true\",\"xltm\":\"true\",\"xltx\":\"true\"}'
    run_occ 'config:app:set onlyoffice editFormats --value={\"csv\":\"true\",\"odp\":\"true\",\"ods\":\"true\",\"odt\":\"true\",\"rtf\":\"true\",\"txt\":\"true\"}'
fi

# Apps install
for APP in ${DEFAULT_APPS//,/ } ${DEFAULT_ADMIN_APPS//,/ };do
    run_occ "app:install $APP"
done;

# Apps for admin only
for APP in ${DEFAULT_ADMIN_APPS//,/ };do
    run_occ "app:enable $APP -g admin"
done;

# Set base structure for new users
BASE_FOLDER="/var/www/html/data/admin/files/Base"
mkdir $BASE_FOLDER
chown www-data:www-data $BASE_FOLDER
run_occ 'files:scan --path="/admin/files"'
run_occ 'config:system:set skeletondirectory --value=$BASE_FOLDER'

# Maintenance mode off
run_occ 'maintenance:mode --off'
