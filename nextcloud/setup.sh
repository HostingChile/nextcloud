#!/bin/bash

run_occ() {
    su -p www-data -s /bin/sh -c "php /var/www/html/occ $1"
}

install_update_app() {
    run_occ "app:install $1" || run_occ "app:update $1"
}

# Check if Nextcloud is installed
run_occ 'status' | head -n1 | grep -q true || { echo "Nextcloud is not installed yet"; exit 1; }

# Needed config
run_occ 'db:convert-filecache-bigint -n'
run_occ 'background:cron'
run_occ 'config:system:set overwriteprotocol --value=https'
run_occ 'config:system:set forwarded_for_headers 0 --value=HTTP_X_FORWARDED_FOR'
run_occ 'config:system:set trusted_proxies 0 --value="$(hostname -i | cut -d. -f1-3).1"'
run_occ 'config:system:set default_locale --value=es_CL'

# Set base structure for new users
BASE_FOLDER="/var/www/html/data/admin/files/Base"
if [ ! -d "$BASE_FOLDER" ];then
    mkdir $BASE_FOLDER
    chown www-data:www-data $BASE_FOLDER
fi
run_occ 'files:scan --path="/admin/files"'
run_occ "config:system:set skeletondirectory --value=$BASE_FOLDER"

# Check if apps API is available
curl -sf -m20 https://apps.nextcloud.com > /dev/null || { echo "Apps API not available"; exit 2; }

# Install selected document editor
if [ "$DOCUMENT_EDITOR" == "collabora" ];then
    run_occ "app:remove onlyoffice"
    install_update_app "richdocuments"
    run_occ "config:app:set richdocuments wopi_url --value=https://$DOCUMENT_EDITOR_HOST"
elif [ "$DOCUMENT_EDITOR" == "onlyoffice" ];then
    run_occ "app:remove richdocuments"
    install_update_app "onlyoffice"
    run_occ "config:app:set onlyoffice DocumentServerInternalUrl --value=https://$DOCUMENT_EDITOR_HOST/"
    run_occ "config:app:set onlyoffice DocumentServerUrl --value=https://$DOCUMENT_EDITOR_HOST/"
    run_occ "config:app:set onlyoffice StorageUrl --value=https://$VIRTUAL_HOST/"
    run_occ 'config:app:set onlyoffice defFormats --value={\"csv\":\"true\",\"doc\":\"true\",\"docm\":\"true\",\"docx\":\"true\",\"dotx\":\"true\",\"epub\":\"true\",\"html\":\"true\",\"odp\":\"true\",\"ods\":\"true\",\"odt\":\"true\",\"potm\":\"true\",\"potx\":\"true\",\"ppsm\":\"true\",\"ppsx\":\"true\",\"ppt\":\"true\",\"pptm\":\"true\",\"pptx\":\"true\",\"rtf\":\"true\",\"txt\":\"true\",\"xls\":\"true\",\"xlsm\":\"true\",\"xlsx\":\"true\",\"xltm\":\"true\",\"xltx\":\"true\"}'
    run_occ 'config:app:set onlyoffice editFormats --value={\"csv\":\"true\",\"odp\":\"true\",\"ods\":\"true\",\"odt\":\"true\",\"rtf\":\"true\",\"txt\":\"true\"}'
fi

# Install and configure antivirus if it is reachable
curl antivirus:3310
if [ $? -eq 0 ];then 
	install_update_app "files_antivirus"
	run_occ "config:app:set files_antivirus av_host --value=antivirus"
	run_occ "config:app:set files_antivirus av_infected_action --value=delete"
	run_occ "config:app:set files_antivirus av_mode --value=daemon"
	run_occ "config:app:set files_antivirus av_port --value=3310"
fi

# Default apps install and update
for APP in ${DEFAULT_APPS//,/ } ${DEFAULT_ADMIN_APPS//,/ };do
    install_update_app "$APP"
done;

# Apps for admin only
for APP in ${DEFAULT_ADMIN_APPS//,/ };do
    run_occ "app:enable $APP -g admin"
done;