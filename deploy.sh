#!/usr/bin/env bash 

# Defining some colors
RED='\033[0;31m'
RST='\033[0m'
CYA='\033[0;36m'
BLK='\033[5m'
YEL='\033[0;33m'
GRN='\033[0;32m'
IMP='\033[0;1;46;30m'


# Default variable
mode="auto"

# Checking for variable parameters
for opt in $@
do
	if [[ $opt =~ ^--([a-z]+)=([a-zA-Z0-9.-]+)$ ]]
	then
		declare "${BASH_REMATCH[1]}"=${BASH_REMATCH[2]}
	else
		echo -e "\033[31mCannot parse argument \033[30;41m $opt \033[0"
	fi
done

# Checking for mode variable
if [ -n "$mode" -a "$mode" != "auto" -a "$mode" != "force" -a "$mode" != "no" ]; then
	echo -e "${RED}Ambigous mode. Accepted values are [auto,force,no]"
	echo -e "${RST}Proceeding as normal mode."
fi

# Checking if Git has been initiated
if [ ! -d ./.git ]; then
	echo -e "${RED}.git directory not found. Ensure your working directory has been initiated."
	exit 1
fi 

# Checkin if artisan command exists
php artisan > /dev/null
if [ $? -gt 0 ]; then
	echo -e "${RED}Couldn't find artisan command. Ensure your working directory is a Laravel project."
	exit 1
fi

# Begin
echo ""
echo -e "${CYA}#################################################################"
echo -e "##################### ${YEL}${BLK}LARAVEL APP DEPLOYMENT${CYA} ####################"
echo -e "#################################################################${RST}"
echo ""

# Activating maintenance mode
echo -e "${IMP}[ MAINTENANCE MODE ]${RST}"
php artisan down
echo ""

# Giving permissions to current user
echo -e "${IMP}[ PERMISSIONS ]${RST}"
sudo chown -R $USER:$USER ./
if [ $? -gt 0 ]; then
	echo -e "${RED}An error has occured.${RST}"
	exit 1
else
	echo -e "${GRN}Permissions set to $USER.${RST}"
fi
echo ""

# git agent
echo -e "${IMP}[ GIT ]${RST}"
if [ "$(ssh-add -l)" = "The agent has no identities." ]; then
	ssh-add ~/.ssh/id_ed25519
fi

# Reseting git
git reset --hard
if [ $? -gt 0 ]; then
	echo -e "${RED}An error has occured."
	exit 1
fi
echo ""

# Pulling from git repo
if [ -n $branch ]; then
	#git fetch origin
	#git checkout -t origin/$branch
	git checkout $branch
fi

git pull

if [ $? -gt 0 ]; then
	echo -e "${RED}An error has occured."
	exit 1
else
	echo -e "${GRN}Done!${RST}"
fi
echo ""

# Installing PHP dependencies
echo -e "${IMP}[ COMPOSER ]${RST}"
if [ "$mode" = "auto" -o "$mode" = "no" ]; then
	echo -e "${YEL}Skipping PHP dependencies installation (Auto mode).${RST}"
	echo ""
elif [ "$mode" = "force" ]; then
	echo -e "${GRN}Installing PHP dependencies (Force mode).${RST}"
	composer install
	if [ $? -gt 0 ]; then
		echo -e "${RED}An error has occured."
		exit 1
	fi
else
	while true; do
		read -p "Would you like to install PHP dependancies ? [Y/n] " ans
		case $ans in
			[Yy]* ) echo -e "${GRN}Installing PHP dependencies.${RST}"
					composer install
					if [ $? -gt 0 ]; then
						echo -e "${RED}An error has occured."
						exit 1
					fi
					echo ""
					break;;
			[Nn]* ) echo -e "${YEL}Skipping PHP dependencies installation.${RST}"; echo ""; break;;
			* ) echo -e "Please answer ${GRN}Yes${RST} or ${RED}No${RST}."
		esac
	done
fi

# Installing NPM dependencies
echo -e "${IMP}[ NPM ]${RST}"
if [ "$mode" = "auto" -o "$mode" = "no" ]; then
	echo -e "${YEL}Skipping Node.js dependencies installation (Auto mode).${RST}"
	echo ""
elif [ "$mode" = "force" ]; then
	echo -e "${GRN}Installing Node.js dependencies (Force mode).${RST}"
	npm install
	if [ $? -gt 0 ]; then
		echo -e "${RED}An error has occured."
		exit 1
	fi
else
	while true; do
		read -p "Would you like to install Node.js dependancies ? [Y/n] " ans
		case $ans in
			[Yy]* ) echo -e "${GRN}Installing Node.js dependencies.${RST}"
					npm install
					if [ $? -gt 0 ]; then
						echo -e "${RED}An error has occured."
						exit 1
					fi
					echo ""
					break;;
			[Nn]* ) echo -e "${YEL}Skipping Node.js dependencies installation.${RST}"; echo ""; break;;
			* ) echo -e "Please answer ${GRN}Yes${RST} or ${RED}No${RST}."
		esac
	done
fi

# Running production script
echo -e "${IMP}[ PRODUCTION SCRIPT ]${RST}"
if [ "$mode" = "auto" -o "$mode" = "force" ]; then
	echo -e "${GRN}Running production script.${RST}"
	npm run prod
	if [ $? -gt 0 ]; then
		echo -e "${RED}An error has occured."
		exit 1
	fi
elif [ "$mode" != "no" ]; then
	while true; do
		read -p "Would you like to run production script ? [Y/n] " ans
		case $ans in
			[Yy]* ) echo -e "${GRN}Running production script.${RST}"
					npm run prod
					if [ $? -gt 0 ]; then
						echo -e "${RED}An error has occured."
						exit 1
					fi
					break;;
			[Nn]* ) echo -e "${YEL}Not running production script.${RST}"; break;;
			* ) echo -e "Please answer ${GRN}Yes${RST} or ${RED}No${RST}."
		esac
	done
else
	echo -e "${YEL}Not running production script.${RST}";
fi
echo ""

# Running Laravel migrations
echo -e "${IMP}[ MIGRATION ]${RST}"
if [ "$mode" = "auto" -o "$mode" = "force" ]; then
	php artisan migrate --force
elif [ "$mode" != "no" ]; then
	php artisan migrate
else
	echo -e "${YEL}Not running migrations.${RST}";
fi

echo ""

# Clearing Laravel cache
echo -e "${IMP}[ CACHE ]${RST}"
php artisan cache:clear
echo ""

# Clearing Laravel configs
echo -e "${IMP}[ CONFIGS ]${RST}"
php artisan config:cache
echo ""

#Clearing Laravel routes
echo -e "${IMP}[ ROUTES ]${RST}"
php artisan route:cache
echo ""

# Restoring initial permissions
echo -e "${IMP}[ PERMISSIONS ]${RST}"
sudo chown -R www-data:www-data ./
if [ $? -gt 0 ]; then
	echo -e "${RED}An error has occured.${RST}"
	exit 1
else
	echo -e "${GRN}Permissions restored!${RST}"
fi
echo ""

# Exiting maintenance mode
echo -e "${IMP}[ MAINTENANCE MODE ]${RST}"
php artisan up
echo ""

# End
echo -e "${CYA}#################################################################"
echo -e "####################### ${GRN}DEPLOYMENT DONE!${CYA} ########################"
echo -e "#################################################################${RST}"
echo ""
