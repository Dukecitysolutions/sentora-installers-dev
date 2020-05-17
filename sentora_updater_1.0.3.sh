#!/usr/bin/env bash

SENTORA_UPDATER_VERSION="1.0.3"
PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"

# Check if the user is 'root' before updating
if [ $UID -ne 0 ]; then
    echo "Install failed: you must be logged in as 'root' to install."
    echo "Use command 'sudo -i', then enter root password and then try again."
    exit 1
fi
# Ensure the OS is compatible with the launcher
if [ -f /etc/centos-release ]; then
    OS="CentOs"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 6 or 7
elif [ -f /etc/lsb-release ]; then
    OS=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
    VER=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
else
    OS=$(uname -s)
    VER=$(uname -r)
fi
ARCH=$(uname -m)

echo "Detected : $OS  $VER  $ARCH"

### Ensure that sentora is installed
if [ -d /etc/sentora ]; then
    echo "Found Sentora, processing"
else
    echo "Sentora is not installed, aborting..."
    exit 1
fi

# FTP Patch
cd /tmp/
wget -O hotfix_controller.ext.php "https://raw.githubusercontent.com/sentora/sentora-core/b176df0e29e52e14d778ca6cb47c5765cf3c4953/modules/ftp_management/code/controller.ext.php"
mv /etc/sentora/panel/modules/ftp_management/code/controller.ext.php controller.ext.php_backup
mv hotfix_controller.ext.php /etc/sentora/panel/modules/ftp_management/code/controller.ext.php
chown root:root /etc/sentora/panel/modules/ftp_management/code/controller.ext.php
chmod 777 /etc/sentora/panel/modules/ftp_management/code/controller.ext.php

# CGI Patch
disable_file() {
    mv "$1" "$1_disabled_by_sentora" &> /dev/null
}

if [[ "$OS" = "CentOs" ]]; then
    HTTP_CONF_PATH="/etc/httpd/conf/httpd.conf"
    HTTP_VARS_PATH="/etc/sysconfig/httpd"
    HTTP_SERVICE="httpd"
    HTTP_USER="apache"
    HTTP_GROUP="apache"
    if [[ "$VER" = "7" ]]; then
        # Disable extra modules in centos 7
        disable_file /etc/httpd/conf.modules.d/01-cgi.conf
        disable_file /etc/httpd/conf.modules.d/00-lua.conf
        disable_file /etc/httpd/conf.modules.d/00-dav.conf
        service httpd restart
    else
        disable_file /etc/httpd/conf.d/welcome.conf
        disable_file /etc/httpd/conf.d/webalizer.conf
        # Disable more extra modules in centos 6.x /etc/httpd/httpd.conf dav/ldap/cgi/proxy_ajp
	    sed -i "s|LoadModule suexec_module modules|#LoadModule suexec_module modules|" "$HTTP_CONF_PATH"
	    sed -i "s|LoadModule cgi_module modules|#LoadModule cgi_module modules|" "$HTTP_CONF_PATH"
	    sed -i "s|LoadModule dav_module modules|#LoadModule dav_module modules|" "$HTTP_CONF_PATH"
	    sed -i "s|LoadModule dav_fs_module modules|#LoadModule dav_fs_module modules|" "$HTTP_CONF_PATH"
	    sed -i "s|LoadModule proxy_ajp_module modules|#LoadModule proxy_ajp_module modules|" "$HTTP_CONF_PATH"
	    service httpd restart
    fi
fi

#Suhosin patch for sentora 1.0.0

SUHOSIN_VERSION="0.9.37.1"
wget -nv -O suhosin.zip https://github.com/stefanesser/suhosin/archive/$SUHOSIN_VERSION.zip
unzip -q suhosin.zip
rm -f suhosin.zip
cd suhosin-$SUHOSIN_VERSION
phpize 
./configure 
make
make install 
cd ..
rm -rf suhosin-$SUHOSIN_VERSION

## SQL patch now
# get mysql root password, check it works or ask it
mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
while ! mysql -u root -p$mysqlpassword -e ";" ; do
read -p "Can't connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
done
echo -e "Connection mysql ok"
wget -nv -O  update.sql https://raw.githubusercontent.com/sentora/sentora-installers/master/preconf/sentora-update/1-0-3/sql/update.sql #need url
mysql -u root -p"$mysqlpassword" < update.sql

echo "We are done system patched updater $SENTORA_UPDATER_VERSION"