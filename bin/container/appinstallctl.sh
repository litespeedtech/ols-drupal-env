#!/bin/bash
DEFAULT_VH_ROOT='/var/www/vhosts'
VH_DOC_ROOT=''
VHNAME=''
APP_NAME=''
DOMAIN=''
WWW_UID=''
WWW_GID=''
WP_CONST_CONF=''
PUB_IP=$(curl -s http://checkip.amazonaws.com)
MYSQL_HOST='mysql'
EPACE='        '

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
	echo -e "\033[1mOPTIONS\033[0m"
    echow '-A, -app [drupal] -D, --domain [DOMAIN_NAME]'
    echo "${EPACE}${EPACE}Example: appinstallctl.sh --app drupal --domain example.com"
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help and exit."
    exit 0
}

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

linechange(){
    LINENUM=$(grep -n "${1}" ${2} | cut -d: -f 1)
    if [ -n "${LINENUM}" ] && [ "${LINENUM}" -eq "${LINENUM}" ] 2>/dev/null; then
        sed -i "${LINENUM}d" ${2}
        sed -i "${LINENUM}i${3}" ${2}
    fi 
}

get_owner(){
	WWW_UID=$(stat -c "%u" ${DEFAULT_VH_ROOT})
	WWW_GID=$(stat -c "%g" ${DEFAULT_VH_ROOT})
	if [ ${WWW_UID} -eq 0 ] || [ ${WWW_GID} -eq 0 ]; then
		WWW_UID=1000
		WWW_GID=1000
		echo "Set owner to ${WWW_UID}"
	fi
}

get_db_pass(){
	if [ -f ${DEFAULT_VH_ROOT}/${1}/.db_pass ]; then
		SQL_DB=$(grep -i Database ${VH_ROOT}/.db_pass | awk -F ':' '{print $2}' | tr -d '"')
		SQL_USER=$(grep -i Username ${VH_ROOT}/.db_pass | awk -F ':' '{print $2}' | tr -d '"')
		SQL_PASS=$(grep -i Password ${VH_ROOT}/.db_pass | awk -F ':' '{print $2}' | tr -d '"')
	else
		echo 'db pass file can not locate, skip wp-config pre-config.'
	fi
}

set_vh_docroot(){
	if [ "${VHNAME}" != '' ]; then
	    VH_ROOT="${DEFAULT_VH_ROOT}/${VHNAME}"
	    VH_DOC_ROOT="${DEFAULT_VH_ROOT}/${VHNAME}/html"
	elif [ -d ${DEFAULT_VH_ROOT}/${1}/html ]; then
	    VH_ROOT="${DEFAULT_VH_ROOT}/${1}"
        VH_DOC_ROOT="${DEFAULT_VH_ROOT}/${1}/html"
	else
	    echo "${DEFAULT_VH_ROOT}/${1}/html does not exist, please add domain first! Abort!"
		exit 1
	fi	
}

check_sql_native(){
	local COUNTER=0
	local LIMIT_NUM=100
	until [ "$(curl -v mysql:3306 2>&1 | grep -i 'native\|Connected')" ]; do
		echo "Counter: ${COUNTER}/${LIMIT_NUM}"
		COUNTER=$((COUNTER+1))
		if [ ${COUNTER} = 10 ]; then
			echo '--- MySQL is starting, please wait... ---'
		elif [ ${COUNTER} = ${LIMIT_NUM} ]; then	
			echo '--- MySQL is timeout, exit! ---'
			exit 1
		fi
		sleep 1
	done
}

app_drupal_dl(){
    echo 'Download Drupal CMS'
    if [ ! -d "${VH_DOC_ROOT}/sites" ]; then
        composer create-project --no-interaction drupal/recommended-project ${VH_DOC_ROOT}/ >/dev/null 2>&1
        cd ${VH_DOC_ROOT}/ && composer require drush/drush -q
    else
        echo 'Drupal already exist, abort!'
        exit 1
    fi	
}

cache_plugin_dl(){
    echo 'Download Cache Plugin'
    if [ -d "${VH_DOC_ROOT}/web/modules" ] && [ ! -d "${VH_DOC_ROOT}/web/modules/lscache-drupal-master" ]; then 
        cd ${VH_DOC_ROOT}/web/modules
        wget https://github.com/litespeedtech/lscache-drupal/archive/master.zip -O master.zip -q 
        unzip -qq master.zip
        rm -f master.zip
    else
        echo 'Skip cache plugin download!'    
    fi
}


install_drupal(){
	echo 'Install Drupal'
	export COMPOSER_ALLOW_SUPERUSER=1
    cd ${VH_DOC_ROOT}

	drush -y site-install standard \
	    "--db-url=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}/${MYSQL_DATABASE}" \
		"--account-name=${DRUPAL_USERNAME}" \
		"--account-pass=${DRUPAL_PASSWORD}" \
		"--account-mail=${DRUPAL_EMAIL}" \
		"--site-name=${DRUPAL_SITE_NAME}" \
		"--site-mail=${DRUPAL_SITE_EMAIL}"
}

install_lscache(){
	echo 'Install LSCache'
	drush -y config-set system.performance css.preprocess 0 -q
	drush -y config-set system.performance js.preprocess 0 -q
	drush cache-rebuild -q
	drush pm:enable lite_speed_cache
	chmod 777 /var/www/html/web/sites/default/files
}

change_owner(){
	if [ "${VHNAME}" != '' ]; then
		chown -R ${WWW_UID}:${WWW_GID} ${DEFAULT_VH_ROOT}/${VHNAME} 
	else
		chown -R ${WWW_UID}:${WWW_GID} ${DEFAULT_VH_ROOT}/${DOMAIN}
	fi
}

main(){
	set_vh_docroot ${DOMAIN}
	get_owner
	cd ${VH_DOC_ROOT}
	if [ "${APP_NAME}" = 'drupal' ] || [ "${APP_NAME}" = 'dp' ]; then
		check_sql_native
		app_drupal_dl
		cache_plugin_dl
		install_drupal
		install_lscache
		change_owner
		exit 0
	else
		echo "APP: ${APP_NAME} not support, exit!"
		exit 1	
	fi
}

check_input ${1}
while [ ! -z "${1}" ]; do
	case ${1} in
		-[hH] | -help | --help)
			help_message
			;;
		-[aA] | -app | --app) shift
			check_input "${1}"
			APP_NAME="${1}"
			;;
		-[dD] | -domain | --domain) shift
			check_input "${1}"
			DOMAIN="${1}"
			;;
		-vhname | --vhname) shift
			VHNAME="${1}"
			;;	       
		*) 
			help_message
			;;              
	esac
	shift
done
main
