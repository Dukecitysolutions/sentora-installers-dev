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
# CentOS 7.*/8.* Minimal, 
# Ubuntu server 16.04/18.04/20.04 
# Debian 9.*/10.* 
# 32bit and 64bit
#
# Contributions from:
#
#   Pascal Peyremorte (ppeyremorte@sentora.org)
#   Mehdi Blagui
#   Anthony DeBeaulieu (anthony.d@sentora.org
#   Kevin Andrews (kevin@zvps.uk)
#
#   and all those who participated to this and to previous installers.
#   Thanks to all.

SENTORA_UPDATER_VERSION="1.1.0"
PANEL_PATH="/etc/sentora"
PANEL_CONF="/etc/sentora/configs"
SENTORA_INSTALLED_DBVERSION=$($PANEL_PATH/panel/bin/setso --show dbversion)
SEN_VER=${SENTORA_INSTALLED_DBVERSION:0:7}

# -------------------------------------------------------------------------------
# Installer Logging
#--- Set custom logging methods so we create a log file in the current working directory.

	logfile=$(date +%Y-%m-%d_%H.%M.%S_sentora_php7_install.log)
	touch "$logfile"
	exec > >(tee "$logfile")
	exec 2>&1
# -------------------------------------------------------------------------------	
	
#--- Display the 'welcome' splash/user warning info..
echo ""
echo "############################################################################################"
echo "#  Welcome to the Official Sentora Upgrader v.$SENTORA_UPDATER_VERSION  					 #"
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

if [[ "$OS" = "CentOs" && ( "$VER" = "7" ) || 
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
if [[ "$SEN_VER" > "1.0.2" ]]; then
    echo "- Found Sentora v$SEN_VER, processing..."
else
    echo "Sentora version v1.0.3 is required to install, you have v$SEN_VER. aborting..."
    exit 1
fi

# Check for some common packages that we know will affect the installation/operating of Sentora.
if [[ "$OS" = "CentOs" ]] ; then
	if [[ "$VER" = "8" ]] ; then
		PACKAGE_INSTALLER="dnf -y -q install"
		PACKAGE_REMOVER="dnf -y -q remove"
	else
		PACKAGE_INSTALLER="yum -y -q install"
		PACKAGE_REMOVER="yum -y -q remove"
	fi
	
elif [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
    PACKAGE_INSTALLER="apt-get -yqq install"
    PACKAGE_REMOVER="apt-get -yqq remove"  
fi

# Setup repos for each OS ARCH
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
		# Install PHP 7.3 Repos & enable
		$PACKAGE_INSTALLER software-properties-common
		add-apt-repository -y ppa:ondrej/apache2
		add-apt-repository -y ppa:ondrej/php
		apt-get -yqq update
		#apt-get -yqq upgrade
	fi
fi

# ***************************************
# Installation really starts here


# Install PHP 7.3
if [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
	if [[ "$VER" = "16.04" || "$VER" = "8" ]]; then
      
		# Install PHP 7.3 and install modules
		#$PACKAGE_INSTALLER php7.3 php7.3-common 
		#$PACKAGE_INSTALLER php7.3-mysql php7.3-mbstring
		#$PACKAGE_INSTALLER php7.3-zip php7.3-xml php7.3-gd
		#$PACKAGE_INSTALLER php7.0-dev libapache2-mod-php7.3
		#$PACKAGE_INSTALLER php7.3-dev
		#$PACKAGE_INSTALLER php7.3-curl
		
		$PACKAGE_INSTALLER php7.3 php7.3-common php7.3-curl php7.0-dev php7.3-dev php7.3-gd php7.3-mysql php7.3-mbstring php7.3-xml php7.3-zip libapache2-mod-php7.3
                
		# PHP Mcrypt 1.0.2 install
		if [ ! -f /etc/php/7.3/apache2/conf.d/20-mcrypt.ini ]; then
                        
			echo -e "\nInstalling php mcrypt 1.0.2"
			$PACKAGE_INSTALLER gcc make autoconf libc-dev pkg-config
			$PACKAGE_INSTALLER libmcrypt-dev
			echo '' | sudo pecl install mcrypt-1.0.2
			bash -c "echo extension=mcrypt.so > /etc/php/7.3/mods-available/mcrypt.ini"
			ln -s /etc/php/7.3/mods-available/mcrypt.ini /etc/php/7.3/apache2/conf.d/20-mcrypt.ini
		fi		
                
		# Set PHP 7.3 as system default in case upgrade to PHP 7.4+
		update-alternatives --set php /usr/bin/php7.3
                
		# Enable Apache mod_php7.3
		a2enmod php7.3  


		# Pass php.ini.OLD Date.timezone over to new PHP.ini
		TIMEZONE=$(cat /etc/php5/apache2/php.ini | grep "date.timezone =" | sed -s "s|.*date.timezone \= '\(.*\)';.*|\1|")
		sed -i 's|;date.timezone =|'"$TIMEZONE"'|g' /etc/php/7.3/apache2/php.ini
		
		# Fix missing php.ini settings sentora needs
		echo -e "\nFix missing php.ini settings sentora needs in Ubuntu 16.04 php 7.3 ..."
		echo "setting upload_tmp_dir = /var/sentora/temp/"
		echo ""
		sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.3/apache2/php.ini
		echo "Setting session.save_path = /var/sentora/sessions"
		sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.3/apache2/php.ini
			  

	fi 
            
	PHP_INI_PATH="/etc/php/7.3/apache2/php.ini"
            
elif [[ "$OS" = "CentOs" ]]; then    
	if [[ "$VER" = "7" ]]; then   
		PHP_INI_PATH="/etc/php.ini" 
	      
		# Install PHP 7.3 and install modules
		#yum -y install httpd mod_ssl php php-zip php-fpm php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel php-intl php-imagick php-pspell wget        
                 
		yum -y --enablerepo=remi-php73 install php php-devel php-gd php-mcrypt php-mysql php-xml php-xmlrpc php-zip
        
		
		## Setup PHP 7.3 new PHP.INI file shipped with PHP and rename old PHP.INI
		file="/etc/php.ini.OLD"
		if [ ! -f "$file" ]; then
			mv /etc/php.ini /etc/php.ini.OLD
			cp -r /etc/php.ini.rpmnew $PHP_INI_PATH
		fi
	
		# Pass php.ini.OLD Date.timezone over to new PHP.ini
		TIMEZONE=$(cat /etc/php.ini.OLD | grep "date.timezone =" | sed -s "s|.*date.timezone \= '\(.*\)';.*|\1|")
		sed -i 's|;date.timezone =|'"$TIMEZONE"'|g' $PHP_INI_PATH
	
		# Fix missing php.ini settings sentora needs
		echo -e "\nFix missing php.ini settings sentora needs in CentOS 7.x php 7.3 ..."
		echo "setting upload_tmp_dir = /var/sentora/temp/"
		echo ""
		sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' $PHP_INI_PATH
		echo "Setting session.save_path = /var/sentora/sessions"
		sed -i 's|;session.save_path = "/tmp"|session.save_path = "/var/sentora/sessions"|g' $PHP_INI_PATH

		
		        
	fi
fi 	

# PHP END
# -------------------------------------------------------------------------------
	
##### Check php 7 was installed or quit installer.
PHPVERFULL=$(php -r 'echo phpversion();')
PHPVER=${PHPVERFULL:0:3} # return 5.x or 7.x

echo -e "\nDetected PHP: $PHPVER "

if  [[ "$PHPVER" = "7.3" ]]; then
   	echo -e "\nPHP 7.3 installed. Procced installing ..."
else
	echo -e "\nPHP 7.3 not installed. Exiting installer. Please contact script admin"
	exit 1
fi
	
# -------------------------------------------------------------------------------
# Start Snuffleupagus v.0.5.x install Below
# -------------------------------------------------------------------------------
	
# Install Snuffleupagus
# Install git
$PACKAGE_INSTALLER git

#setup PHP_PERDIR in Snuffleupagus.c in src
mkdir -p /etc/snuffleupagus
cd /etc/snuffleupagus/src || exit
	
# Clone Snuffleupagus
git clone https://github.com/nbs-system/snuffleupagus
	
sed -i 's/PHP_INI_SYSTEM/PHP_INI_PERDIR/g' snuffleupagus.c
		
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
	
if [[ "$OS" = "CentOs" && ( "$VER" = "7" ) ]]; then
	
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
	echo "extension=snuffleupagus.so" >> /etc/php/7.3/mods-available/snuffleupagus.ini
	echo "sp.configuration_file=/etc/sentora/configs/php/sp/snuffleupagus.rules" >> /etc/php/7.3/mods-available/snuffleupagus.ini
	ln -s /etc/php/7.3/mods-available/snuffleupagus.ini /etc/php/7.3/apache2/conf.d/20-snuffleupagus.ini
		
fi
	
# Restart Apache service
if [[ "$OS" = "CentOs" && ("$VER" = "7") ]]; then
	systemctl restart httpd
	
elif [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
	systemctl restart apache2
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
		
# Download Sentora upgrade packages
echo -e "\nDownloading Updated package files..." 
	
# Clone Github instead
upgradedir="$HOME/sentora_php7_upgrade"
if [ -d "$upgradedir" ]; then
	rm -r ~/sentora_php7_upgrade
fi
git clone https://github.com/Dukecitysolutions/sentora-php7-upgrade sentora_php7_upgrade
	
# mkdir -p sentora_php7_upgrade
# cd sentora_php7_upgrade
# wget -nv -O sentora_php7_upgrade.zip http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.zip
	
#echo -e "\n--- Unzipping files..."
#unzip -oq sentora_php7_upgrade.zip
	
# -------------------------------------------------------------------------------
# BIND/NAMED DNS Below
# -------------------------------------------------------------------------------
	
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
	
	# Ubuntu DNS fix now starting fix
	# Update Snuff Default rules to fix panel timeout
	echo -e "\nUpdating Ubuntu DNS fix..."
	rm -rf /etc/apparmor.d/usr.sbin.named
	cp -r  ~/sentora_php7_upgrade/preconf/apparmor.d/usr.sbin.named /etc/apparmor.d/
	#chown -R root:root /etc/apparmor.d/usr.sbin.named 
	#chmod 0644 /etc/apparmor.d/usr.sbin.named 
		
	if ! grep -q "managed-keys-directory" /etc/bind/named.conf; then
		echo -e "\nUpdating named.conf with managed-keys-directory for Ubuntu 16 & 18\n"
		sed -i '\~dnssec-lookaside auto;~a   managed-keys-directory "/var/named/dynamic";' /etc/bind/named.conf
			
		# Delete Default empty managed-keys.bind.jnl file
		rm -rf /var/named/dynamic/managed-keys.bind
					
	fi

	# Set bind log in DB missing in Sentora installer
	$PANEL_PATH/panel/bin/setso --set bind_log "/var/sentora/logs/bind/bind.log"

	# DELETING maybe or using later ################
	# DNS now starting fix
	#file="/etc/apparmor.d/usr.sbin.named"
	#TARGET_STRING="/etc/sentora/configs/bind/etc/** rw,"
	#grep -q $TARGET_STRING $file
	#if [ ! $? -eq 0 ]
	#	then
   	#		echo "Apparmor does not include DNS fix. Updating..."
   	#	sed -i '\~/var/cache/bind/ rw,~a   /etc/sentora/configs/bind/etc/** rw,' /etc/apparmor.d/usr.sbin.named
	#	sed -i '\~/var/cache/bind/ rw,~a   /var/sentora/logs/bind/** rw,' /etc/apparmor.d/usr.sbin.named
	#fi
	###############################

fi	
	
# -------------------------------------------------------------------------------
# CRON Below
# -------------------------------------------------------------------------------
	
# prepare daemon crontab
# sed -i "s|!USER!|$CRON_USER|" "$PANEL_CONF/cron/zdaemon" #it screw update search!#
rm -rf /etc/cron.d/zdaemon
cp -r ~/sentora_php7_upgrade/preconf/cron/zdaemon /etc/cron.d/zdaemon
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
	
# Fix postfix not working after upgrade to 16.04
if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
	echo -e "\nFixing postfix not working after upgrade to 16.04..."
		
	# disable postfix daemon_directory for now to allow startup after update
	sed -i 's|daemon_directory = /usr/lib/postfix|#daemon_directory = /usr/lib/postfix|g' /etc/sentora/configs/postfix/main.cf
				
	systemctl restart postfix
		
fi
	
# Update/alter Postfix table from MYISAM to INNODB
# get mysql root password, check it works or ask it
mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
while ! mysql -u root -p"$mysqlpassword" -e ";" ; do
read -r -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
done
echo -e "Connection mysql ok"
mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/1-postfix-innodb.sql
mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/2-postfix-unused-tables.sql
	
# -------------------------------------------------------------------------------
# ProFTPd Below
# -------------------------------------------------------------------------------

if [[ "$OS" = "CentOs" && ("$VER" = "7") ]]; then
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
	#touch "$FTP_CONF_PATH"
	#echo "include $PANEL_CONF/proftpd/proftpd-mysql.conf" >> "$FTP_CONF_PATH";
	ln -s "$PANEL_CONF/proftpd/proftpd-mysql.conf" "$FTP_CONF_PATH"

	# Restart Proftpd
	service proftpd restart
		
fi
	
# -------------------------------------------------------------------------------
# Start Sentora upgrade Below
# -------------------------------------------------------------------------------
		
# -------------------------------------------------------------------------------
# Start
# -------------------------------------------------------------------------------

# ####### start here   Upgrade __autoloader() to x__autoloader()
# rm -rf $PANEL_PATH/panel/dryden/loader.inc.php
# cd 
# cp -r /sentora_update/loader.inc.php $PANEL_PATH/panel/dryden/
sed -i 's/__autoload/x__autoload/g' /etc/sentora/panel/dryden/loader.inc.php
	
# Update Snuffleupagus Default rules to current
echo -e "\n--- Updating Snuffleupagus default rules..."
rm -rf /etc/sentora/configs/php/sp/snuffleupagus.rules
rm -rf /etc/sentora/configs/php/sp/sentora.rules
rm -rf /etc/sentora/configs/php/sp/cron.rules
cp -r  ~/sentora_php7_upgrade/preconf/php/snuffleupagus.rules /etc/sentora/configs/php/sp/
cp -r  ~/sentora_php7_upgrade/preconf/php/sentora.rules /etc/sentora/configs/php/sp/
cp -r  ~/sentora_php7_upgrade/preconf/php/cron.rules /etc/sentora/configs/php/sp/
	
# Upgrade apache_admin with apache_admin 1.0.x
echo -e "\n--- Updating Apache_admin module..."
rm -rf /etc/sentora/panel/modules/apache_admin/
cp -r  ~/sentora_php7_upgrade/modules/apache_admin $PANEL_PATH/panel/modules/
		
# Set new sentora panel logs dir
#mkdir -p /var/sentora/logs/panel
		
# Upgrade cron module 1.0.x
echo -e "\n--- Updating Cron module..."
rm -rf /etc/sentora/panel/modules/cron/
cp -r  ~/sentora_php7_upgrade/modules/cron $PANEL_PATH/panel/modules/
		
# Upgrade dns_admin module 1.0.x
echo -e "\n--- Updating Dns_Admin module..."
rm -rf /etc/sentora/panel/modules/dns_admin/
cp -r  ~/sentora_php7_upgrade/modules/dns_admin $PANEL_PATH/panel/modules/
		
# Upgrade dns_manager module 1.0.x
echo -e "\n--- Updating Dns_Manager module..."
rm -rf /etc/sentora/panel/modules/dns_manager/
cp -r  ~/sentora_php7_upgrade/modules/dns_manager $PANEL_PATH/panel/modules/
	
# Upgrade domains_module to 1.0.x
echo -e "\n--- Updating Domains module..."
rm -rf /etc/sentora/panel/modules/domains/
cp -r  ~/sentora_php7_upgrade/modules/domains $PANEL_PATH/panel/modules/
	
# Upgrade ftp_management module 1.0.x
echo -e "\n--- Updating FTP_management module..."
rm -rf /etc/sentora/panel/modules/ftp_management/
cp -r  ~/sentora_php7_upgrade/modules/ftp_management $PANEL_PATH/panel/modules/
	
# Upgrade mailboxes module 1.0.x
echo -e "\n--- Updating Mailboxes module..."
rm -rf /etc/sentora/panel/modules/mailboxes/
cp -r  ~/sentora_php7_upgrade/modules/mailboxes $PANEL_PATH/panel/modules/
	
# Upgrade mysql_databases module 1.0.x
echo -e "\n--- Updating Mysql_databases module..."
rm -rf /etc/sentora/panel/modules/mysql_databases/
cp -r  ~/sentora_php7_upgrade/modules/mysql_databases $PANEL_PATH/panel/modules/
	
# Upgrade mysql_users module 1.0.x
echo -e "\n--- Updating Mysql_users module..."
rm -rf /etc/sentora/panel/modules/mysql_users/
cp -r  ~/sentora_php7_upgrade/modules/mysql_users $PANEL_PATH/panel/modules/
	
# Upgrade parked_Domains module 1.0.x
echo -e "\n--- Updating Parked_Domains module..."
rm -rf /etc/sentora/panel/modules/parked_domains/
cp -r  ~/sentora_php7_upgrade/modules/parked_domains $PANEL_PATH/panel/modules/
	
# Upgrade Sub_Domains module 1.0.x
echo -e "\n--- Updating Sub_Domains module..."
rm -rf /etc/sentora/panel/modules/sub_domains/
cp -r  ~/sentora_php7_upgrade/modules/sub_domains $PANEL_PATH/panel/modules/
	
# Upgrade Usage_viewer module 1.0.x
echo -e "\n--- Updating Usage_viewer module..."
rm -rf /etc/sentora/panel/modules/usage_viewer/
cp -r  ~/sentora_php7_upgrade/modules/usage_viewer $PANEL_PATH/panel/modules/
	
# Copy New Apache config template files
echo -e "\n--- Updating Sentora vhost templates..."
rm -rf /etc/sentora/configs/apache/templates/
cp -r ~/sentora_php7_upgrade/preconf/apache/templates /etc/sentora/configs/apache/
echo ""
	
# install Smarty files
cp -r ~/sentora_php7_upgrade/etc/lib/smarty /etc/sentora/panel/etc/lib/

# Replace .htaccess with new file
rm -r $PANEL_PATH/panel/.htaccess
cp -r ~/sentora_php7_upgrade/.htaccess $PANEL_PATH/panel/

# Replace /inc/init.inc.php with new file
rm -r $PANEL_PATH/panel/inc/init.inc.php
cp -r ~/sentora_php7_upgrade/inc/init.inc.php $PANEL_PATH/panel/inc/
	
# Update Sentora Core Mysql tables
# get mysql root password, check it works or ask it
mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
while ! mysql -u root -p"$mysqlpassword" -e ";" ; do
read -r -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
done
echo -e "Connection mysql ok"
mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/sentora_1_0_3_1.sql
	
# Restart apache to set Snuffleupagus
if [[ "$OS" = "CentOs" ]]; then
	service httpd restart
elif [[ "$OS" = "Ubuntu" ]]; then
	systemctl restart apache2
fi
		
# -------------------------------------------------------------------------------
# Start Roundcube-1.3.10 upgrade Below
# -------------------------------------------------------------------------------
	
echo -e "\nStarting Roundcube upgrade to 1.3.10..."
cd ~/sentora_php7_upgrade || exit
wget --no-check-certificate -nv -O roundcubemail-1.3.10.tar.gz https://github.com/roundcube/roundcubemail/releases/download/1.3.10/roundcubemail-1.3.10-complete.tar.gz
tar xf roundcubemail-*.tar.gz
cd roundcubemail-1.3.10 || exit
bin/installto.sh /etc/sentora/panel/etc/apps/webmail/
chown -R root:root /etc/sentora/panel/etc/apps/webmail

# -------------------------------------------------------------------------------
# Start pChart2.4 w/PHP 7 support upgrade Below
# -------------------------------------------------------------------------------
	
echo -e "\n--- Starting pChart2.4 upgrade..."
rm -rf /etc/sentora/panel/etc/lib/pChart2/
cp -r  ~/sentora_php7_upgrade/etc/lib/pChart2 $PANEL_PATH/panel/etc/lib/
	
# -------------------------------------------------------------------------------
# Start PHPsysinfo 3.3.1 upgrade Below
# -------------------------------------------------------------------------------
	
echo -e "\nStarting PHPsysinfo upgrade to 3.3.1..."
rm -rf /etc/sentora/panel/etc/apps/phpsysinfo/
cp -r  ~/sentora_php7_upgrade/etc/apps/phpsysinfo $PANEL_PATH/panel/etc/apps/
	
# Setup config file
mv -f /etc/sentora/panel/etc/apps/phpsysinfo/phpsysinfo.ini.new /etc/sentora/panel/etc/apps/phpsysinfo/phpsysinfo.ini
	
# -------------------------------------------------------------------------------
# Start PHPmyadmin 4.9.2 upgrade Below - TESTING WHICH VERSION IS BEST HERE.
# -------------------------------------------------------------------------------
		
#--- Some functions used many times below
# Random password generator function
passwordgen() {
   	l=$1
   	[ "$l" == "" ] && l=16
   	tr -dc A-Za-z0-9 < /dev/urandom | head -c ${l} | xargs
}
	
echo -e "\n-- Configuring phpMyAdmin 4.9..."
phpmyadminsecret=$(passwordgen 32);
	
#echo "password"
#echo -e "$phpmyadminsecret"
	
#Version checker function for Mysql & PHP
versioncheck() { 
	echo "$@" | gawk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'; 
}

# Start
echo -e -p "Installer is about to upgrade PHPmyadmin to 4.9.2."

## START Install here
					
#PHPMYADMIN_VERSION="STABLE"
PHPMYADMIN_VERSION="4.9.2-all-languages"
cd  $PANEL_PATH/panel/etc/apps/ || exit
														
# empty folder
rm -rf /etc/sentora/panel/etc/apps/phpmyadmin
						
						
						
						

# Download/Get PHPmyadmin 4.9.2
#wget -nv -O phpmyadmin.zip https://github.com/phpmyadmin/phpmyadmin/archive/$PHPMYADMIN_VERSION.zip				
cp -r  ~/sentora_php7_upgrade/etc/apps/phpmyadmin.zip phpmyadmin.zip
	
	
	
	
							
unzip -q  phpmyadmin.zip
mv phpMyAdmin-$PHPMYADMIN_VERSION phpmyadmin
																	
cd phpmyadmin || exit							
cd $PANEL_PATH/panel/etc/apps/ || exit
chmod -R 777 phpmyadmin
chown -R "$HTTP_USER":"$HTTP_USER" phpmyadmin
							
mv $PANEL_PATH/panel/etc/apps/phpmyadmin_old/robots.txt phpmyadmin/robots.txt
                       	
mkdir -p /etc/sentora/panel/etc/apps/phpmyadmin/tmp
chmod -R 777 /etc/sentora/panel/etc/apps/phpmyadmin/tmp
ln -s $PANEL_CONF/phpmyadmin/config.inc.php $PANEL_PATH/panel/etc/apps/phpmyadmin/config.inc.php
chmod 644 $PANEL_CONF/phpmyadmin/config.inc.php
sed -i "s|\$cfg\['blowfish_secret'\] \= '.*';|\$cfg\['blowfish_secret'\] \= '$phpmyadminsecret';|" $PANEL_CONF/phpmyadmin/config.inc.php

# Remove phpMyAdmin's setup folders in case they were left behind.
rm -rf phpmyadmin/setup
rm -rf phpmyadmin/sql
rm -rf phpmyadmin/test
rm -rf phpmyadmin.zip
#rm -rf phpmyadmin_old

# -------------------------------------------------------------------------------
	
# Update Sentora APACHE_CHANGED, DBVERSION and run DAEMON

# Set apache daemon to build vhosts file.
$PANEL_PATH/panel/bin/setso --set apache_changed "true"
	
# Set dbversion
$PANEL_PATH/panel/bin/setso --set dbversion "$SENTORA_UPDATER_VERSION"
	
# Run Daemon
php -d "sp.configuration_file=/etc/sentora/configs/php/sp/sentora.rules" -q $PANEL_PATH/panel/bin/daemon.php		
	
# -------------------------------------------------------------------------------

# Clean up files downloaded for install/update
rm -r ~/sentora_php7_upgrade

# Disable PHP 7.1, 7.2, 7.4 package tell we can test. AGAIN to make ubuntu 16.04 didnt override during install(ISSUE)
if [[ "$OS" = "Ubuntu" ]]; then
	sudo apt-mark hold php7.1
	sudo apt-mark hold php7.2
	sudo apt-mark hold php7.4
fi

service "$DB_SERVICE" restart
service "$HTTP_SERVICE" restart
service postfix restart
service dovecot restart
service "$CRON_SERVICE" restart
service "$BIND_SERVICE" restart
service proftpd restart
service atd restart

# -------------------------------------------------------------------------------

echo -e "\nDone updating all Sentora_core and PHP 7.3 files"
echo -e "\nEnjoy and have fun testing!"
echo -e "\nWe are done upgrading Sentora 1.0.3 - PHP 5.* w/Suhosin to PHP 7.3 w/Snuffleupagus"

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
