#!/bin/bash
set -eu

run_occ() {
  su -p www-data -s /bin/sh -c "php /var/www/html/occ $1" || true
}

install_update_app() {
  run_occ "app:install $1" || run_occ "app:update $1"
}

if [[ $SKIP_INITIAL_SETUP != "1" ]] && [[ ! "$(run_occ 'config:system:get inital_setup_completed' | tail -n1)" == "yes" ]];then
	echo "Initial setup started"

	# Check if Nextcloud is installed
	run_occ 'status' | grep -q "installed: true" || { echo "Nextcloud is not installed yet"; exit 1; }

	# System config
	run_occ 'db:convert-filecache-bigint -n'
	run_occ 'background:cron'
	run_occ 'config:system:set forwarded_for_headers 0 --value=HTTP_X_FORWARDED_FOR'
	run_occ 'config:system:set default_locale --value=es_CL'

	# Proxy config
	run_occ 'config:system:set trusted_proxies 0 --value="$(hostname -i | cut -d. -f1-3).0/24"'
	run_occ 'config:system:set overwrite.cli.url --value="https://$NEXTCLOUD_TRUSTED_DOMAINS"'
	run_occ 'config:system:set overwritehost --value="$NEXTCLOUD_TRUSTED_DOMAINS"'
	run_occ 'config:system:set overwriteprotocol --value=https'
	run_occ 'maintenance:update:htaccess'

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

	# Install OnlyOffice app
	install_update_app "onlyoffice"
	run_occ "config:app:set onlyoffice DocumentServerInternalUrl --value=https://${ONLYOFFICE_URL}/"
	run_occ "config:app:set onlyoffice DocumentServerUrl --value=https://${ONLYOFFICE_URL}/"
	run_occ "config:app:set onlyoffice StorageUrl --value=https://$NEXTCLOUD_TRUSTED_DOMAINS/"
	run_occ 'config:app:set onlyoffice defFormats --value={\"csv\":\"true\",\"doc\":\"true\",\"docm\":\"true\",\"docx\":\"true\",\"dotx\":\"true\",\"epub\":\"true\",\"html\":\"true\",\"odp\":\"true\",\"ods\":\"true\",\"odt\":\"true\",\"potm\":\"true\",\"potx\":\"true\",\"ppsm\":\"true\",\"ppsx\":\"true\",\"ppt\":\"true\",\"pptm\":\"true\",\"pptx\":\"true\",\"rtf\":\"true\",\"xls\":\"true\",\"xlsm\":\"true\",\"xlsx\":\"true\",\"xltm\":\"true\",\"xltx\":\"true\"}'
	run_occ 'config:app:set onlyoffice editFormats --value={\"csv\":\"true\",\"odp\":\"true\",\"ods\":\"true\",\"odt\":\"true\",\"rtf\":\"true\"}'

	# Install and configure antivirus if it is reachable
	install_update_app "files_antivirus"
	run_occ "config:app:set files_antivirus av_host --value=antivirus"
	run_occ "config:app:set files_antivirus av_infected_action --value=delete"
	run_occ "config:app:set files_antivirus av_mode --value=daemon"
	run_occ "config:app:set files_antivirus av_port --value=3310"

	# Default apps install and update
  DEFAULT_APPS="announcementcenter,apporder,calendar,checksum,contacts,drawio,extract,files_accesscontrol,files_automatedtagging,files_downloadactivity,files_mindmap,files_retention,files_trackdownloads,groupfolders,guests,ldap_write_support,quickaccesssorting,tasks"
	for APP in ${DEFAULT_APPS//,/ };do
		install_update_app "$APP"
	done;

	run_occ "config:app:set files_sharing incoming_server2server_share_enabled --value=no"
	run_occ "config:app:set files_sharing lookupServerEnabled --value=no"
	run_occ "config:app:set files_sharing lookupServerUploadEnabled --value=no"
	run_occ "config:app:set files_sharing outgoing_server2server_share_enabled --value=no"
		
	if [ "$LDAP_ENABLED" == "yes" ];then
		echo "LDAP setup started"

		run_occ "app:enable user_ldap"

		run_occ "ldap:create-empty-config"

		run_occ "ldap:set-config s01 ldapHost ldap"
		run_occ "ldap:set-config s01 ldapPort 389"

		run_occ "ldap:set-config s01 ldapAgentName cn=admin,${LDAP_BASE_DN}"
		run_occ "ldap:set-config s01 ldapAgentPassword '${LDAP_PASSWORD}'"

		run_occ "ldap:set-config s01 ldapBase ${LDAP_BASE_DN}"
		run_occ "ldap:set-config s01 ldapBaseGroups ou=Groups,${LDAP_BASE_DN}"
		run_occ "ldap:set-config s01 ldapBaseUsers ou=Users,${LDAP_BASE_DN}"

		run_occ "ldap:set-config s01 ldapExpertUsernameAttr cn"

		run_occ "ldap:set-config s01 ldapGroupDisplayName cn"
		run_occ "ldap:set-config s01 ldapGroupFilter '(&(objectclass=groupOfNames))'"
		run_occ "ldap:set-config s01 ldapGroupFilterMode 1"

		run_occ "ldap:set-config s01 ldapLoginFilter '(&(cn=%uid))'"
		run_occ "ldap:set-config s01 ldapLoginFilterMode 1"

		run_occ "ldap:set-config s01 ldapUserDisplayName displayName"
		run_occ "ldap:set-config s01 ldapUserFilter '(&(objectClass=hSuiteUser))'"
		run_occ "ldap:set-config s01 ldapUserFilterMode 1"

		run_occ "ldap:set-config s01 turnOnPasswordChange 1"
		run_occ "ldap:set-config s01 ldapQuotaAttribute quota"
		
		run_occ "ldap:set-config s01 ldapConfigurationActive 1"

		echo "LDAP setup finished"
	fi

	echo "Initial setup finished" && run_occ "config:system:set inital_setup_completed --value=yes"
else
	echo "Initial setup skipped. Run 'config:system:set inital_setup_completed --value=no' to allow initial setup"
fi

exec "$@"
