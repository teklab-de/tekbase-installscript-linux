#!/bin/bash

# TekBase - Server Control Panel
# Copyright TekLab
# Christian Frankenstein
# Website: https://teklab.de
# Email: service@teklab.de
# Discord: https://discord.gg/K49XAPv

# You can start webinstall.sh fully automatically with the command:
# ./webinstall.sh 2 1 1 2 "Debian" "9" "10000" "w2a384cj3d80smcz2x245ki49sg0i"

##############################
# Command Line Variables     #
##############################
# 1 = "german" otherwise "english"
langsel=$1

# 1 = Webserver + TekBASE + Teamspeak 3 + Dedicated installation
# 2 = Webserver + TekBASE + Dedicated installation
# 3 = Webserver + TekBASE"
# 4 = Webserver + Teamspeak 3 + Dedicated installation
# 5 = Webserver + Dedicated installation
# 6 = Webserver only Ioncube, Pecl SSH, Geoip, Qstat and FTP
# 7 = Semi-automatic web server installation with requests
# 8 = Teamspeak 3 + Dedicated installation
# 9 = Dedicated installation
modsel=$2

# 1 = No further yes/no queries
yessel=$3

# 1 = SuSE
# 2 = Debian / Ubuntu
# 3 = CentOS / Fedora / Red Hat
os_install=$4

# "CentOS", "Debian", "Fedora", "Red Hat", "SuSE", "Ubuntu"
os_name=$5

# Only the major version (e.g. 18 not 18.04)
os_version=$6

# 32 or 64Bit
os_typ=$(uname -m)

# If you are a reseller then enter your reseller ID and Key, otherwise this parameters are empty
# !currently not available!
# resellerid=$7
# resellerkey=$8

installhome=$(pwd)


##############################
# Colored Message            #
##############################
function color {
    if [ "$1" = "c" ]; then
        txt_color=6
    fi  
    if [ "$1" = "g" ]; then
        txt_color=2
    fi
    if [ "$1" = "r" ]; then
        txt_color=1
    fi
    if [ "$1" = "y" ]; then
        txt_color=3
    fi
    if [ "$2" = "n" ]; then
        echo -n "$(tput setaf $txt_color)$3"
    else
        echo "$(tput setaf $txt_color)$3"   
    fi
    tput sgr0
}


##############################
# Generate Password          #
##############################
function gen_passwd { 
    PWCHARS=$1
    [ "$PWCHARS" = "" ] && PWCHARS=16
    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${PWCHARS} | xargs
}


##############################
# Loading Spinner            #
##############################
function loading {
    SPINNER=("-" "\\" "|" "/")

    for SEQUENCE in $(seq 1 $1); do
        for I in "${SPINNER[@]}"; do
            echo -ne "\b$I"
            sleep 0.1
        done
    done
}


##############################
# Create Directory           #
##############################
function make_dir {
    if [ "$1" != "" -a ! -d $1 ]; then
        mkdir -p $1
    fi
}


##############################
# Check Apache               #
##############################
function chk_apache {
    apache_inst=0
    if [ "$1" != "3" ]; then
        checka=$(which apache 2>&-)
        checkb=$(which apache2 2>&-)
        checkc=$(find /usr/include -name apache2)
        checkd=$(find /usr/include -name apache)
        if [ "$checka" != "" -o "$checkb" != "" -o "$checkc" != "" -o "$checkd" != "" ]; then
            apache_inst=1
        fi
    else
        checka=$(which httpd | grep -i "/httpd" 2>&-)
        if [ "$checka" != "" ]; then
            apache_inst=1
        fi    
    fi
}

##############################
# Check Netstat              #
##############################
function chk_netstat {
    netstat_inst=0
    check=$(which netstat 2>&-)
    if [ -n "$check" ]; then
        netstat_inst=1
    fi
}
    
##############################
# Check OS                   #
##############################
function chk_os {
    os_install=""
    os_name=""
    os_version=""
    check=$(cat /etc/*-release | grep -i 'CentOS')
    if [ -n "$check" ]; then
        os_install=3
        os_name="CentOS"
        os_version=$(cat /etc/*-release | grep -i 'VERSION_ID' | awk -F "\"" '{print $2}')
    fi
    
    check=$(cat /etc/*-release | grep -i 'Debian')
    if [ -n "$check" -a "$os_install" = "" ]; then
        os_install=2
        os_name="Debian"
        os_version=$(cat /etc/*-release | grep -i 'VERSION_ID' | awk -F "\"" '{print $2}')
    fi
    
    check=$(cat /etc/*-release | grep -i 'Fedora')
    if [ -n "$check" -a "$os_install" = "" ]; then
        os_install=3
        os_name="Fedora"
        os_version=$(cat /etc/*-release | grep -i 'VERSION_ID' | awk -F "=" '{print $2}')
    fi
    
    check=$(cat /etc/*-release | grep -i 'Red Hat')
    if [ -n "$check" -a "$os_install" = "" ]; then
        os_install=3
        os_name="Red Hat"
        os_version=$(cat /etc/*-release | grep -i 'VERSION_ID' | awk -F "\"" '{print $2}')
    fi
    
    check=$(cat /etc/*-release | grep -i 'SUSE')
    if [ -n "$check" -a "$os_install" = "" ]; then
        os_install=1
        os_name="SuSE"
        os_version=$(cat /etc/*-release | grep -i 'VERSION_ID' | awk -F "\"" '{print $2}' | awk -F "." '{print $1}')
    fi
    
    check=$(cat /etc/*-release | grep -i 'Ubuntu')
    if [ -n "$check" -a "$os_install" = "" ] || [ -n "$check" -a "$os_name" = "Debian" ]; then
        os_install=2
        os_name="Ubuntu"
        os_version=$(cat /etc/*-release | grep -i 'VERSION_ID' | awk -F "\"" '{print $2}' | awk -F "." '{print $1}')
    fi
}


##############################
# Check MySQL                #
##############################
function chk_mysql {
    mysql_inst=0
    if [ "$1" != "3" ]; then
        checka=$(which mysql 2>&-)
    else
        checka=$(which mysql | grep -i "/mysql" 2>&-)
    fi
    if [ "$checka" != "" ]; then
        mysql_inst=1
    fi  
}


##############################
# Check PHP                  #
##############################
function chk_php {
    php_inst=0
    checka=$(php -m | grep -i "gd")
    if [ "$1" != "3" ]; then
        checkb=$(which php 2>&-)
    else
        checkb=$(which php | grep -i "/php" 2>&-)
    fi
    if [ "$checka" != "" -a "$checkb" != "" ]; then
        php_inst=1
    fi  
}


##############################
# Check Web Panel            #
##############################
function chk_panel {
    web_panel="0"
    if [ -f /etc/init.d/psa ]; then
        web_panel="Plesk"
    elif [ -f /usr/local/vesta/bin/v-change-user-password ]; then
        web_panel="VestaCP"
    elif [ -d /root/confixx ]; then
        web_panel="Confixx"
    elif [ -d /var/www/froxlor ]; then
        web_panel="Froxlor"
    elif [ -d /etc/imscp ]; then
        web_panel="i-MSCP"
    elif [ -d /usr/local/ispconfig ]; then
        web_panel="ISPConfig"
    elif [ -d /var/cpanel ]; then
        web_panel="cPanel"
    elif [ -d /usr/local/directadmin ]; then
        web_panel="DirectAdmin"
    fi
}


##############################
# Select Yes / No            #
##############################
function select_yesno {
    clear
    echo -e "$1"
    echo ""
    if [ "$langsel" = "1" ]; then
        echo "(1) Ja - Weiter"
        echo "(2) Nein - Beenden"
    else
        echo "(1) Yes - Continue"
        echo "(2) No - Exit" 
    fi
    echo ""

    if [ "$langsel" = "1" ]; then
        if [ "$yesno" = "" ]; then
            echo -n "Bitte geben Sie ihre Auswahl an: "
        else
            color r n "Bitte geben Sie entweder 1 oder 2 ein: "
        fi
    else
        if [ "$yesno" = "" ]; then
            echo -n "Please enter your selection: "
        else
            color r n "Please enter either 1 or 2: "
        fi
    fi

    read -n 1 yesno

    for i in $yesno; do
    case "$i" in
        '1')
            clear
        ;;
        '2')
            clear
            exit 0
        ;;
        *)
            yesno=99
            clear
            select_yesno "$1"
        ;;
    esac
    done
}


##############################
# Select Lanuage             #
##############################
function select_lang {
    clear
    echo "TekBASE Webserver Installer"
    echo ""
    echo "(1) German"
    echo "(2) English"
    echo "(3) Exit"
    echo ""

    if [ "$langsel" = "" ]; then
        echo "Bitte waehlen Sie ihre Sprache."
        echo -n "Please select your language: "
    else
        color r x "Bitte geben Sie entweder 1,2 oder 3 ein!"
        color r n "Please enter only 1,2 or 3: "
    fi

    read -n 1 langsel

    for i in $langsel; do
    case "$i" in
        '1')
            clear
        ;;
        '2')
            clear
        ;;
        '3')
            clear
            exit 0
        ;;
        *)
            langsel=99
            clear
            select_lang
        ;;
    esac
    done
}


##############################
# Select Mode                #
##############################
function select_mode {
    clear
    if [ "$langsel" = "1" ]; then
        echo "Installation Auswahl"
        echo ""
        echo "Waehlen Sie 1 oder 2. Dies ist perfekt fuer Anfaenger geeignet,"
        echo "welche nur einen Rootserver nutzen."
        echo ""
        echo "(1) Webserver + TekBASE + Teamspeak 3 + Rootserver Einrichtung"
        echo "(2) Webserver + TekBASE + Rootserver Einrichtung"
        echo "(3) Webserver + TekBASE"
        echo "(4) Webserver + Teamspeak 3 + Rootserver Einrichtung"
        echo "(5) Webserver + Rootserver Einrichtung"
        echo "(6) Webserver nur Ioncube, Pecl SSH, Geoip, Qstat und FTP"
        echo "(7) Semi-automatische Webserver Installation mit Abfrage"
        echo ""
        echo "(8) Teamspeak 3 + Rootserver Einrichtung"
        echo "(9) Rootserver Einrichtung"
        echo "(0) Exit"
    else
        echo "Installation selection"
        echo ""
        echo "Choose 1 or 2. This is perfect for beginners who use only one"
        echo "dedicated server."
        echo ""
        echo "(1) Webserver + TekBASE + Teamspeak 3 + Dedicated installation"
        echo "(2) Webserver + TekBASE + Dedicated installation"
        echo "(3) Webserver + TekBASE"
        echo "(4) Webserver + Teamspeak 3 + Dedicated installation"
        echo "(5) Webserver + Dedicated installation"
        echo "(6) Webserver only Ioncube, Pecl SSH, Geoip, Qstat and FTP"
        echo "(7) Semi-automatic web server installation with requests"
        echo ""
        echo "(8) Teamspeak 3 + Dedicated installation"
        echo "(9) Dedicated installation"
        echo "(0) Exit"
    fi
    echo ""

    if [ "$langsel" = "1" ]; then
        if [ "$modsel" = "" ]; then
            echo -n "Bitte geben Sie ihre Auswahl an: "
        else
            color r n "Bitte geben Sie entweder 1,2,3,4,5,6,7,8,9 oder 0 ein: "
        fi
    else
        if [ "$modsel" = "" ]; then
            echo -n "Please enter your selection: "
        else
            color r n "Please enter either 1,2,3,4,5,6,7,8,9 or 0: "
        fi
    fi

    read -n 1 modsel

    for i in $modsel; do
    case "$i" in
        '1')
            clear
        ;;
        '2')
            clear
        ;;
        '3')
            clear
        ;;
        '4')
            clear
        ;;
        '5')
            clear
        ;;
        '6')
            clear
        ;;
        '7')
            clear
        ;;
        '8')
            clear
        ;;
        '9')
            clear
        ;;
        '0')
            clear
            exit 0
        ;;
        *)
            modsel=99
            clear
            select_mode
        ;;
    esac
    done
}


##############################
# Select URL                 #
##############################
function select_url {
    clear
    if [ "$langsel" = "1" ]; then
        echo "Domains Auswahl"
        echo ""
    else
        echo "Domain selection"
        echo ""
    fi

    cd $1
    urlcounter=1
    for siteurl in $(find * -maxdepth 0 -type d)
    do
        if [ "$(grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$' <<< $siteurl)" != "" ]; then
            echo "($urlcounter) $siteurl"
            let urlcounter=$urlcounter+1
        fi
        if [ "$urlcounter" -gt 9 ]; then
            break
        fi
    done
	
    echo ""    
    echo "(0) Exit"
    echo ""

    if [ "$langsel" = "1" ]; then
        if [ "$urlsel" = "" ]; then
            echo -n "Bitte geben Sie ihre Auswahl an: "
        else
            color r n "Bitte geben Sie entweder 1, ... oder 0 ein: "
        fi
    else
        if [ "$urlsel" = "" ]; then
            echo -n "Please enter your selection: "
        else
            color r n "Please enter either 1, ... or 0: "
        fi
    fi

    read -n 1 urlsel

    for i in $urlsel; do
    case "$i" in
        '1')
            clear
        ;;
        '2')
            clear
        ;;
        '3')
            clear
        ;;
        '4')
            clear
        ;;
        '5')
            clear
        ;;
        '6')
            clear
        ;;
        '7')
            clear
        ;;
        '8')
            clear
        ;;
        '9')
            clear
        ;;
        '0')
            clear
            exit 0
        ;;
        *)
            urlsel=99
            clear
            select_url
        ;;
    esac
    done

    let urlcounter=$urlcounter-1
    
    if [ "$urlsel" -gt "$urlcounter" ]; then
        select_url
    fi

    urlcounter=1  
    for siteurl in $(find * -maxdepth 0 -type d)
    do
        if [ "$(grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$' <<< $siteurl)" != "" ]; then
            if [ "$urlcounter" = "$urlsel" ]; then
                site_url=$siteurl
                break
            else
                let urlcounter=$urlcounter+1
            fi
        fi
    done
}


##############################
# Choose Lang                #
##############################
if [ ! -n "$langsel" ]; then
    select_lang
fi


##############################
# Test OS                    #
##############################
if [ ! -n "$os_install" -a ! -n "$os_name" -a ! -n "$os_version" ]; then
    chk_os
fi

if [ ! -n "$os_install" -o ! -n "$os_name" -o ! -n "$os_version" ]; then
    clear
    if [ "$langsel" = "1" ]; then
        color r x "Es wird nur CentOS, Debian, Fedora, Red Hat, SuSE und Ubuntu unterstuetzt."
    else
        color r x "Only CentOS, Debian, Fedora, Red Hat, SuSE and Ubuntu are supported."
    fi
    exit 0
fi

if [ ! -n "$yessel" ]; then
    yesno=""
    if [ "$langsel" = "1" ]; then
        select_yesno "Ihr System: $os_name $os_version - $os_typ. Ist dies korrekt?"
    else
        select_yesno "Your system: $os_name $os_version - $os_typ. Is this correct?"
    fi
fi


##############################
# Test Root                  #
##############################
if [ "$(id -u)" != "0" ]; then
    su -
fi

if [ "$(id -u)" != "0" ]; then
    clear
    if [ "$langsel" = "1" ]; then
        color r x "Sie benoetigen root Rechte."
    else
        color r x "You need root privileges."
    fi
    exit 0
fi


##############################
# Get IP, Hostname           #
##############################
local_ip=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
if [ "$local_ip" = "" ]; then
    host_name=$(hostname -fhost_name | awk '{print tolower($0)}')
else
    host_name=$(getent hosts $local_ip | awk '{print tolower($2)}' | head -n 1)
fi
if [ "$host_name" = "" ] || [ "$host_name" = "0" ]; then
    host_name="$local_ip";
fi


##############################
# Choose Mode                #
##############################
if [ ! -n "$modsel" ]; then
    select_mode
fi


chk_netstat

echo "" > /home/tekbase_status.txt


##############################
# Install Libs And Progs     #
##############################
if [ ! -n "$yessel" ]; then
    yesno=""
    if [ "$langsel" = "1" ]; then
        select_yesno "Es wird jetzt autoconf, automake, build-essential, curl, expect, gcc, hddtemp,\ndmidecode, lm-sensors, m4, make, net-tools, openjdk, openssl-dev, patch, pwgen,\nscreen, smartmontools, sqlite, sudo, sysstat, unzip und wget installiert."
    else
        select_yesno "Autoconf, automake, build-essential, curl, expect gcc, hddtemp, dmidecode,\nlm-sensors, m4, make, net-tools, openjdk, openssl-dev, patch, pwgen, screen,\nsmartmontools, sqlite, sudo, sysstat, unzip and wget is now installed."
    fi
fi

case "$os_install" in
    '1')
        clear
        if [ "$modsel" != "7" ]; then
            chkyes="--non-interactive install"
            zypper --non-interactive update
         else
            chkyes="install"
            zypper update
        fi
        for i in autoconf automake m4 make screen sudo curl wget sqlite sqlite3 expect gcc libopenssl-devel hddtemp dmidecode lm-sensors net-tools sysstat smartmontools patch pwgen unzip java-1_8_0-openjdk git; do
            zypper $chkyes $i
        done
        zypper $chkyes -t pattern devel_basis
    ;;
    '2')
        clear
        if [ "$modsel" != "7" ]; then
            chkyes="-y"
            apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
        else
            chkyes=""
            apt-get update && apt-get upgrade && apt-get dist-upgrade
        fi     
        for i in autoconf automake build-essential m4 make debconf-utils screen sudo curl wget sqlite sqlite3 expect gcc libssh2-1-dev libssl-dev hddtemp dmidecode lm-sensors net-tools sysstat smartmontools patch pwgen unzip git; do
            apt-get install $i $chkyes
        done
        if [ "$os_version" -lt "14" -a "$os_name" = "Ubuntu" ] || [ "$os_version" -lt "8" -a "$os_name" = "Debian" ]; then
            apt-get install openjdk-7-jre $chkyes
        else
            apt-get install openjdk-8-jre $chkyes        
        fi
    ;;
    '3')
        clear
        if [ "$modsel" != "7" ]; then
            chkyes="-y"
            yum update && yum upgrade -y
        else
            chkyes=""
            yum update && yum upgrade
        fi
        yum -y install epel-release
        yum repolist
        for i in autoconf automake m4 make screen sudo curl wget sqlite expect gcc openssl-devel hddtemp dmidecode lm-sensors net-tools sysstat smartmontools patch pwgen unzip java-1.8.0-openjdk git; do
            yum install $i $chkyes
        done
        yum groupinstall 'Development Tools' $chkyes
    ;;
esac

sensors-detect --auto
service kmod start


##############################
# Install Apache, Php, MySQL #
##############################
if [ $modsel -lt 8 ]; then
    chk_apache $os_install
 
    if [ "$apache_inst" = "0" ]; then
        if [ ! -n "$yessel" ]; then
            yesno=""
            if [ "$langsel" = "1" ]; then
                select_yesno "Apache Webserver nicht gefunden. Dieser wird jetzt installiert."
            else
                select_yesno "Apache web server not found. This will now be installed."
            fi
        fi

        if [ "$os_install" = "1" ]; then
            if [ "$modsel" != "7" ]; then
                zypper --non-interactive install apache2
            else
                zypper install apache2	    
            fi
        fi
        if [ "$os_install" = "2" ]; then
            if [ "$modsel" != "7" ]; then
                export DEBIAN_FRONTEND=noninteractive
                apt-get install apache2 -y
            else
                apt-get install apache2
            fi
        fi
        if [ "$os_install" = "3" ]; then
            if [ "$modsel" != "7" ]; then
                yum install httpd -y
            else
                yum install httpd	    
            fi
        fi
        
        chk_apache $os_install

        if [ "$apache_inst" = "0" ]; then
            clear
            if [ "$langsel" = "1" ]; then
                color r x "Der Apache Webserver konnte nicht installiert werden."
                color r x "Bitte nehmen Sie die Installation selbst vor."
            else
                color r x "The Apache web server could not be installed."
                color r x "Please install it yourself."
            fi 
            echo "Check apache: error" >> /home/tekbase_status.txt
            exit 0
        fi
        echo "Check apache: ok" >> /home/tekbase_status.txt
    else
        echo "Check apache: ok" >> /home/tekbase_status.txt    
    fi

    if [ ! -n "$yessel" ]; then
        yesno=""
        if [ "$langsel" = "1" ]; then
            select_yesno "Es wird jetzt php, php-common, php-cli, php-curl, php-gd, php-geoip, php-json,\nphp-mail, php-mcrypt, php-mbstring, php-mysql, php-ssh2, php-xml und php-zip\ninstalliert."
        else
            select_yesno "Php, php-common, php-cli, php-curl, php-gd, php-geoip, php-json, php-mail,\nphp-mcrypt, php-mbstring,php-mysql, php-ssh2, php-xml and php-zip is now\ninstalled."
        fi
    fi

    if [ "$os_install" = "1" ]; then
        if [ "$os_version" -lt "42" ]; then
            for i in apache2-mod-php5 php5 php5-common php5-cli php5-curl php5-devel php5-gd php5-geoip php5-json php5-mail php5-mcrypt php5-mbstring php5-mysql php5-ssh2 php5-xml php5-zip; do
                zypper $chkyes $i
            done
        else
            for i in apache2-mod-php7 php7 php7-common php7-cli php7-curl php7-devel php7-gd php7-geoip php7-json php7-mail php7-mcrypt php7-mbstring php7-mysql php7-ssh2 php7-xml php7-zip; do
                zypper $chkyes $i
            done
        fi
    fi
    if [ "$os_install" = "2" ]; then
     	if [ "$os_version" -lt "16" -a "$os_name" = "Ubuntu" ] || [ "$os_version" -lt "9" -a "$os_name" = "Debian" ]; then
      	    for i in libapache2-mod-php5 php5 php5-common php5-cli php5-curl php5-dev php5-gd php5-geoip php5-json php5-mail php5-mcrypt php5-mbstring php5-mysql php5-ssh2 php5-xml php5-zip; do
                apt-get install $i $chkyes
            done
        else
            for i in libapache2-mod-php php php-common php-cli php-curl php-dev php-gd php-geoip php-json php-mail php-mcrypt php-mbstring php-mysql php-ssh2 php-xml php-zip; do
                apt-get install $i $chkyes
            done
        fi
    fi
    if [ "$os_install" = "3" ]; then
        for i in php php-common php-cli php-devel php-gd php-mbstring php-mysql php-xml; do
            yum install $i $chkyes
        done
    fi
    
    chk_php $os_install

    if [ "$php_inst" = "0" ]; then
        clear
        if [ "$langsel" = "1" ]; then
            color r x "PHP und die Extensions konnten nicht vollstaendig installiert werden."
            color r x "Bitte nehmen Sie die Installation selbst vor."
        else
            color r x "PHP and the extensions could not be installed completely."
            color r x "Please install it yourself."
        fi 
        echo "Check php: error" >> /home/tekbase_status.txt
        exit 0
    fi
    echo "Check php: ok" >> /home/tekbase_status.txt

    chk_mysql $os_install
    
    if [ "$mysql_inst" = "0" ]; then
        if [ ! -n "$yessel" ]; then
            yesno=""
            if [ "$langsel" = "1" ]; then
                select_yesno "MySQL/MariaDB Server nicht gefunden. Dieser wird jetzt installiert."
            else
                select_yesno "MySQL/MariaDB server not found. This will now be installed."
            fi
        fi
        
        if [ "$os_install" = "1" ]; then
            zypper $chkyes mariadb mariadb-tools
    	    service mysql restart
        fi
        if [ "$os_install" = "2" ]; then
            if [ "$modsel" != "7" ]; then
                export DEBIAN_FRONTEND=noninteractive
            fi
            
            mysqlpwd=$(gen_passwd 8)
            echo "MySQL root password: $mysqlpwd" > /home/tekbase_mysql.txt

            if [ "$os_version" -lt "16" -a "$os_name" = "Ubuntu" ] || [ "$os_version" -lt "9" -a "$os_name" = "Debian" ]; then
                mysqlpwd=$(gen_passwd 8)
                if [ "$modsel" != "7" ]; then
                    debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysqlpwd"
                    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysqlpwd"
                fi
                apt-get install mysql-server mysql-client mysql-common $chkyes  	        
            else
                if [ "$modsel" != "7" ]; then
                    debconf-set-selections <<< "mariadb-server mysql-server/root_password password $mysqlpwd"
                    debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $mysqlpwd" 
                fi
                apt-get install mariadb-server mariadb-client $chkyes
            fi
            service mysql restart
        fi
        if [ "$os_install" = "3" ]; then
            yum install mariadb mariadb-server $chkyes
            service mariadb restart
        fi
        
        chk_mysql $os_install
        
        if [ "$mysql_inst" = "0" ]; then
            clear
            if [ "$langsel" = "1" ]; then
                color r x "Der MySQL/MariaDB Server konnte nicht installiert werden."
                color r x "Bitte nehmen Sie die Installation selbst vor."
            else
                color r x "The MySQL/MariaDB server could not be installed."
                color r x "Please install it yourself."
            fi 
            echo "Check mysql: error" >> /home/tekbase_status.txt
            exit 0
        fi
        echo "Check mysql: ok" >> /home/tekbase_status.txt
    else
        mysqlpwd=""
        echo "Check mysql: ok" >> /home/tekbase_status.txt    
    fi
fi


##############################
# Check Php Version And Path #
##############################
if [ $modsel -lt 8 ]; then
    service apache2 restart
    php_ioncube=$(php -m | grep -i "ioncube")
    # php_geoip=$(php -m | grep -i "geoip")
    php_ssh=$(php -m | grep -i "ssh2") 
    # php_gd=$(php -m | grep -i "gd") 
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    php_inidir=$(php -r "echo PHP_CONFIG_FILE_PATH;")
    php_extdir=$(php -r "echo PHP_EXTENSION_DIR;")
    php_exinidir=$(php -r "echo PHP_CONFIG_FILE_SCAN_DIR;")
    php_dir=$(dirname "$php_inidir");
    if [ -f $php_dir/apache2/php.ini ]; then
        php_apachedir="$php_dir/apache2"
    fi
    if [ -f $php_dir/fpm/php.ini ]; then
        php_fpmdir="$php_dir/fpm"
    fi
fi


##############################
# Install Pecl SSH2, Ioncube #
##############################
if [ $modsel -lt 8 ]; then
    if [ "$php_ssh" = "" ]; then
        cd $installhome
        
        if [ ! -f libssh2-1.9.0.tar.gz ]; then
            wget --no-check-certificate https://www.libssh2.org/download/libssh2-1.9.0.tar.gz
        fi
        tar -xzf libssh2-1.9.0.tar.gz
        cd libssh2-1.9.0
        ./configure --prefix=/usr --with-openssl=/usr && make install
        cd ..

        if [ "$php_version" = "5.6" ] || [ "$php_version" = "7.0" ]; then
            if [ ! -f ssh2-0.13.tgz ]; then
                wget --no-check-certificate https://pecl.php.net/get/ssh2-0.13.tgz
            fi
            tar -xzf ssh2-0.13.tgz
            cd ssh2-0.13
            phpize && ./configure --with-ssh2 && make install
            cd ..
            rm -r ssh2-0.13.0
            rm ssh2-0.13.tgz
        else
            if [ ! -f ssh2-1.1.2.tgz ]; then
                wget --no-check-certificate https://pecl.php.net/get/ssh2-1.1.2.tgz
            fi
            tar -xzf ssh2-1.1.2.tgz
            cd ssh2-1.1.2
            phpize && ./configure --with-ssh2 && make install
            cd ..
            rm -r ssh2-1.1.2
            rm ssh2-1.1.2.tgz
        fi

        rm -r libssh2-1.9.0
        rm package.xml
    
        cd $php_exinidir
        echo "extension=ssh2.so" > 20-ssh2.ini
        if [ "$os_install" = "1" -o "$os_install" = "2" ]; then
            if [ -d $php_apachedir/conf.d ]; then
                echo "extension=ssh2.so" > $php_apachedir/conf.d/20-ssh2.ini
            fi
            if [ -d $php_fpmdir/conf.d ]; then
                echo "extension=ssh2.so" > $php_apachedir/conf.d/20-ssh2.ini
            fi            
        fi
        
        php_ssh=$(php -m | grep -i "ssh2") 
        if [ "$php_ssh" = "" ]; then
            clear
            if [ "$langsel" = "1" ]; then
                color r x "Die Pecl SSH2 Extension für PHP konnte nicht installiert werden."
                color r x "Bitte nehmen Sie die Installation selbst vor."
            else
                color r x "The Pecl SSH2 extension for PHP could not be installed."
                color r x "Please install it yourself."
            fi 
            echo "Check ssh2: error" >> /home/tekbase_status.txt
            exit 0
        else
            echo "Check ssh2: ok" >> /home/tekbase_status.txt
        fi
    else
        echo "Check ssh2: ok" >> /home/tekbase_status.txt    
    fi
   
    if [ "$php_ioncube" = "" ]; then
        cd /usr/local

        if [ -d ioncube ]; then
            rm ioncube
        fi

        if [ "$os_typ" = "x86_64" ]; then
            wget --no-check-certificate https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
            tar xvfz ioncube_loaders_lin_x86-64.tar.gz
        else
            wget --no-check-certificate https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz
            tar xvfz ioncube_loaders_lin_x86.tar.gz
        fi
        if [ ! -d ioncube ]; then
            cd $installhome
            mv ioncube_x86-64.tar.gz /usr/local
            mv ioncube_x86.tar.gz /usr/local
            cd /usr/local
        
            if [ "$os_typ" = "x86_64" ]; then
                tar -xzf ioncube_x86-64.tar.gz
                rm ioncube_x86-64.tar.gz
            else
                tar -xzf ioncube_x86.tar.gz
                rm  ioncube_x86.tar.gz
            fi
        fi
        
        cd ioncube
        cp *.* $php_extdir

        cd $php_exinidir
        echo "zend_extension=ioncube_loader_lin_$php_version.so" > 00-ioncube.ini
        if [ "$os_install" = "1" -o "$os_install" = "2" ]; then
            if [ -d $php_apachedir/conf.d ]; then
                echo "zend_extension=$php_extdir/ioncube_loader_lin_$php_version.so" > $php_apachedir/conf.d/00-ioncube.ini
            fi
            if [ -d $php_fpmdir/conf.d ]; then
                echo "zend_extension=$php_extdir/ioncube_loader_lin_$php_version.so" > $php_fpmdir/conf.d/00-ioncube.ini
            fi           
        fi 
        
        php_ioncube=$(php -m | grep -i "ioncube") 
        if [ "$php_ioncube" = "" ]; then 
            clear
            if [ "$langsel" = "1" ]; then
                color r x "Die Ioncube Extension für PHP konnte nicht installiert werden."
                color r x "Bitte nehmen Sie die Installation selbst vor."
            else
                color r x "The Ioncube extension for PHP could not be installed."
                color r x "Please install it yourself."
            fi 
            echo "Check ioncube: error" >> /home/tekbase_status.txt
            exit 0
        else
            echo "Check ioncube: ok" >> /home/tekbase_status.txt
        fi
    else
        echo "Check ioncube: ok" >> /home/tekbase_status.txt    
    fi
fi


##############################
# Configure Php              #
##############################
if [ $modsel -lt 8 ]; then
    if [ -f $php_inidir/php.ini ]; then
        sed -i '/allow_url_fopen/c\allow_url_fopen=on' $php_inidir/php.ini
        sed -i '/max_execution_time/c\max_execution_time=360' $php_inidir/php.ini
        sed -i '/max_input_time/c\max_input_time=1000' $php_inidir/php.ini
        sed -i '/memory_limit/c\memory_limit=128M' $php_inidir/php.ini
        sed -i '/post_max_size/c\post_max_size=32M' $php_inidir/php.ini
        sed -i '/upload_max_filesize/c\upload_max_filesize=32M' $php_inidir/php.ini
        echo "date.timezone=\"Europe/Berlin\"" >> $php_inidir/php.ini 
    fi
    if [ -f $php_apachedir/php.ini ]; then
        sed -i '/allow_url_fopen/c\allow_url_fopen=on' $php_apachedir/php.ini
        sed -i '/max_execution_time/c\max_execution_time=360' $php_apachedir/php.ini
        sed -i '/max_input_time/c\max_input_time=1000' $php_apachedir/php.ini
        sed -i '/memory_limit/c\memory_limit=128M' $php_apachedir/php.ini
        sed -i '/post_max_size/c\post_max_size=32M' $php_apachedir/php.ini
        sed -i '/upload_max_filesize/c\upload_max_filesize=32M' $php_apachedir/php.ini
        echo "date.timezone=\"Europe/Berlin\"" >> $php_apachedir/php.ini 
    fi
    if [ -f $php_fpmdir/php.ini ]; then
        sed -i '/allow_url_fopen/c\allow_url_fopen=on' $php_fpmdir/php.ini
        sed -i '/max_execution_time/c\max_execution_time=360' $php_fpmdir/php.ini
        sed -i '/max_input_time/c\max_input_time=1000' $php_fpmdir/php.ini
        sed -i '/memory_limit/c\memory_limit=128M' $php_fpmdir/php.ini
        sed -i '/post_max_size/c\post_max_size=32M' $php_fpmdir/php.ini
        sed -i '/upload_max_filesize/c\upload_max_filesize=32M' $php_fpmdir/php.ini
        echo "date.timezone=\"Europe/Berlin\"" >> $php_fpmdir/php.ini 
    fi
    
    if [ -f /etc/apache2/confixx_vhosts/web0.conf ]; then
        sed -i '/allow_url_fopen/c\php_admin_flag allow_url_fopen on' /etc/apache2/confixx_vhosts/web0.conf
    fi
    
    if [ -f /etc/apache2/confixx_mhost.conf ]; then
        sed -i '/allow_url_fopen/c\php_admin_flag allow_url_fopen on' /etc/apache2/confixx_mhost.conf
    fi
fi


##############################
# Restart Apache And Php     #
##############################
if [ $modsel -lt 8 ]; then
    if [ "$os_install" != "3" ]; then
        service apache2 restart
        service php5-fpm restart
        service php${php_version}-fpm restart
    else
        service httpd restart
    fi
fi


##############################
# Mail Check                 #
##############################
if [ $modsel -lt 8 ]; then
    if [ "$netstat_inst" = "1" ]; then
        check=$(netstat -tlpn | grep ":25 ")
    else
        check=$(ss -tlpn | grep ":25 ")
    fi
    if [ "$check" = "" ]; then
        check=$(which postfix 2>&-)
        if [ "$check" = "" ]; then
            if [ ! -n "$yessel" ]; then
                yesno=""
                if [ "$langsel" = "1" ]; then
                    select_yesno "Postfix wurde nicht gefunden. Dieser wird jetzt installiert."
                else
                    select_yesno "Postfix not found. This will now be installed."
                fi
            fi
            for i in $os_install; do
    	    case "$i" in
    	        '1')
    	            clear
    	            if [ "$modsel" != "7" ]; then
    	                zypper --non-interactive install postfix
    	            else
     	                zypper install postfix       
    	            fi
    	        ;;
    	        '2')
    	            clear
            	    if [ "$modsel" != "7" ]; then
            	        export DEBIAN_FRONTEND=noninteractive
            	        debconf-set-selections <<< "postfix postfix/mailname string $host_name"
            	        debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
            	        apt-get install postfix -y
            	    else
            	        apt-get install postfix 
            	    fi
    	        ;;
    	        '3')
            	    clear
            	    if [ "$modsel" != "7" ]; then
            	        yum install postfix -y
            	    else
            	        yum install postfix
            	    fi
    	        ;;
    	    esac
    	    done
        fi
    fi
fi


##############################
# Install Qstat              #
##############################
if [ "$os_install" = "2" ]; then
    apt-get install qstat
    if [ -f /usr/bin/qstat ]; then
        chmod 0755 /usr/bin/qstat
        cp /usr/bin/qstat /
    fi
    if [ ! -f /usr/bin/qstat -a -f /usr/bin/quakestat ]; then
        chmod 0755 /usr/bin/quakestat
        cp /usr/bin/quakestat /usr/bin/qstat
        cp /usr/bin/qstat /
    fi
fi

if [ ! -f /qstat ]; then
    cd $installhome
    if [ ! -f qstat.tar.gz ]; then
        wget --no-check-certificate https://teklab.s3.amazonaws.com/tekbase_qstat.tar.gz
        tar -xzf tekbase_qstat.tar.gz
        rm tekbase_qstat.tar.gz
    else
        tar -xzf qstat.tar.gz
        rm qstat.tar.gz 
    fi
    
    cd qstat
    ./configure && make all install
    chmod 0755 qstat
    cp qstat /usr/bin
    cp qstat /
    
    if [ -d /var/www/empty ]; then
        cp qstat /var/www/empty
    fi
    if [ -d /srv/www/empty ]; then
        cp qstat /srv/www/empty
    fi
    if [ -d /home/www/empty ]; then
        cp qstat /home/www/empty
    fi

    cd $installhome
    rm -r qstat
    
    if [ ! -f /qstat ]; then
        echo "Check qstat: error" >> /home/tekbase_status.txt
    else
        echo "Check qstat: ok" >> /home/tekbase_status.txt    
    fi
else
    echo "Check qstat: ok" >> /home/tekbase_status.txt
fi


##############################
# Install Scripts            #
##############################
if [ "$modsel" = "1" ] || [ "$modsel" = "2" ] || [ "$modsel" = "4" ] || [ "$modsel" = "5" ] || [ "$modsel" = "8" ] || [ "$modsel" = "9" ]; then
    if [ ! -f skripte.tar ]; then
        cd /home
        git clone https://github.com/teklab-de/tekbase-scripts-linux.git skripte
        if [ ! -f /skripte/autoupdater ]; then
            cd $installhome        
            wget --no-check-certificate https://teklab.s3.amazonaws.com/tekbase_scripts.tar
            tar -xzf tekbase_scripts.tar -C /home
            rm tekbase_scripts.tar
        fi
        cd skripte
        mkdir cache
        chmod 755 *
        chmod 777 cache
        cd $installhome
        
        if [ ! -f hlstats.tar ]; then
            wget --no-check-certificate https://teklab.s3.amazonaws.com/tekbase_hlstats.tar
            tar -xzf tekbase_hlstats.tar -C /home/skripte
            rm tekbase_hlstats.tar
        else
            tar -xzf hlstats.tar -C /home/skripte
            rm hlstats.tar
        fi
    else
        tar -xzf skripte.tar -C /home
        rm skripte.tar   
    fi

    userpwd=$(gen_passwd 8)
    useradd -g users -p $(perl -e 'print crypt("'$userpwd'","Sa")') -s /bin/bash -m user-webi -d /home/user-webi

    cd $installhome
    if [ ! -f user-webi.tar ]; then
        wget --no-check-certificate https://teklab.s3.amazonaws.com/tekbase_user-webi.tar
        tar -xzf tekbase_user-webi.tar -C /home
        rm tekbase_user-webi.tar
    else
        tar -xzf user-webi.tar -C /home
        rm user-webi.tar
    fi
    if [ ! -f keys.tar ]; then
		wget --no-check-certificate https://teklab.s3.amazonaws.com/tekbase_keys.tar
		tar -xzf tekbase_keys.tar -C /home/user-webi
        rm tekbase_keys.tar
    else
        tar -xzf keys.tar -C /home/user-webi
        rm keys.tar
    fi

    if [ -d /home/skripte ]; then
        echo "Check scripts: ok" >> /home/tekbase_status.txt
    else
        echo "Check scripts: error" >> /home/tekbase_status.txt    
    fi
fi


##############################
# Configure Sudo             #
##############################
if [ "$modsel" = "1" ] || [ "$modsel" = "2" ] || [ "$modsel" = "4" ] || [ "$modsel" = "5" ] || [ "$modsel" = "8" ] || [ "$modsel" = "9" ]; then
    if [ "$os_install" = "3" ]; then
        cp /etc/sudoers /etc/sudoers.tekbase
        rm /etc/sudoers
        echo "root ALL=(ALL)	ALL" >> /etc/sudoers
    else
        sed -i '/^user-webi*/d' /etc/sudoers
    fi
    
    echo "user-webi ALL=(ALL) NOPASSWD:	/home/skripte/" >> /etc/sudoers
    echo "user-webi ALL=(ALL) NOPASSWD:	/usr/bin/useradd" >> /etc/sudoers
    echo "user-webi ALL=(ALL) NOPASSWD:	/usr/bin/usermod" >> /etc/sudoers
    echo "user-webi ALL=(ALL) NOPASSWD:	/usr/bin/userdel" >> /etc/sudoers
    chmod 0400 /etc/sudoers
fi


##############################
# Check Sudo                 #
##############################
if [ "$modsel" = "1" ] || [ "$modsel" = "2" ] || [ "$modsel" = "4" ] || [ "$modsel" = "5" ] || [ "$modsel" = "8" ] || [ "$modsel" = "9" ]; then
    cd /home/skripte
    sudochk=$(su user-webi -c "sudo ./tekbase 1 tekbasewi testpw")
    cd ..
    if [ "$sudochk" = "ID1" ]; then
        echo "Check sudo: ok" >> /home/tekbase_status.txt
        userdel tekbasewi
        rm -r /home/tekbasewi
    else
    	echo "Check sudo: error" >> /home/tekbase_status.txt
    fi
fi


##############################
# Install Ftp                #
##############################
install_ftp="1"
if [ -f /etc/proftpd.tekbase ]; then
    install_ftp="0"
fi
if [ "$install_ftp" = "1" -a -f /etc/proftpd.conf ]; then
    install_ftp="0"
fi
if [ "$install_ftp" = "1" -a -f /etc/proftpd/proftpd.conf ]; then
    install_ftp="0"
fi
if [ "$install_ftp" = "1" -a -f /etc/vsftpd.conf ]; then
    install_ftp="0"
fi

if [ "$install_ftp" = "1" ]; then
    if [ "$os_install" = "1" ]; then
        if [ "$modsel" != "7" ]; then
            zypper --non-interactive install vsftpd
        else
            zypper install vsftpd
        fi
    fi
    if [ "$os_install" = "2" ]; then
        if [ "$modsel" != "7" ]; then
            export DEBIAN_FRONTEND=noninteractive
            debconf-set-selections <<< "proftpd-basic shared/proftpd/inetd_or_standalone select standalone"
            apt-get install proftpd -y
        else
            apt-get install proftpd
        fi
    fi
    if [ "$os_install" = "3" ]; then
        if [ "$modsel" != "7" ]; then
            yum install proftpd -y
        else
            yum install proftpd
        fi
    fi
fi


##############################
# Configure Ftp              #
##############################
if [ -f /etc/proftpd.conf -o -f /etc/proftpd/proftpd.conf ]; then
    if [ -f /etc/proftpd.conf ]; then
        ftp_file="/etc/proftpd.conf"
    fi
    if [ -f /etc/proftpd/proftpd.conf ]; then
        ftp_file="/etc/proftpd/proftpd.conf"
    fi
       
    if [ ! -d /etc/proftpd ]; then
    	mkdir /etc/proftpd
    fi
    
    if [ ! -f /etc/proftpd/ftpd.passwd ]; then
        touch /etc/proftpd/ftpd.passwd
        chmod 440 /etc/proftpd/ftpd.passwd
        chown proftpd.root /etc/proftpd/ftpd.passwd
        touch /etc/proftpd/ftpd.group
        chmod 440 /etc/proftpd/ftpd.group
        chown proftpd.root /etc/proftpd/ftpd.group
    fi
        
    cp $ftp_file /etc/proftpd.tekbase
    
    cd $installhome
    if [ -f proftpd_settings.cfg ]; then
    	cat proftpd_settings.cfg >> $ftp_file
    	echo "" >> $ftp_file
    fi

    sed -i '/^UseReverseDNS*/d' $ftp_file
    sed -i '/^IdentLookups*/d' $ftp_file
    sed -i '/^DefaultRoot*/d' $ftp_file
    sed -i '/^AuthGroupFile*/d' $ftp_file
    sed -i '/^AllowOverwrite*/d' $ftp_file
    sed -i '/^AuthUserFile*/d' $ftp_file
    sed -i '/^RequireValidShell*/d' $ftp_file
    sed -i '/^AuthOrder*/d' $ftp_file

    echo "AllowOverwrite on" >> $ftp_file
    echo "UseReverseDNS off" >> $ftp_file
    echo "IdentLookups off" >> $ftp_file
    echo "DefaultRoot ~" >> $ftp_file
    echo "RequireValidShell off" >> $ftp_file
    echo "AuthOrder mod_auth_pam.c mod_auth_unix.c mod_auth_file.c" >> $ftp_file
    echo "AuthUserFile /etc/proftpd/ftpd.passwd" >> $ftp_file
    echo "AuthGroupFile /etc/proftpd/ftpd.group" >> $ftp_file
        
    service proftpd restart
    service xinetd restart
    echo "Check proftpd: ok" >> /home/tekbase_status.txt
else
    if [ ! -f /etc/vsftpd.conf ]; then
        echo "Check proftpd: error" >> /home/tekbase_status.txt
    fi
fi

if [ -f /etc/vsftpd.conf ]; then
    cp /etc/vsftpd.conf /etc/vsftpd.tekbase
    
    sed -i '/write_enable*/c\write_enable=YES' /etc/vsftpd.conf
    sed -i '/chroot_local_user*/c\chroot_local_user=YES' /etc/vsftpd.conf
    sed -i '/userlist_enable*/c\userlist_enable=NO' /etc/vsftpd.conf

    service vsftpd restart
    service xinetd restart
    echo "Check vsftp: ok" >> /home/tekbase_status.txt
else
    echo "Check vsftpd: error" >> /home/tekbase_status.txt
fi


##############################
# Install Teamspeak 3        #
##############################
if [ "$modsel" = "1" ] || [ "$modsel" = "4" ] || [ "$modsel" = "8" ]; then
    cd $installhome
    adminpwd=$(gen_passwd 8)
    
    ps -u user-webi | grep ts3server | awk '{print $1}' | while read pid; do
    kill $pid
    done 
    
    if [ -f /home/user-webi/teamspeak3/ts3server_startscript.sh ]; then
        cd /home/user-webi
        if [ -f /home/user-webi/teamspeak3_backup/ts3server_startscript.sh ]; then
            rm -r teamspeak3_backup
        fi
        mv teamspeak3 teamspeak3_backup
        cd $installhome
    fi
    
    if [ "$os_typ" = "x86_64" ]; then
        ts_arch="amd64"
    else
        ts_arch="x86"
    fi
    
    for i in $(curl -s "http://dl.4players.de/ts/releases/?C=M;O=D" | grep -Po '(?<=href=")[0-9]+(\.[0-9]+){2,3}(?=/")' | sort -Vr); do
        ts_url="http://dl.4players.de/ts/releases/$i/teamspeak3-server_linux_$ts_arch-$i.tar.bz2"
        check=$(curl -I $ts_url 2>&1 | grep "HTTP/" | awk '{print $2}')
        if [ "$check" = "200" ]; then
            break
        else
            $ts_url
        fi
    done

    if [ "$check" = "200" -a "$ts_url" != "" ]; then
        curl $ts_url -o teamspeak3-server.tar.bz2
        tar -xjf teamspeak3-server.tar.bz2
        rm teamspeak3-server.tar.bz2
        if [ "$os_typ" = "x86_64" ]; then
            mv teamspeak3-server_linux_amd64 /home/user-webi/teamspeak3
        else
            mv teamspeak3-server_linux_x86 /home/user-webi/teamspeak3
        fi    
    fi
    
    if [ -f /home/user-webi/teamspeak3/ts3server_startscript.sh ]; then
        if [ "$os_typ" = "x86_64" ]; then
            tar -xzf teamspeak3-server_linux-x86-64.tar.gz
            mv teamspeak3-server_linux-amd64 /home/user-webi/teamspeak3
        else
            tar -xzf teamspeak3-server_linux-x86.tar.gz
            mv teamspeak3-server_linux-x86 /home/user-webi/teamspeak3
        fi
    fi
    
    chown -R user-webi:users /home/user-webi/teamspeak3
    cd /home/user-webi/teamspeak3
    su user-webi -c "touch .ts3server_license_accepted"
    su user-webi -c "./ts3server_startscript.sh start serveradmin_password=$adminpwd create_default_virtualserver=0 createinifile=1 inifile=ts3server.ini > tsout.txt"
    clear
    if [ "$langsel" = "1" ]; then
        echo "Teamspeak wird jetzt konfiguriert."
    else
        echo "Teamspeak will now be configured."
    fi
    loading 25
    su user-webi -c "./ts3server_startscript.sh stop"
    cat tsout.txt | grep -i "token=" | awk '{print $1}' > /home/tekbase_ts3.txt

    su user-webi -c "touch query_ip_blacklist.txt query_ip_whitelist.txt"
    echo "127.0.0.1" >> query_ip_whitelist.txt
    echo "$local_ip" >> query_ip_whitelist.txt
    echo "machine_id=" >> ts3server.ini
    echo "default_voice_port=9987" >> ts3server.ini
    echo "voice_ip=0.0.0.0" >> ts3server.ini
    echo "licensepath=" >> ts3server.ini
    echo "filetransfer_port=30033" >> ts3server.ini
    echo "filetransfer_ip=0.0.0.0" >> ts3server.ini
    echo "query_port=10011" >> ts3server.ini
    echo "query_ip=0.0.0.0" >> ts3server.ini
    echo "query_ip_whitelist=query_ip_whitelist.txt" >> ts3server.ini
    echo "query_ip_blacklist=query_ip_blacklist.txt" >> ts3server.ini
    echo "dbplugin=ts3db_sqlite3" >> ts3server.ini
    echo "dbpluginparameter=" >> ts3server.ini
    echo "dbsqlpath=sql/" >> ts3server.ini
    echo "dbsqlcreatepath=create_sqlite/" >> ts3server.ini
    echo "dbconnections=10" >> ts3server.ini
    echo "logpath=logs" >> ts3server.ini
    echo "logquerycommands=0" >> ts3server.ini
    echo "dbclientkeepdays=30" >> ts3server.ini
    echo "logappend=0" >> ts3server.ini
    echo "query_skipbruteforcecheck=0" >> ts3server.ini
    echo "create_default_virtualserver=0" >> ts3server.ini    
    su user-webi -c "./ts3server_startscript.sh start inifile=ts3server.ini"

    echo "Admin Login: serveradmin" >> /home/tekbase_ts3.txt
    echo "Admin Password: $adminpwd" >> /home/tekbase_ts3.txt
fi


##############################
# Install Linux Daemon       #
##############################
if [ "$modsel" = "1" ] || [ "$modsel" = "2" ] || [ "$modsel" = "4" ] || [ "$modsel" = "5" ] || [ "$modsel" = "8" ] || [ "$modsel" = "9" ]; then
    cd /home/skripte
    daemonpwd=$(gen_passwd 8)
    daemonport=1500
    sed -i '/password*/c\password = '$daemonpwd'' tekbase.cfg
    sed -i '/listen_port*/c\listen_port = '$daemonport'' tekbase.cfg
    portcheck=1
    while [ "$portcheck" != "" ]; do
        daemonport=$((daemonport+1))
        
        if [ "$netstat_inst" = "1" ]; then
            portcheck=$(netstat -tlpn | grep ":$daemonport ")
        else
    	    portcheck=$(ss -tlpn | grep ":$daemonport ")
        fi
        if [ "$portcheck" = "" ]; then
            sed -i '/listen_port*/c\listen_port = '$daemonport'' tekbase.cfg
        fi
    done
    echo "Daemon Port: $daemonport" > /home/tekbase_daemon.txt
    echo "Daemon Password: $daemonpwd" >> /home/tekbase_daemon.txt
fi


##############################
# Configure WWW              #
##############################
if [ $modsel -lt 7 ]; then
    wwwok=0
    site_url=$host_name
    
    if [ -d /home/www/web0/html ]; then
        wwwpath="/var/www/web0/html"
        wwwok=1
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /home/www/confixx ]; then
            wwwpath="/home/www/confixx/html"
            wwwok=1
        fi
    fi

    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www/vhosts/$site_url/httpdocs ]; then
    	    wwwpath="/var/www/vhosts/$site_url/httpdocs"
    	    wwwok=1
        fi
    fi

    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www/vhosts/default/htdocs ]; then
            wwwpath="/var/www/vhosts/default/htdocs"
            wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www/virtual/default ]; then
    	    wwwpath="/var/www/virtual/default"
    	    wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www/web0/html ]; then
    	    wwwpath="/var/www/web0/html"
            wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www/confixx/html ]; then
    	    wwwpath="/var/www/confixx/html"
    	    wwwok=1
        fi
    fi

    if [ "$wwwok" = "0" ]; then
        if [ -d /srv/www/vhosts/$site_url/httpdocs ]; then
    	    wwwpath="/srv/www/vhosts/$site_url/httpdocs"
    	    wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /srv/www/vhosts/default/htdocs ]; then
    	    wwwpath="/srv/www/vhosts/default/htdocs"
    	    wwwok=1
        fi
    fi

    if [ "$wwwok" = "0" ]; then
        if [ -d /srv/www/virtual/default ]; then
    	    wwwpath="/srv/www/virtual/default"
    	    wwwok=1
        fi
    fi

    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www/htdocs ]; then
    	    wwwpath="/var/www/htdocs"
    	    wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /srv/www/web0/html ]; then
    	    wwwpath="/srv/www/web0/html"
    	    wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /srv/www/confixx/html ]; then
    	    wwwpath="/srv/www/confixx/html"
    	    wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /srv/www/htdocs ]; then
            wwwpath="/srv/www/htdocs"
            wwwok=1
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ -d /srv/www ]; then
    	    wwwpath="/srv/www"
    	    wwwok=1
    	    if [ "$local_ip" != "" ]; then
    	        site_url=$local_ip
    	    fi
        fi
    fi

    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www/html ]; then
    	    wwwpath="/var/www/html"
    	    wwwok=1
    	    if [ "$local_ip" != "" ]; then
    	        site_url=$local_ip
    	    fi
        fi
    fi

    if [ "$wwwok" = "0" ]; then
        if [ -d /var/www ]; then
    	    wwwpath="/var/www"
    	    wwwok=1
    	    if [ "$local_ip" != "" ]; then
    	        site_url=$local_ip
    	    fi
        fi
    fi
    
    if [ "$wwwok" = "0" ]; then
        if [ "$os_install" = "1" ]; then
    	    mkdir /srv/www
    	    wwwpath="/srv/www"
        else
    	    mkdir /var/www
    	    wwwpath="/var/www"
        fi
    	if [ "$local_ip" != "" ]; then
    	    site_url=$local_ip
    	fi
    fi
    
    chk_panel
    if [ "$web_panel" = "Plesk" -a -d /var/www/vhosts ]; then
        select_url "/var/www/vhosts"
        wwwpath="/var/www/vhosts/$site_url/httpdocs"
    fi
fi


##############################
# Plesk                      #
##############################
if [ $modsel -lt 7 ]; then
    if [ "$web_panel" = "Plesk" -a -d /var/www/vhosts ]; then
        if [ "$os_install" = "2" ]; then
            for i in libgeoip-dev geoip-bin geoip-database libssh2-1-dev; do
                apt-get install $i $chkyes
            done
        fi

        cd /opt/plesk/php
        for phpd in $(find * -maxdepth 0 -type d)
        do
            if [ "$(grep -E '^([0-9].[0-9])$' <<< $phpd)" != "" ]; then
                phpv=${phpd//.}
                if [ "$phpv" = "56" ]; then
                    if [ -d /opt/plesk/php/${phpd}/bin ]; then
                        for i in plesk-php${phpv}-dev plesk-php${phpv}-gd plesk-php${phpv}-mbstring plesk-php${phpv}-mcrypt plesk-php${phpv}-mysql plesk-php${phpv}-xml; do
                            apt-get install $i $chkyes
                        done
                        /opt/plesk/php/${phpd}/bin/pecl install https://pecl.php.net/get/ssh2-0.13.tgz
                        if [ -f /opt/plesk/php/${phpd}/lib/php/modules/ssh2.so ]; then
                            echo "extension=ssh2.so" > /opt/plesk/php/${phpd}/etc/php.d/ssh2.ini
                        fi
                        /opt/plesk/php/${phpd}/bin/pecl install http://pecl.php.net/get/geoip-1.1.1.tgz
                         if [ -f /opt/plesk/php/${phpd}/lib/php/modules/geoip.so ]; then
                            echo "extension=geoip.so" > /opt/plesk/php/${phpd}/etc/php.d/ssh2.ini
                        fi
                        /etc/init.d/plesk-php${phpv}-fpm restart
                    fi    

                else
                    if [ -d /opt/plesk/php/${phpd}/bin ]; then
                        for i in plesk-php${phpv}-dev plesk-php${phpv}-gd plesk-php${phpv}-mbstring plesk-php${phpv}-mysql plesk-php${phpv}-xml; do
                            apt-get install $i $chkyes
                        done
                        /opt/plesk/php/${phpd}/bin/pecl install https://pecl.php.net/get/ssh2-1.1.2.tgz
                        if [ -f /opt/plesk/php/${phpd}/lib/php/modules/ssh2.so ]; then
                            echo "extension=ssh2.so" > /opt/plesk/php/${phpd}/etc/php.d/ssh2.ini
                        fi
                        /opt/plesk/php/${phpd}/bin/pecl install http://pecl.php.net/get/geoip-1.1.1.tgz
                        if [ -f /opt/plesk/php/${phpd}/lib/php/modules/geoip.so ]; then
                            echo "extension=geoip.so" > /opt/plesk/php/${phpd}/etc/php.d/ssh2.ini
                        fi
                        /etc/init.d/plesk-php${phpv}-fpm restart
                    fi
                fi
            fi
        done
    fi
fi


##############################
# Install TekBASE            #
##############################
if [ $modsel -lt 7 ]; then
    cd $installhome

    if [ "$php_version" = "5.6" ] || [ "$php_version" = "7.0" ]; then
        wget --no-check-certificate https://teklab.s3.amazonaws.com/tekbase.zip
    else
        wget --no-check-certificate https://teklab.s3.amazonaws.com/tekbase_php56.zip    
    fi
    unzip tekbase.zip
    rm tekbase.zip

    mv tekbase $wwwpath
    tekpwd=$(gen_passwd 8)
    tekdb=$(gen_passwd 4)

    if [ "$os_install" = "2" ]; then
    	mysqlpwd=$(cat /etc/mysql/debian.cnf | grep -i password | awk 'NR == 1 {print $3}')
        mysqlusr=$(cat /etc/mysql/debian.cnf | grep -i user | awk 'NR == 1 {print $3}')
    else
        clear
        mysqlusr="root"
        if [ "$mysqlpwd" = "" ]; then
    	    if [ "$langsel" = "1" ]; then
                echo "Bitte geben Sie das MySQL Root Passwort an, dies wurde Ihnen von"
                echo "Ihrem Serveranbieter bereits genannt (Root Passwort vielleicht)."
                echo ""
                echo -n "Passwort: "
            else
                echo "Please input the MySQL Root password. You get this from from"
                echo "your server provider (in example Root password)."
                echo ""
                echo -n "Password: "
            fi      
            read mysqlpwd
        fi
    fi

    Q1="CREATE DATABASE IF NOT EXISTS tekbase_$tekdb;"
    Q2="GRANT ALL PRIVILEGES ON tekbase_$tekdb.* TO 'tekbase_$tekdb'@'localhost' IDENTIFIED BY '$tekpwd' WITH GRANT OPTION;"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"

    mysql --user=$mysqlusr --password=$mysqlpwd -e "$SQL"
    mysql --user=tekbase_$tekdb --password=$tekpwd tekbase_$tekdb < $wwwpath/tekbase/install/database.sql

    rm -r $wwwpath/tekbase/install

    echo "<?php" > $wwwpath/tekbase/config.php
    echo "\$dbhost = \"localhost\";" >> $wwwpath/tekbase/config.php
    echo "\$dbuname = \"tekbase_$tekdb\";" >> $wwwpath/tekbase/config.php
    echo "\$dbpass = \"$tekpwd\";" >> $wwwpath/tekbase/config.php
    echo "\$dbname = \"tekbase_$tekdb\";" >> $wwwpath/tekbase/config.php
    echo "\$prefix = \"teklab\";" >> $wwwpath/tekbase/config.php
    echo "\$dbtype = \"mysqli\";" >> $wwwpath/tekbase/config.php
    echo "\$sitekey = \"$tekpwd\";" >> $wwwpath/tekbase/config.php
    echo "\$gfx_chk = \"1\";" >> $wwwpath/tekbase/config.php
    echo "\$ipv6 = \"1\";" >> $wwwpath/tekbase/config.php
    echo "\$shopcodes = \"00000\";" >> $wwwpath/tekbase/config.php
    echo "\$max_logins = \"7\";" >> $wwwpath/tekbase/config.php
    echo "\$awidgetone = \"Members,group,members_all.php, ,3\";" >> $wwwpath/tekbase/config.php
    echo "\$awidgetwo = \"TekLab News,news,teklab_rss_all.php, ,2\";" >> $wwwpath/tekbase/config.php
    echo "\$awidgetthree = \"Admins,administrator,admins_all.php, ,1\";" >> $wwwpath/tekbase/config.php
    echo "// FTP Login: tekbaseftp, FTP Passwort: $tekpwd" >> $wwwpath/tekbase/config.php
    echo "?>" >> $wwwpath/tekbase/config.php
    
    chmod 0777 $wwwpath/tekbase/cache
    chmod 0777 $wwwpath/tekbase/pdf
    chmod 0777 $wwwpath/tekbase/resources
    chmod 0777 $wwwpath/tekbase/tmp

    useradd -g users -p $(perl -e 'print crypt("'$tekpwd'","Sa")') -s /bin/bash -m tekbaseftp -d $wwwpath/tekbase
    chown -R tekbaseftp:users $wwwpath/tekbase

    echo "DB Login: tekbase_$tekdb" > /home/tekbase_db.txt
    echo "DB Password: $tekpwd" >> /home/tekbase_db.txt
    echo "FTP Login: tekbaseftp" > /home/tekbase_ftp.txt
    echo "FTP Password: $tekpwd" >> /home/tekbase_ftp.txt

    sleep 5
    wget -q -O - http://$site_url/tekbase/admin.php
else
    cd $installhome
    rm -r tekbase
fi
wget -q --post-data "op=insert&$site_url" -O - http://licenses1.tekbase.de/wiauthorized.php


##############################
# DB Inserts                 #
##############################
if [ "$local_ip" != "" ]; then
    if [ "$netstat_inst" = "1" ]; then
        ssh_port=$(netstat -tlpn | grep -e 'ssh' | awk -F ":" '{print $2}' | awk '{print $1}')
    else
        ssh_port=$(ss -tlpn | grep -e 'ssh' | awk -F ":" '{print $2}' | awk '{print $1}')
    fi
    if [ "$ssh_port" = "" ]; then
        ssh_port=22
    fi
    mysql --user=tekbase_$tekdb --password=$tekpwd tekbase_$tekdb << EOF
    INSERT INTO teklab_rootserver (id, sshdaemon, daemonpasswd, path, sshuser, sshport, name, serverip, loadindex, apps, games, streams, voices, vserver, web, cpucores, active) VALUES (NULL, "0", "$daemonpwd", "/home/skripte", "user-webi", "$ssh_port", "$local_ip", "$local_ip", "500", "1", "1", "1", "1", "1", "1", "$cpu_threads", "1");
    INSERT INTO teklab_teamspeak (id, serverip, queryport, admin, passwd, path, typ, rserverid) VALUES (NULL, "$local_ip", "10011", "serveradmin", "$adminpwd", "teamspeak3", "Teamspeak3", "1");
EOF
fi


##############################
# Finish                     #
##############################
cd $installhome
cd /usr/local
rm ioncube_x86-64.tar.gz
rm ioncube_x86.tar.gz
clear
if [ $modsel -lt 8 ]; then
    if [ "$langsel" = "1" ]; then
        echo "TekBASE wurde installiert. Sie können TekBASE über folgenden"
        echo "Browser Link aufrufen: http://$site_url/tekbase/admin.php"
        echo "Zwecks Freischaltung der Miet/Kaufversion diesen Link an"
        echo "service@teklab.de senden. Die Lite Version koennen Sie selbst"
        echo "im Kundenbereich freischalten."
        echo ""
        echo "Bei Plesk am besten unter Hosting Einstellungen die PHP Version"
        echo "auf 'X.X.XX (Vendor)' stellen bzw. PHP als 'Apache Modul' ausfuehren."
        echo "Dies ist nötig da ansonsten geoip und ioncube sowie ssh2 für die"
        echo "jeweilige PHP Version nachträglich kompiliert werden müssten."
        echo ""
        echo "Sollte TekBASE nicht aufrufbar sein, so schreiben Sie uns an"
        echo "Miet/Kaufversionen erhalten einen KOSTENLOSEN Installationssupport."
    else
        echo "TekBASE was installed. You can open TekBASE with this browser"
        echo "Link: http://$site_url/tekbase/admin.php"
        echo "Please send us an email with this link to service@teklab.de."
        echo "The Lite version can activated by yourself on our customer panel."
        echo ""
        echo "Is your TekBASE not available, please write us."
        echo "Rental/Buy versions get a FREE installation support."
    fi
    echo ""
fi

if [ "$modsel" = "1" ] || [ "$modsel" = "4" ] || [ "$modsel" = "8" ]; then
    if [ "$langsel" = "1" ]; then
        echo "Der Teamspeak 3 Grundserver wurde installiert. Das Serveradmin"
        echo "Passwort finden Sie in /home/tekbase_ts3.txt"
    else
        echo "The Teamspeak 3 server was installed. You will find the"
        echo "Serveradmin password in /home/tekbase_ts3.txt"
    fi
    echo ""
fi

if [ "$modsel" = "1" ] || [ "$modsel" = "2" ] || [ "$modsel" = "4" ] || [ "$modsel" = "5" ] || [ "$modsel" = "8" ] || [ "$modsel" = "9" ]; then
    if [ "$langsel" = "1" ]; then
        echo "Der Rootserver wurde komplett eingerichtet. Die Linux Daemon"
        echo "Zugangsdaten stehen in der /home/tekbase_daemon.txt Datei."
        echo "Der Linux Daemon benoetigt kein SSH und arbeitet auch deutlich"
        echo "schneller. Um den Linux Daemon zu starten bitte folgendes"
        echo "ausfuehren:"
        echo "su user-webi"
        echo "cd /home/skripte"
        echo "screen -A -m -d -S tekbasedaemon ./server"
    else
        echo "The root server has been completely set up. The linux daemon"
        echo "credentials are in the file /home/tekbase_daemon.txt."
        echo "The linux daemon does not require SSH and works much faster."
        echo "To start the linux daemon please run the following:"
        echo "su user-webi"
        echo "cd /home/skripte"
        echo "screen -A -m -d -S tekbasedaemon ./server"
    fi
    echo ""
fi

if [ "$os_install" = "2" ]; then
    export DEBIAN_FRONTEND=dialog
fi

exit 0
