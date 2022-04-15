#!/bin/bash

# Official Sentora Automated Upgrade Script
# =============================================
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Supported Operating Systems: 
# CentOS 8.*/ Minimal, 
# Ubuntu server 18.04, 20.04*/ Minimal,
# 32bit and 64bit
#
# Contributions from:
#
#   Anthony DeBeaulieu (anthony.d@sentora.org
#   Pascal Peyremorte (ppeyremorte@sentora.org)
#   Mehdi Blagui
#   Kevin Andrews (kevin@zvps.uk)
#
#   and all those who participated to this and to previous installers.
#   Thanks to all.

## 
# SENTORA_CORE/UPGRADER_VERSION
# master - latest unstable
# 2.0.0 - example stable tag
##

SENTORA_UPDATER_VERSION="2.0.0-BETA-build-v.1.0.5" # BETA READY
SENTORA_PRECONF_VERSION="dev-master"
SENTORA_CORE_VERSION="dev-master"

PANEL_PATH="/etc/sentora"
PANEL_CONF="/etc/sentora/configs"
SENTORA_CORE_UPGRADE="$HOME/sentora-core-$SENTORA_PRECONF_VERSION"
SENTORA_PRECONF_UPGRADE="$HOME/sentora-installers-$SENTORA_CORE_VERSION"


SENTORA_INSTALLED_DBVERSION=$($PANEL_PATH/panel/bin/setso --show dbversion)
SEN_VER=${SENTORA_INSTALLED_DBVERSION:0:7}
	
#--- Display the 'welcome' splash/user warning info..
echo ""
echo "############################################################################################"
echo "#  Welcome to the Official Sentora Upgrader v."$SENTORA_UPDATER_VERSION"					   #"
echo "############################################################################################"
echo ""
echo -e "\n- Checking that minimal requirements are ok"

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
    VER=${VERFULL:0:1} # return 8*
elif [ -f /etc/lsb-release ]; then
    OS=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
    VER=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
elif [ -f /etc/os-release ]; then
    OS=$(grep -w ID /etc/os-release | sed 's/^.*=//')
    VER=$(grep VERSION_ID /etc/os-release | sed 's/^.*"\(.*\)"/\1/')
else
    OS=$(uname -s)
    VER=$(uname -r)
fi
ARCH=$(uname -m)

echo "- Detected : $OS  $VER  $ARCH"

if [[ "$OS" = "CentOs" && ( "$VER" = "8" ) || 
      "$OS" = "Ubuntu" && ( "$VER" = "18.04" || "$VER" = "20.04" ) ]] ; then
    echo "- Ok."
else
    echo "Sorry, this OS is not supported by Sentora." 
    exit 1
fi

### Ensure that sentora is installed
if [ -d /etc/sentora ]; then
    echo "- Found Sentora, processing..."
else
    echo "Sentora is not installed, aborting..."
    exit 1
fi

### Ensure that sentora v2.0.0 or greater is installed
#if [[ "$SEN_VER" > "2.0.0" ]]; then
 #   echo "- Found Sentora v$SEN_VER, processing..."
#else
 #   echo "Sentora version v2.0.0 is required to install upgrade, you have v$SEN_VER. aborting..."
  #  exit 1
#fi

# Check for some common packages that we know will affect the installation/operating of Sentora.
if [[ "$OS" = "CentOs" ]] ; then
	if [[ "$VER" = "8" ]] ; then
		PACKAGE_INSTALLER="dnf -y -q install"
		PACKAGE_REMOVER="dnf -y -q remove"
	else
		PACKAGE_INSTALLER="yum -y -q install"
		PACKAGE_REMOVER="yum -y -q remove"
	fi
	
	if  [[ "$VER" = "8" ]]; then
		DB_PCKG="mariadb" &&  echo "DB server will be mariaDB"
		DB_SERVICE="mariadb"
	else 
		DB_PCKG="mysql" && echo "DB server will be mySQL"
		DB_SERVICE="mysql"
	fi
	
	HTTP_PCKG="httpd"
	PHP_PCKG="php"
	BIND_PCKG="bind"
	
	HTTP_SERVICE="httpd"
	BIND_SERVICE="bind"
	CRON_SERVICE="crond"
	
elif [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
    PACKAGE_INSTALLER="apt-get -yqq install"
    PACKAGE_REMOVER="apt-get -yqq remove"  
	
	DB_PCKG="mysql-server"
    HTTP_PCKG="apache2"
    BIND_PCKG="bind9"
	
	DB_SERVICE="mysql"
    HTTP_SERVICE="apache2"
    BIND_SERVICE="bind9"
	CRON_SERVICE="cron"
	
fi

# Setup repos for each OS ARCH and update systems
if [[ "$OS" = "CentOs" ]]; then
	if [[ "$VER" = "8" ]]; then
		# Clean & clear cache
		yum clean all
		rm -rf /var/cache/yum/*
                    
		# Install PHP 7.3 Repos & enable
		$PACKAGE_INSTALLER yum-utils
		$PACKAGE_INSTALLER epel-release
		$PACKAGE_INSTALLER http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	fi

elif [[ "$OS" = "Ubuntu" || "$OS" = "CentOs" || "$OS" = "debian" ]]; then
	if [[ "$VER" = "18.04" || "$VER" = "20.04" || "$VER" = "8" ]]; then
	
		apt-get -yqq update
		apt-get -yqq upgrade
	fi
fi


# ***************************************
# Sentora Installation/upgrade really starts here
# ***************************************

# Check OS and Sentora version!
 	
#--- Set custom logging methods so we create a log file in the current working directory.
logfile=$(date +%Y-%m-%d_%H.%M.%S_sentora_upgrade.log)
touch "$logfile"
exec > >(tee "$logfile")
exec 2>&1

extern_ip="$(wget -qO- http://api.sentora.org/ip.txt)"

echo "Upgrader version $SENTORA_UPDATER_VERSION"
echo "Sentora core version $SENTORA_CORE_VERSION"
echo ""
echo "Upgrading Sentora $SENTORA_CORE_VERSION at http://$HOSTNAME and IP: $extern_ip"
echo "on server under: $OS  $VER  $ARCH"
uname -a

# Stop Apache Sentora Services to avoid any user issues while upgrading
echo -e "\n--- Stopping Apache services to avoid issues with connecting users during upgrade..."
echo -e "\n--Stopping Apache service $HTTP_SERVICE..."
service "$HTTP_SERVICE" stop


# Update Sentora Services Below.

# -------------------------------------------------------------------------------
# ProFTPd Below
# -------------------------------------------------------------------------------

# Fix Proftpd using datetime stamp DEFAULT with ZEROS use NULL. Fixes MYSQL 5.7.5+ NO_ZERO_IN_DATE
#mysql -u root -p"$mysqlpassword" < "$SENTORA_PRECONF_UPGRADE"/preconf/sentora-update/2-0-0/sql/4-proftpd-datetime-fix.sql


# -------------------------------------------------------------------------------
# Start Sentora upgrade Below
# -------------------------------------------------------------------------------
# -------------------------------------------------------------------------------
# Start NOW
# -------------------------------------------------------------------------------

#--- Download Sentora Core archive from GitHub
echo -e "\n-- Downloading Sentora, Please wait, this may take several minutes, the installer will continue after this is complete!"
# Get latest sentora
while true; do

	# Sentora REPO
    # wget -nv -O sentora_core.zip https://github.com/sentora/sentora-core/archive/$SENTORA_CORE_VERSION.zip
	wget -nv -O sentora_core.zip https://github.com/Dukecitysolutions/sentora-core-dev/archive/master.zip
	
    if [[ -f sentora_core.zip ]]; then
        break;
    else
        echo "Failed to download sentora core from Github"
        echo "If you quit now, you can run again the installer later."
        read -r -e -p "Press r to retry or q to quit the installer? " resp
        case $resp in
            [Rr]* ) continue;;
            [Qq]* ) exit 3;;
        esac
    fi 
done

# Unzip Sentora core files
unzip -oq sentora_core.zip

# Remove zip file
rm -rf sentora_core.zip

#--- Download Sentora Preconfig archive from GitHub
while true; do

	# Sentora REPO
    # wget -nv -O sentora_preconfig.zip https://github.com/sentora/sentora-installers/archive/$SENTORA_PRECONF_VERSION.zip
	wget -nv -O sentora_preconfig.zip https://github.com/Dukecitysolutions/sentora-installers-dev/archive/master.zip
	
    if [[ -f sentora_preconfig.zip ]]; then
        break;
    else
        echo "Failed to download sentora preconfig from Github"
        echo "If you quit now, you can run again the installer later."
        read -r -e -p "Press r to retry or q to quit the installer? " resp
        case $resp in
            [Rr]* ) continue;;
            [Qq]* ) exit 3;;
        esac
    fi
done

# Unzip Sentora Preconf files
unzip -oq sentora_preconfig.zip

# Remove zip file
rm -rf sentora_preconfig.zip

#
# Update Sentora Preconf files.
#
echo -e "\n--- Updating Sentora Preconf files...\n"

# Update Sentora Apache Template Configs
rm -rf $PANEL_PATH/configs/apache/templates
cp -R "$SENTORA_PRECONF_UPGRADE"/preconf/apache/templates $PANEL_PATH/configs/apache/

# Set templates folder to 0755 permissions
chmod -R 0755 $PANEL_PATH/configs/apache/templates

# Set templates to 0644 permissions
chmod -R 0644 $PANEL_PATH/configs/apache/templates/*

#
# Update Sentora Core files.
#
echo -e "\n--- Updating Sentora Core files...\n"

# Upgrade Sentora Dryden files
rm -rf $PANEL_PATH/panel/dryden
cp -R "$SENTORA_CORE_UPGRADE"/dryden $PANEL_PATH/panel/

# Set Dryden to 0777 permissions
chmod -R 0777 $PANEL_PATH/panel/dryden

# Delete All Default core modules for upgrade/updates. Leave Third-party - There might be a better way to do this.
    ## Removing core Modules for upgrade
    # rm -rf $PANEL_PATH/panel/bin/
    # rm -rf $PANEL_PATH/panel/dryden/
    # rm -rf $PANEL_PATH/panel/etc/
    # rm -rf $PANEL_PATH/panel/inc/
    # rm -rf $PANEL_PATH/panel/index.php
    # rm -rf $PANEL_PATH/panel/LICENSE.md
    # rm -rf $PANEL_PATH/panel/README.md
    # rm -rf $PANEL_PATH/panel/robots.txt
    rm -rf $PANEL_PATH/panel/modules/aliases
    rm -rf $PANEL_PATH/panel/modules/apache_admin
    rm -rf $PANEL_PATH/panel/modules/backup_admin
    rm -rf $PANEL_PATH/panel/modules/backupmgr
    rm -rf $PANEL_PATH/panel/modules/client_notices
    rm -rf $PANEL_PATH/panel/modules/cron
    rm -rf $PANEL_PATH/panel/modules/distlists
    rm -rf $PANEL_PATH/panel/modules/dns_admin
    rm -rf $PANEL_PATH/panel/modules/dns_manager
    rm -rf $PANEL_PATH/panel/modules/domains
    rm -rf $PANEL_PATH/panel/modules/faqs
    rm -rf $PANEL_PATH/panel/modules/forwarders
    rm -rf $PANEL_PATH/panel/modules/ftp_admin
    rm -rf $PANEL_PATH/panel/modules/ftp_management
    rm -rf $PANEL_PATH/panel/modules/mail_admin
    rm -rf $PANEL_PATH/panel/modules/mailboxes
    rm -rf $PANEL_PATH/panel/modules/manage_clients
    rm -rf $PANEL_PATH/panel/modules/manage_groups
    rm -rf $PANEL_PATH/panel/modules/moduleadmin
    rm -rf $PANEL_PATH/panel/modules/my_account
    rm -rf $PANEL_PATH/panel/modules/mysql_databases
    rm -rf $PANEL_PATH/panel/modules/mysql_users
    rm -rf $PANEL_PATH/panel/modules/news
    rm -rf $PANEL_PATH/panel/modules/packages
    rm -rf $PANEL_PATH/panel/modules/parked_domains
    rm -rf $PANEL_PATH/panel/modules/password_assistant
    rm -rf $PANEL_PATH/panel/modules/phpinfo
    rm -rf $PANEL_PATH/panel/modules/phpmyadmin
    rm -rf $PANEL_PATH/panel/modules/phpsysinfo
	rm -rf $PANEL_PATH/panel/modules/protected_directories
	rm -rf $PANEL_PATH/panel/modules/sentoraconfig
    rm -rf $PANEL_PATH/panel/modules/services
    rm -rf $PANEL_PATH/panel/modules/shadowing
    rm -rf $PANEL_PATH/panel/modules/sub_domains
    rm -rf $PANEL_PATH/panel/modules/theme_manager
    rm -rf $PANEL_PATH/panel/modules/updates
    rm -rf $PANEL_PATH/panel/modules/usage_viewer
    rm -rf $PANEL_PATH/panel/modules/webalizer_stats
    rm -rf $PANEL_PATH/panel/modules/webmail
    rm -rf $PANEL_PATH/panel/modules/zpanelconfig
    rm -rf $PANEL_PATH/panel/modules/zpx_core_module
	
# Upgrade all modules with new files from master core.
cp -R "$SENTORA_CORE_UPGRADE"/modules/* $PANEL_PATH/panel/modules/

# Set all modules to 0777 permissions
chmod -R 0777 $PANEL_PATH/panel/modules/*


# -------------------------------------------------------------------------------
# Update Sentora APACHE_CHANGED, DBVERSION and run DAEMON
# -------------------------------------------------------------------------------

# Set dbversion
$PANEL_PATH/panel/bin/setso --set dbversion "$SENTORA_UPDATER_VERSION"

# Set apache daemon to build vhosts file.
$PANEL_PATH/panel/bin/setso --set apache_changed "true"
	
# Run Daemon
php -d "sp.configuration_file=/etc/sentora/configs/php/sp/sentora.rules" -q $PANEL_PATH/panel/bin/daemon.php		
echo ""

# Clean up files needed for install/update
rm -rf sentora-core-$SENTORA_CORE_VERSION
rm -rf sentora-installers-$SENTORA_PRECONF_VERSION


#--- Restart all services to capture output messages, if any
if [[ "$OS" = "CentOs" && "$VER" == "8" ]]; then
    # CentOs7 does not return anything except redirection to systemctl :-(
    service() {
       echo "Restarting $1"
       systemctl restart "$1.service"
    }
fi

echo -e "# -------------------------------------------------------------------------------"

echo -e "\n--- Restarting Services"
echo -e "Restarting $DB_SERVICE..."
service "$DB_SERVICE" restart
echo -e "Restarting $HTTP_SERVICE..."
service "$HTTP_SERVICE" restart
echo -e "Restarting Postfix..."
service postfix restart
echo -e "Restarting Dovecot..."
service dovecot restart
echo -e "Restarting CRON..."
service "$CRON_SERVICE" restart
echo -e "Restarting Bind9/Named..."
service "$BIND_SERVICE" restart
echo -e "Restarting Proftpd..."
service proftpd restart
echo -e "Restarting ATD..."
service atd restart

echo -e "\n--- Finished Restarting Services...\n"


echo -e "\n--- Done Upgrading all Sentora core files\n"

# Wait until the user have read before restarts the server...
if [[ "$INSTALL" != "auto" ]] ; then
    while true; do
		
        read -r -e -p "Restart your server now to complete the install (y/n)? " rsn
        case $rsn in
            [Yy]* ) break;;
            [Nn]* ) exit;
        esac
    done
    shutdown -r now
fi