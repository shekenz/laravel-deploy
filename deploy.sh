#!/usr/bin/env sh 

# Defining some colors
RED='\033[0;31m'
RST='\033[0m'
CYA='\033[0;36m'
BLK='\033[5m'
YEL='\033[0;33m'
GRN='\033[0;32m'
IMP='\033[0;1;46;30m'

# Checking for parameter
if [ -n "$1" -a "$1" != "auto" -a "$1" != "force" -a "$1" != "no" ]; then
	echo "${RED}Ambigous argument $1. Proceeding as normal mode."
fi

# Checking if Git has been initiated
if [ ! -d ./.git ]; then
	echo "${RED}.git directory not found. Ensure your working directory has been initiated."
	exit 1
fi 

# Checkin if artisan command exists
php artisan > /dev/null
if [ $? -gt 0 ]; then
	echo "${RED}Couldn't find artisan command. Ensure your working directory is a Laravel project."
	exit 1
fi

echo ""
echo "${CYA}#################################################################"
echo "##################### ${YEL}${BLK}LARAVEL APP DEPLOYMENT${CYA} ####################"
echo "#################################################################${RST}"
echo ""

echo "${IMP}[ MAINTENANCE MODE ]${RST}"
php artisan down
echo ""

echo "${IMP}[ PERMISSIONS ]${RST}"
sudo chown -R $USER:$USER ./
if [ $? -gt 0 ]; then
	echo "${RED}An error has occured.${RST}"
	exit 1
else
	echo "${GRN}Permissions set to $USER.${RST}"
fi
echo ""

echo "${IMP}[ GIT ]${RST}"
if [ "$(ssh-add -l)" = "The agent has no identities." ]; then
	ssh-add ~/.ssh/id_ed25519
fi

git reset --hard
if [ $? -gt 0 ]; then
	echo "${RED}An error has occured."
	exit 1
fi
echo ""

git pull
if [ $? -gt 0 ]; then
	echo "${RED}An error has occured."
	exit 1
else
	echo "${GRN}Done!${RST}"
fi
echo ""

echo "${IMP}[ COMPOSER ]${RST}"
if [ "$1" = "auto" -o "$1" = "no" ]; then
	echo "${YEL}Skipping PHP dependencies installation (Auto mode).${RST}"
	echo ""
elif [ "$1" = "force" ]; then
	echo "${GRN}Installing PHP dependencies (Force mode).${RST}"
	composer install
	if [ $? -gt 0 ]; then
		echo "${RED}An error has occured."
		exit 1
	fi
else
	while true; do
		read -p "Would you like to install PHP dependancies ? [Y/n] " ans
		case $ans in
			[Yy]* ) echo "${GRN}Installing PHP dependencies.${RST}"
					composer install
					if [ $? -gt 0 ]; then
						echo "${RED}An error has occured."
						exit 1
					fi
					echo ""
					break;;
			[Nn]* ) echo "${YEL}Skipping PHP dependencies installation.${RST}"; echo ""; break;;
			* ) echo "Please answer ${GRN}Yes${RST} or ${RED}No${RST}."
		esac
	done
fi

echo "${IMP}[ NPM ]${RST}"
if [ "$1" = "auto" -o "$1" = "no" ]; then
	echo "${YEL}Skipping Node.js dependencies installation (Auto mode).${RST}"
	echo ""
elif [ "$1" = "force" ]; then
	echo "${GRN}Installing Node.js dependencies (Force mode).${RST}"
	npm install
	if [ $? -gt 0 ]; then
		echo "${RED}An error has occured."
		exit 1
	fi
else
	while true; do
		read -p "Would you like to install Node.js dependancies ? [Y/n] " ans
		case $ans in
			[Yy]* ) echo "${GRN}Installing Node.js dependencies.${RST}"
					npm install
					if [ $? -gt 0 ]; then
						echo "${RED}An error has occured."
						exit 1
					fi
					echo ""
					break;;
			[Nn]* ) echo "${YEL}Skipping Node.js dependencies installation.${RST}"; echo ""; break;;
			* ) echo "Please answer ${GRN}Yes${RST} or ${RED}No${RST}."
		esac
	done
fi

echo "${IMP}[ PRODUCTION SCRIPT ]${RST}"
if [ "$1" = "auto" -o "$1" = "force" ]; then
	echo "${GRN}Running production script.${RST}"
	npm run prod
	if [ $? -gt 0 ]; then
		echo "${RED}An error has occured."
		exit 1
	fi
elif [ "$1" != "no" ]; then
	while true; do
		read -p "Would you like to run production script ? [Y/n] " ans
		case $ans in
			[Yy]* ) echo "${GRN}Running production script.${RST}"
					npm run prod
					if [ $? -gt 0 ]; then
						echo "${RED}An error has occured."
						exit 1
					fi
					break;;
			[Nn]* ) echo "${YEL}Not running production script.${RST}"; break;;
			* ) echo "Please answer ${GRN}Yes${RST} or ${RED}No${RST}."
		esac
	done
else
	echo "${YEL}Not running production script.${RST}";
fi
echo ""

echo "${IMP}[ MIGRATION ]${RST}"
if [ "$1" = "auto" -o "$1" = "force" ]; then
	php artisan migrate --force
elif [ "$1" != "no" ]; then
	php artisan migrate
else
	echo "${YEL}Not running migrations.${RST}";
fi

echo ""

echo "${IMP}[ CACHE ]${RST}"
php artisan cache:clear
echo ""

echo "${IMP}[ CONFIGS ]${RST}"
php artisan config:cache
echo ""

echo "${IMP}[ ROUTES ]${RST}"
php artisan route:cache
echo ""

echo "${IMP}[ PERMISSIONS ]${RST}"
sudo chown -R www-data:www-data ./
if [ $? -gt 0 ]; then
	echo "${RED}An error has occured.${RST}"
	exit 1
else
	echo "${GRN}Permissions restored!${RST}"
fi
echo ""

echo "${IMP}[ MAINTENANCE MODE ]${RST}"
php artisan up
echo ""

echo "${CYA}#################################################################"
echo "####################### ${GRN}DEPLOYMENT DONE!${CYA} ########################"
echo "#################################################################${RST}"
echo ""
