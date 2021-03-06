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
# Ubuntu server 16.04  
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
# 1.0.3 - example stable tag
##

SENTORA_UPDATER_VERSION="2.0.0" # PRODUCTION READY
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
    VER=${VERFULL:0:1} # return 6 or 7
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
      "$OS" = "Ubuntu" && ( "$VER" = "16.04" ) ]] ; then
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

### Ensure that sentora v1.0.3 or greater is installed
#if [[ "$SEN_VER" > "1.0.2" ]]; then
 #   echo "- Found Sentora v$SEN_VER, processing..."
#else
 #   echo "Sentora version v1.0.3 is required to install, you have v$SEN_VER. aborting..."
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
	
	if  [[ "$VER" = "7" || "$VER" = "8" ]]; then
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
	if [[ "$VER" = "7" ]]; then
		# Clean & clear cache
		yum clean all
		rm -rf /var/cache/yum/*
                    
		# Install PHP 7.3 Repos & enable
		$PACKAGE_INSTALLER yum-utils
		$PACKAGE_INSTALLER epel-release
		$PACKAGE_INSTALLER http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	fi

elif [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
	if [[ "$VER" = "16.04" || "$VER" = "8" ]]; then
	
		apt-get -yqq update
		apt-get -yqq upgrade
	fi
fi


# ***************************************
# Installation really starts here

echo -e "\n# -------------------------------------------------------------------------------"

#--- Setup Sentora admin contact info

echo -e "\n--- Please Enter vaild contact info for the Sentora system admin or owner below:\n"

# Get Admin contact info 
# ---- Name
while true
do
    read -r -e -p "Enter Full name: " -i "$ADMIN_NAME" ADMIN_NAME
    echo
    if [ ! -z "$ADMIN_NAME" ]
    then
        break
    else
        echo "Entry is Blank. Try again."
    fi
done

# --- Email
while true
do
    read -r -e -p "Enter admin email: " -i "$ADMIN_EMAIL" ADMIN_EMAIL
    echo
    if [[ "$ADMIN_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]
    then
        break
    else
        echo "Email address $ADMIN_EMAIL is invalid."
    fi
done

# ---- Phone Number
while true
do
    read -r -e -p "Enter Phone Number: " -i "$ADMIN_PHONE" ADMIN_PHONE
    echo
    if [ ! -z "$ADMIN_PHONE" ]
    then
        break
    else
        echo "Entry is Blank. Try again."
    fi
done

# ---- Address
while true
do
    read -r -e -p "Enter Street Address: " -i "$ADMIN_ADDRESS" ADMIN_ADDRESS
    echo
    if [ ! -z "$ADMIN_ADDRESS" ]
    then
        break
    else
        echo "Entry is Blank. Try again."
    fi
done

# ---- Address - City, State or Province
while true
do
    read -r -e -p "Enter City, State or Province: " -i "$ADMIN_PROVINCE" ADMIN_PROVINCE
    echo
    if [ ! -z "$ADMIN_PROVINCE" ]
    then
        break
    else
        echo "Entry is Blank. Try again."
    fi
done

# ---- Address - Postal code
while true
do
    read -r -e -p "Enter Postal code: " -i "$ADMIN_POSTALCODE" ADMIN_POSTALCODE
    echo
    if [ ! -z "$ADMIN_POSTALCODE" ]
    then
        break
    else
        echo "Entry is Blank. Try again."
    fi
done

# ---- Address - Country
while true
do
    read -r -e -p "Enter Country: " -i "$ADMIN_COUNTRY" ADMIN_COUNTRY
    echo
    if [ ! -z "$ADMIN_COUNTRY" ]
    then
        break
    else
        echo "Entry is Blank. Try again."
    fi
done


echo -e "\n# -------------------------------------------------------------------------------\n"


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
echo -e "\nStopping $HTTP_SERVICE..."
service "$HTTP_SERVICE" stop

#--- Apache+Mod_SSL
echo -e "\n--- Installing Apache MOD_SSL\n"
if [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
	if [[ "$VER" = "16.04" || "$VER" = "18.04" || "$VER" = "20.04" || "$VER" = "8" ]]; then
		# Install Mod_ssl & openssl
		#$PACKAGE_INSTALLER mod_ssl
		$PACKAGE_INSTALLER openssl
		
		# Activate mod_ssl
		a2enmod ssl 
	fi
	
elif [[ "$OS" = "CentOs" ]]; then
	if [[ "$VER" = "7" || "$VER" = "8" ]]; then
		# Install Mod_ssl & openssl
		$PACKAGE_INSTALLER mod_ssl
		$PACKAGE_INSTALLER openssl
		
		# Disable/Comment out Listen 443
		sed -i 's|Listen 443 https|#Listen 443 https|g' /etc/httpd/conf.d/ssl.conf
	fi
fi

#--- PHP
# Install PHP 7.x
   
    if [[ "$OS" = "CentOs" ]]; then
		if [[ "$VER" = "7" ]]; then
		
			echo -e "\n-Installing REMI-repo PHP 7.3 version..."
		
			## Start PHP 7.x install here
			yum clean all
			rm -rf /var/cache/yum/*
			
			$PACKAGE_INSTALLER yum-utils
			$PACKAGE_INSTALLER epel-release
			$PACKAGE_INSTALLER http://rpms.remirepo.net/enterprise/remi-release-7.rpm
		
			## Install PHP 7.3 and update modules
			
			##yum -y install httpd mod_ssl php php-zip php-fpm php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel php-intl php-imagick php-pspell wget
			
			yum -y --enablerepo=remi-php73 install php php-devel php-gd php-mcrypt php-mysql php-xml php-xmlrpc php-zip
				
		elif [[ "$VER" = "8" ]]; then
		
			echo -e "\n-Installing Default OS PHP 7.2 version..."
		
			## Install PHP 7.2 and update modules
		
			$PACKAGE_INSTALLER php php-devel php-gd php-json php-mbstring php-intl php-mysqlnd php-pear php-xml php-xmlrpc php-zip
            
            
            # Get mcrypt, pear and imap files
			echo -e "\n--- Getting PHP-mcrypt files..."
			$PACKAGE_INSTALLER libmcrypt-devel libmcrypt #Epel packages 
			
			# Install php-imap 
			echo -e "\n--- Installing PHP-imap..."
			wget https://rpms.remirepo.net/temp/epel-8-php-7.2/php-imap-7.2.24-1.epel8.7.2.x86_64.rpm
			$PACKAGE_INSTALLER php-imap-7.2.24-1.epel8.7.2.x86_64.rpm
			#rm -r php-imap-7.2.24-1.epel8.7.2.x86_64.rpm
			

            # Enable Mod_php & Prefork for Apache/PHP 7.3
            sed -i 's|#LoadModule mpm_prefork_module|LoadModule mpm_prefork_module|g' /etc/httpd/conf.modules.d/00-mpm.conf
            sed -i 's|LoadModule mpm_event_module|#LoadModule mpm_event_module|g' /etc/httpd/conf.modules.d/00-mpm.conf
			
			
			# PHP-mcrypt install code all OS - Check this!!!!!!
            
    		# Update Pecl Channels
			echo -e "\n--- Updating PECL Channels..."
    		pecl channel-update pecl.php.net
    		pecl update-channels
                    
    		# Install PHP-Mcrypt
			echo -e "\n--- Installing PHP-mcrypt..."
    		echo -ne '\n' | sudo pecl install mcrypt
			
			# Set mcrypt files		
			touch /etc/php.d/20-mcrypt.ini
			echo 'extension=mcrypt.so' >> /etc/php.d/20-mcrypt.ini
			
		fi
		
		PHP_INI_PATH="/etc/php.ini"
        
	elif [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
		
		if [[ "$VER" = "16.04" ]]; then
			echo -e "\n-Installing OS Default PHP 7.0 version..."
			
			# Remove and purge installed PHP 5.x system copied over
			$PACKAGE_REMOVER php5.*
			apt-get purge php5.*
			
			$PACKAGE_INSTALLER libapache2-mod-php7.0 php7.0-common php7.0-cli php7.0-mysql php7.0-gd php7.0-mcrypt php7.0-curl php-pear php7.0-imap php7.0-xmlrpc php7.0-xsl php7.0-intl php-mbstring php7.0-mbstring php-gettext php7.0-dev php7.0-zip
			
			# Fix missing php.ini settings sentora needs
			echo -e "\n--- Fix missing php.ini settings sentora needs in Ubuntu 16.04 php 7.0 ..."
			echo "setting upload_tmp_dir = /var/sentora/temp/"
			echo ""
			sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.0/apache2/php.ini
			echo "Setting session.save_path = /var/sentora/sessions"
			sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.0/apache2/php.ini
			
			PHP_INI_PATH="/etc/php/7.0/apache2/php.ini"
			
			# Enable Apache mod_php7.0
			sudo a2enmod php7.0
		fi		
	fi

# PHP END
# -------------------------------------------------------------------------------
	
##### Check php 7.x was installed or quit installer.
PHPVERFULL=$(php -r 'echo phpversion();')
PHPVER=${PHPVERFULL:0:3} # return 5.x or 7.x
	
echo -e "\nDetected PHP: $PHPVER "

if  [[ "$PHPVER" == 7.* ]]; then
	echo -e "\nPHP $PHPVER installed. Procced installing ..."
else
	echo -e "\nPHP 7.x not installed. $PHPVER installed. Exiting installer. Please contact script admin"
	exit 1
fi
	
# -------------------------------------------------------------------------------
# Start Snuffleupagus v.0.5.x install Below
# -------------------------------------------------------------------------------
	
echo -e "\n--- Installing Snuffleupagus..."
	
# Install Snuffleupagus
# Install git
$PACKAGE_INSTALLER git

if [[ "$OS" = "Ubuntu" && ( "$VER" = "16.04" ) ]]; then
	# update OLD CA certificates
	sudo apt-get install apt-transport-https ca-certificates -y
	sudo update-ca-certificates
fi
	
# Setup PHP_PERDIR in Snuffleupagus.c in src
mkdir -p /etc/snuffleupagus
cd /etc || exit
	
# Clone Snuffleupagus
echo -e "\n--- Downloading Snuffleupagus..."
git clone https://github.com/nbs-system/snuffleupagus
		
cd /etc/snuffleupagus/src || exit
		
sed -i 's|PHP_INI_SYSTEM|PHP_INI_PERDIR|g' snuffleupagus.c
		
phpize
./configure --enable-snuffleupagus
make clean
make
make install
	
cd ~ || exit
	
# Setup Snuffleupagus Rules
mkdir /etc/sentora/configs/php
mkdir /etc/sentora/configs/php/sp
touch /etc/sentora/configs/php/sp/snuffleupagus.rules
	
if [[ "$OS" = "CentOs" && ( "$VER" = "7" || "$VER" = "8" ) ]]; then
	
	# Enable snuffleupagus in PHP.ini
	echo -e "\nUpdating CentOS PHP.ini Enable snuffleupagus..."
	echo "extension=snuffleupagus.so" >> /etc/php.d/20-snuffleupagus.ini
	echo "sp.configuration_file=/etc/sentora/configs/php/sp/snuffleupagus.rules" >> /etc/php.d/20-snuffleupagus.ini
				
	#### FIX - Suhosin loading in php.ini
	mv /etc/php.d/suhosin.ini /etc/php.d/suhosin.ini_bak
	# zip -r /etc/php.d/suhosin.zip /etc/php.d/suhosin.ini
	# rm -rf /etc/php.d/suhosin.ini
		
elif [[ "$OS" = "Ubuntu" && ( "$VER" = "16.04" ) ]]; then
	
	# Enable snuffleupagus in PHP.ini
	echo -e "\nUpdating Ubuntu PHP.ini Enable snuffleupagus..."
	echo "extension=snuffleupagus.so" >> /etc/php/"$PHPVER"/mods-available/snuffleupagus.ini
	echo "sp.configuration_file=/etc/sentora/configs/php/sp/snuffleupagus.rules" >> /etc/php/"$PHPVER"/mods-available/snuffleupagus.ini
	ln -s /etc/php/"$PHPVER"/mods-available/snuffleupagus.ini /etc/php/"$PHPVER"/apache2/conf.d/20-snuffleupagus.ini
		
fi
		
# -------------------------------------------------------------------------------
# PANEL SERVICE FIXES/UPGRADES BELOW
# -------------------------------------------------------------------------------
	
# -------------------------------------------------------------------------------
# Download Sentora Upgrader files Now
# -------------------------------------------------------------------------------	
	
#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
# reset home dir for commands
cd ~ || exit
		
# Remove OLD BETA version files/folder if left behind
upgradedir="$HOME/sentora_php7_upgrade"
if [ -d "$upgradedir" ]; then
	rm -r ~/sentora_php7_upgrade
fi

# Download Sentora upgrade packages
echo -e "\n--- Downloading Proconf files..." 

# Get Sentora Installers/Preconf
wget -nv -O sentora_preconfig.zip https://github.com/Dukecitysolutions/sentora-installers-dev/archive/master.zip

echo -e "\n--- Unzipping Preconf files..."
unzip -oq sentora_preconfig.zip
rm -r sentora_preconfig.zip

# Get Sentora core files
echo -e "\n--- Downloading Core files..." 
wget -nv -O sentora_core.zip https://github.com/Dukecitysolutions/sentora-core-dev/archive/master.zip

echo -e "\n--- Unzipping core files..."
unzip -oq sentora_core.zip
rm -r sentora_core.zip
		
# -------------------------------------------------------------------------------
# BIND/NAMED DNS Below
# -------------------------------------------------------------------------------
	
if [[ "$OS" = "CentOs" ]]; then
    $PACKAGE_INSTALLER bind bind-utils bind-libs
    BIND_PATH="/etc/named/"
    BIND_FILES="/etc"
    BIND_SERVICE="named"
    BIND_USER="named"
elif [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
    $PACKAGE_INSTALLER bind9 bind9utils
    BIND_PATH="/etc/bind/"
    BIND_FILES="/etc/bind"
    BIND_SERVICE="bind9"
    BIND_USER="bind"
fi
	
echo -e "\n--- Setting up Bind9..."
	
# reset home dir for commands
cd ~ || exit
	
# Fix CentOS 7 DNS 
if [[ "$OS" = "CentOs" && ("$VER" = "7") ]]; then
	if ! grep -q "managed-keys-directory" /etc/named.conf; then
		echo -e "\nUpdating named.conf with managed-keys-directory for CentOS 7\n"
		sed -i '\~dnssec-lookaside auto;~a   managed-keys-directory "/var/named/dynamic";' /etc/named.conf
			
		# Delete Default empty managed-keys.bind.jnl file
		rm -rf /var/named/dynamic/managed-keys.bind
						
	fi
	
fi	
	
# Fix Ubuntu 16.04 DNS 
if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
	
	# Ubuntu 16.04-20.04 Bind9 Fixes 
	if [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
		if [[ "$VER" = "16.04" || "$VER" = "18.04" || "$VER" = "20.04" ]]; then
			# Disable Bind9(Named) from Apparmor. Apparmor reinstalls with apps(MySQL & Bind9) for some reason.
			ln -s /etc/apparmor.d/usr.sbin.named /etc/apparmor.d/disable/
			apparmor_parser -R /etc/apparmor.d/usr.sbin.named
		fi
	fi

	# Set bind log in DB missing in Sentora installer
	$PANEL_PATH/panel/bin/setso --set bind_log "/var/sentora/logs/bind/bind.log"

fi	

# Fix/Disable Named/bind dnssec-lookaside
if [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
	# Bind/Named v.9.10 or OLDER
	if [[ "$VER" = "8" || "$VER" = "16.04" ]]; then
		sed -i "s|dnssec-lookaside auto|dnssec-lookaside no|g" $BIND_FILES/named.conf
		
	# Bind/Named v.9.11 or NEWER
	elif [[ "$VER" = "18.04" ]]; then
		sed -i "s|dnssec-lookaside auto|#dnssec-lookaside auto|g" $BIND_FILES/named.conf
	
	fi
elif [[ "$OS" = "CentOs" ]]; then

	# Bind/Named v.9.11 or NEWER
	if [[ "$VER" = "8" ]]; then
		sed -i "s|dnssec-lookaside auto|#dnssec-lookaside auto|g" $BIND_FILES/named.conf
		
	fi
fi
	
# -------------------------------------------------------------------------------
# CRON Below
# -------------------------------------------------------------------------------
	
echo -e "\n--- Setting up Cron..."
	
# prepare daemon crontab
# sed -i "s|!USER!|$CRON_USER|" "$PANEL_CONF"/cron/zdaemon #it screw update search!#
rm -rf /etc/cron.d/zdaemon
cp -r "$SENTORA_PRECONF_UPGRADE"/preconf/cron/zdaemon /etc/cron.d/zdaemon
sed -i "s|!USER!|root|" "/etc/cron.d/zdaemon"
chmod 644 /etc/cron.d/zdaemon
		
# Fix Sentora user CRON_MANAGER Module
if [[ "$OS" = "CentOs" ]]; then
		
	chown apache:apache /var/spool/cron
	chmod 0770 /var/spool/cron
			
	chown apache:apache /var/spool/cron/apache
	chmod 0770 /var/spool/cron/apache
			
elif [[ "$OS" = "Ubuntu" ]]; then
		
	chown root:root /var/spool/cron
	chmod 0777 /var/spool/cron
			
	chown www-data:www-data /var/spool/cron/crontabs
	chmod 0770 /var/spool/cron/crontabs
		
fi
	
# -------------------------------------------------------------------------------
# FAIL2BAN Below
# -------------------------------------------------------------------------------
	# ???
	
# -------------------------------------------------------------------------------
# POSTFIX Below
# -------------------------------------------------------------------------------
	
echo -e "\n--- Setting up Postfix..."
	
# Fix postfix not working after upgrade to 16.04
# Edit deamon_directory in postfix main.cf to fix startup issue.
if [[ "$OS" = "Ubuntu" ]]; then
	if [[ "$VER" = "16.04" ]]; then
		sed -i "s|daemon_directory = /usr/lib/postfix|daemon_directory = /usr/lib/postfix/sbin|" $PANEL_CONF/postfix/main.cf
	fi
fi
	
# Update/alter Postfix table from MYISAM to INNODB
# get mysql root password, check it works or ask it
mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
while ! mysql -u root -p"$mysqlpassword" -e ";" ; do
read -r -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
done
echo -e "Connection mysql ok"
echo -e "\n--- Updating Postfix DB..."
mysql -u root -p"$mysqlpassword" < "$SENTORA_PRECONF_UPGRADE"/preconf/sentora-update/2-0-0/sql/0-postfix-datetime-fix.sql
mysql -u root -p"$mysqlpassword" < "$SENTORA_PRECONF_UPGRADE"/preconf/sentora-update/2-0-0/sql/1-postfix-innodb.sql
mysql -u root -p"$mysqlpassword" < "$SENTORA_PRECONF_UPGRADE"/preconf/sentora-update/2-0-0/sql/2-postfix-unused-tables.sql
	
# -------------------------------------------------------------------------------
# ProFTPd Below
# -------------------------------------------------------------------------------

echo -e "\n--- Setting up Proftpd..."

if [[ "$OS" = "CentOs" && ("$VER" = "7" || "$VER" = "8") ]]; then
	echo -e "\n-- Installing ProFTPD if not installed"
		
	PACKAGE_INSTALLER="yum -y -q install"
		
   	$PACKAGE_INSTALLER proftpd proftpd-mysql 
   	FTP_CONF_PATH='/etc/proftpd.conf'
   	sed -i "s|nogroup|nobody|" $PANEL_CONF/proftpd/proftpd-mysql.conf
		
	# Setup proftpd base file to call sentora config
	rm -f "$FTP_CONF_PATH"
	#touch "$FTP_CONF_PATH"
	#echo "include $PANEL_CONF/proftpd/proftpd-mysql.conf" >> "$FTP_CONF_PATH";
	ln -s "$PANEL_CONF/proftpd/proftpd-mysql.conf" "$FTP_CONF_PATH"
		
	systemctl enable proftpd
		
elif [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
		
	echo -e "\n-- Reinstall ProFTPD to fix Ubuntu issues"
		
	# Remove Proftpd for reinstall
	$PACKAGE_REMOVER proftpd-basic

	# Reinstall Proftpd and proftpd-mysql
	$PACKAGE_INSTALLER proftpd proftpd-mod-mysql

	FTP_CONF_PATH='/etc/proftpd/proftpd.conf'

	# Setup proftpd base file to call sentora config
	rm -f "$FTP_CONF_PATH"
	ln -s "$PANEL_CONF/proftpd/proftpd-mysql.conf" "$FTP_CONF_PATH"

	# Restart Proftpd
	service proftpd restart
		
fi

# Fix Proftpd using datetime stamp DEFAULT with ZEROS use NULL. Fixes MYSQL 5.7 NO_ZERO_IN_DATE
mysql -u root -p"$mysqlpassword" < "$SENTORA_PRECONF_UPGRADE"/preconf/sentora-update/2-0-0/sql/4-proftpd-datetime-fix.sql


# Update Proftpd to use SHA512 if NOT already
#if ! grep -q SHA512 "/etc/sentora/configs/proftpd/proftpd-mysql.conf"; then
  
	# Update Proftp ftpuser passwd column type to vahrchar(180) for SHA512 encrypted passwords & change current plaintext passwords to SHA512.
	# mysql -u root -p"$mysqlpassword" -D sentora_proftpd -e "ALTER TABLE ftpuser MODIFY COLUMN passwd varchar(180)"
	# mysql -u root -p"$mysqlpassword" -D sentora_proftpd -e "UPDATE ftpuser SET passwd=SHA2(passwd, 512)"

	# Delete Sentora_core x_ftpaccounts plaintext ft_password_vc column
	# mysql -u root -p"$mysqlpassword" -D sentora_core -e "ALTER TABLE x_ftpaccounts DROP COLUMN ft_password_vc"
	
#fi


# -------------------------------------------------------------------------------
# Start Sentora upgrade Below
# -------------------------------------------------------------------------------
		
# -------------------------------------------------------------------------------
# Start
# -------------------------------------------------------------------------------

echo -e "\n--- Updating Sentora Core files..."

# Upgrade Sentora Dryden files
rm -rf $PANEL_PATH/panel/dryden
cp -R "$SENTORA_CORE_UPGRADE"/dryden $PANEL_PATH/panel/

# Set Dryden to 0777 permissions
chmod -R 0777 $PANEL_PATH/panel/dryden

# Update Snuffleupagus Default rules to current
echo -e "\n--- Updating Snuffleupagus default rules..."
rm -rf /etc/sentora/configs/php/sp/snuffleupagus.rules
rm -rf /etc/sentora/configs/php/sp/sentora.rules
rm -rf /etc/sentora/configs/php/sp/cron.rules
cp -r  "$SENTORA_PRECONF_UPGRADE"/preconf/php/sp/snuffleupagus.rules /etc/sentora/configs/php/sp/
cp -r  "$SENTORA_PRECONF_UPGRADE"/preconf/php/sp/sentora.rules /etc/sentora/configs/php/sp/
cp -r  "$SENTORA_PRECONF_UPGRADE"/preconf/php/sp/cron.rules /etc/sentora/configs/php/sp/
	
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


# Copy New Apache config template files
echo -e "\n--- Updating Sentora vhost templates..."
rm -rf /etc/sentora/configs/apache/templates/
cp -r "$SENTORA_PRECONF_UPGRADE"/preconf/apache/templates /etc/sentora/configs/apache/
echo ""
	
# Install Smarty files
cp -r "$SENTORA_CORE_UPGRADE"/etc/lib/smarty /etc/sentora/panel/etc/lib/

# Replace .htaccess with new file
rm -r $PANEL_PATH/panel/.htaccess
cp -r "$SENTORA_CORE_UPGRADE"/.htaccess $PANEL_PATH/panel/

# Replace /inc/init.inc.php with new file
rm -r $PANEL_PATH/panel/inc/init.inc.php
cp -r "$SENTORA_CORE_UPGRADE"/inc/init.inc.php $PANEL_PATH/panel/inc/
	
# Update Sentora Core Mysql tables
# get mysql root password, check it works or ask it
mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
while ! mysql -u root -p"$mysqlpassword" -e ";" ; do
read -r -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
done
echo -e "Connection mysql ok"
echo -e "\n--- Updating Sentora Core DB and Proftpd..."
mysql -u root -p"$mysqlpassword" < "$SENTORA_PRECONF_UPGRADE"/preconf/sentora-update/2-0-0/sql/3-core-update.sql

	
# Restart Apache to set Snuffleupagus
if [[ "$OS" = "CentOs" ]]; then
	service httpd restart
elif [[ "$OS" = "Ubuntu" ]]; then
	systemctl restart apache2
fi
		
	
# -------------------------------------------------------------------------------
#--- LetsEncrypt -  We need a module to help user with SSL Certs/settings. Module coming soon!!!!
# -------------------------------------------------------------------------------

# Ubuntu 20.04 LetsEncrypt has issues with their code for 20.04. Will resolve later when when they resolve. Maybe i will fix not sure..

if [[ "$OS" = "CentOs" && ( "$VER" = "7" || "$VER" = "8" ) || 
      "$OS" = "Ubuntu" && ("$VER" = "16.04" || "$VER" = "18.04" ) ||
      "$OS" = "debian" && ("$VER" = "9" || "$VER" = "10" ) ]] ; then
	  
	$PACKAGE_INSTALLER git
	git clone https://github.com/letsencrypt/letsencrypt
	cd letsencrypt
	./letsencrypt-auto --help
	  
fi


# -------------------------------------------------------------------------------
# Start Roundcube-1.4.4 upgrade Below
# -------------------------------------------------------------------------------
	
echo -e "\n--- Starting Roundcube upgrade to 1.4.4..."

# Start Roundcube upgrade

# Backup old Roundcube install for admins to use
echo -e "\n#### Backup of old roundcube site files has been created at webmail_old. Use this to copy any info you need like plugins/modules ####\n"
cp -r $PANEL_PATH/panel/etc/apps/webmail $PANEL_PATH/panel/etc/apps/webmail_old

# Upgrade Roundcube
chmod -R 0777 $SENTORA_CORE_UPGRADE/etc/apps/webmail
yes | $SENTORA_CORE_UPGRADE/etc/apps/webmail/bin/installto.sh $PANEL_PATH/panel/etc/apps/webmail/
chown -R root:root $PANEL_PATH/panel/etc/apps/webmail

# Delete Roundcube setup files
rm -r $PANEL_PATH/panel/etc/apps/webmail/SQL
#rm -r $PANEL_PATH/panel/etc/apps/webmail/installer

# -------------------------------------------------------------------------------
# Start pChart2.4 w/PHP 7 support upgrade Below
# -------------------------------------------------------------------------------
	
echo -e "\n--- Starting pChart2.4 upgrade..."
rm -rf /etc/sentora/panel/etc/lib/pChart2/
cp -r  "$SENTORA_CORE_UPGRADE"/etc/lib/pChart2 $PANEL_PATH/panel/etc/lib/
	
# -------------------------------------------------------------------------------
# Start PHPsysinfo 3.3.1 upgrade Below
# -------------------------------------------------------------------------------
	
echo -e "\n--- Starting PHPsysinfo upgrade to 3.3.1..."
rm -rf /etc/sentora/panel/etc/apps/phpsysinfo/
cp -r  "$SENTORA_CORE_UPGRADE"/etc/apps/phpsysinfo $PANEL_PATH/panel/etc/apps/
	
# Setup config file
mv -f /etc/sentora/panel/etc/apps/phpsysinfo/phpsysinfo.ini.new /etc/sentora/panel/etc/apps/phpsysinfo/phpsysinfo.ini
	
# -------------------------------------------------------------------------------
# Start PHPmyadmin 4.9.2 upgrade Below - TESTING WHICH VERSION IS BEST HERE.
# -------------------------------------------------------------------------------

echo -e "\n--- Configuring phpMyAdmin 4.9.2...\n"	
	
#--- Some functions used many times below
# Random password generator function
passwordgen() {
   	l=$1
   	[ "$l" == "" ] && l=16
   	tr -dc A-Za-z0-9 < /dev/urandom | head -c ${l} | xargs
}
	
phpmyadminsecret=$(passwordgen 32);
	
#echo "password"
#echo -e "$phpmyadminsecret"
	
#Version checker function for Mysql & PHP
versioncheck() { 
	echo "$@" | gawk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'; 
}

## START PHPmyadmin Install here
					
cd  $PANEL_PATH/panel/etc/apps/ || exit

rm -rf $PANEL_PATH/panel/etc/apps/phpmyadmin																						
cp -r "$SENTORA_CORE_UPGRADE"/etc/apps/phpmyadmin phpmyadmin
	
																	
cd phpmyadmin || exit							
cd $PANEL_PATH/panel/etc/apps/ || exit
chmod -R 777 phpmyadmin
chown -R "$HTTP_USER":"$HTTP_USER" phpmyadmin
							

mkdir -p /etc/sentora/panel/etc/apps/phpmyadmin/tmp
chmod -R 777 /etc/sentora/panel/etc/apps/phpmyadmin/tmp
ln -s $PANEL_CONF/phpmyadmin/config.inc.php $PANEL_PATH/panel/etc/apps/phpmyadmin/config.inc.php
chmod 644 $PANEL_CONF/phpmyadmin/config.inc.php
#sed -i "s|\$cfg\['blowfish_secret'\] \= '.*';|\$cfg\['blowfish_secret'\] \= '$phpmyadminsecret';|" $PANEL_CONF/phpmyadmin/config.inc.php

# Remove phpMyAdmin's setup folders in case they were left behind.


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
	
# -------------------------------------------------------------------------------

# Clean up files downloaded for install/update
rm -r "$SENTORA_CORE_UPGRADE"
rm -r "$SENTORA_PRECONF_UPGRADE"


#--- Restart all services to capture output messages, if any
if [[ "$OS" = "CentOs" && "$VER" == "7" || "$VER" == "8" ]]; then
    # CentOs7 does not return anything except redirection to systemctl :-(
    service() {
       echo "Restarting $1"
       systemctl restart "$1.service"
    }
fi

echo -e "# -------------------------------------------------------------------------------"

# Set admin contact info to zadmin profile

echo -e "\n--- Updating Admin contact Info..."
mysql -u root -p"$mysqlpassword" -e "UPDATE sentora_core.x_accounts SET ac_email_vc='$ADMIN_EMAIL' WHERE sentora_core.x_accounts.ac_id_pk = 1"
mysql -u root -p"$mysqlpassword" -e "UPDATE sentora_core.x_profiles SET ud_fullname_vc='$ADMIN_NAME', ud_phone_vc='$ADMIN_PHONE', ud_address_tx='$ADMIN_ADDRESS\r\n$ADMIN_PROVINCE $ADMIN_POSTALCODE\r\n$ADMIN_COUNTRY', ud_postcode_vc='$ADMIN_POSTALCODE' WHERE sentora_core.x_profiles.ud_id_pk = 1"

echo -e "\n--- Done Updating admin contact info.\n"

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
