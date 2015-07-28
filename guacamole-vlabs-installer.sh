#!/bin/bash

# READ THIS FIRST!!!
#
# Before running this script make sure that:
#
# - This is an ubuntu server 14.04 and up.
# - The server can run apt-get install.
# - This file is an executable file.


#------------------------------------------------
# UPDATE THIS SECTION TO FIT YOUR INSTALLATION !!
#------------------------------------------------

# This section names different applications that will be downloaded by this script to support Guacamole and to
# allow its installation. Please change them to reflect the versions that you want, or the ones you already
# have, so that they are skipped when already found in the system.

# VARIABLES

GUACAMOLE_VERSION=0.9.7  # the Guacamole version to install
# a file with the list of dependencies for this version of Guacamole
DEPENDENCIES_LIST="guacamole-${GUACAMOLE_VERSION}-dependency-list.txt"
# the same, version of programs to install...
MAVEN=maven2
JDK=openjdk-7-jdk
TOMCAT=tomcat7


# Tomcat configuration file, already modified for Guacamole. If you already have Tomcat running and cannot
# overwrite your configuration file, change its value to zero by uncommenting the line below.
TOMCAT_SERVER_XML=server.xml
#TOMCAT_SERVER_XML=0   # uncomment this line to avoid overwriting server.xml


# guacamole installation file names 
WAR=.war
COMPRESSED=.tar.gz
GUACAMOLE_SERVER=guacamole-server-$GUACAMOLE_VERSION
GUACAMOLE_CLIENT=guacamole-client-$GUACAMOLE_VERSION
GUACAMOLE_SERVER_ARCHIVE=$GUACAMOLE_SERVER$COMPRESSED
GUACAMOLE_CLIENT_ARCHIVE=$GUACAMOLE_CLIENT$COMPRESSED
GUACAMOLE_WAR=guacamole-$GUACAMOLE_VERSION$WAR


# guacamole archive_download_locations
GUACAMOLE_SERVER_DOWNLOAD=http://sourceforge.net/projects/guacamole/files/current/source/$GUACAMOLE_SERVER_ARCHIVE
GUACAMOLE_CLIENT_DOWNLOAD=http://sourceforge.net/projects/guacamole/files/current/source/$GUACAMOLE_CLIENT_ARCHIVE


# destination for the compiled guacamole.war file
GUACAMOLE_WAR_DESTINATION=$(pwd)  # will save war file in current folder
# destination for tomcat's server.xml file
TOMCAT_SERVER_XML_FOLDER=/etc/$TOMCAT 
# destination for the 


# build location for the .jar plugin
GUACAMOLE_AUTH_URL_MAVEN_FOLDER=./guacamole-auth-url/
# the folder there the .jar plugin will be deposited
GUACAMOLE_AUTH_URL_BUILD_FOLDER="${GUACAMOLE_AUTH_URL_MAVEN_FOLDER}target/"
# the results of the build will be saved in the same place as the WAR



# abort on error
set -e
set -o pipefail



# welcome message
echo -e "\n\n"
echo -e "-------------------------------------------------------------------------------"
echo -e "Guacamole Installer Script:"
echo -e "This script installs Guacamole and its dependencies..."
echo -e ""
echo -e "The installer will install libraries and packages required for the server to"
echo -e "run properly. Check the names and versions below, and if you need to change"
echo -e "them, edit the VARIABLES section of this script."
echo -e "-------------------------------------------------------------------------------"
echo -e "Guacamole version: $GUACAMOLE_VERSION"
echo -e "Guacamole library dependencies list file: $DEPENDENCIES_LIST"
echo -e "Maven: $MAVEN"
echo -e "Java JDK: $JDK"
echo -e "Tomcat: $TOMCAT"
echo -e "Tomcat configuration file: $TOMCAT_SERVER_XML"
echo -e ""


# ask user to proceed if dependencies are OK
read -r -p "Do you want to continue with install? [y/n] " response
response=${response,,}
if [[ $response =~ ^(no|n) ]]; then
	echo -e "Quitting installer..."
	exit 0
fi



# first of all remove old guacamole directories and files
# and stop guacamole service.
if [ -f /etc/init.d/guacd ]; then
	/etc/init.d/guacd stop
fi
# files
rm -f /var/lib/$TOMCAT/webapps/guacamole.war
# directories
rm -drf /etc/guacamole/
rm -drf /usr/share/$TOMCAT/.guacamole/
rm -drf /var/lib/guacamole/




# install all software required for installing guacamole

# install Java JDK
echo -e "\n\nCheck for/install Java JDK."
sleep 2
apt-get install $JDK -y
# install Maven 2
echo -e "\n\nCheck for/install Maven."
sleep 2
apt-get install $MAVEN -y
# install Tomcat
echo -e "\n\nCheck for/install Tomcat."
sleep 2
if [ ! $TOMCAT == 0 ]; then
	apt-get install $TOMCAT -y
fi
# copy tomcat's server.xml file
cp -p $TOMCAT_SERVER_XML $TOMCAT_SERVER_XML_FOLDER
#install tar
echo -e "\n\nCheck for/install tar."
apt-get install tar -y
# install guacamole dependencies
echo -e "\n\nCheck for/install Guacamole dependencies."
cat $DEPENDENCIES_LIST | xargs  apt-get -y install



# start of installing process
echo -e "\n\nGuacamole install process starting..."




# install guacamole server
# if server archive not present, download it
if [ ! -f $GUACAMOLE_SERVER_ARCHIVE ]; then
	echo -e "downloging $GUACAMOLE_SERVER"
	sleep 1
	wget $GUACAMOLE_SERVER_DOWNLOAD
fi
echo -e "\n\nGuacamole server install starting..."
sleep 1
tar -xzf $GUACAMOLE_SERVER_ARCHIVE
cd $GUACAMOLE_SERVER
./configure --with-init-dir=/etc/init.d
make
make install
ldconfig
cd ..


# install client
echo -e "\n\nBuilding Guacamole web application..."
if [ ! -f $GUACAMOLE_CLIENT_ARCHIVE ]; then
	echo -e "downloading $GUACAMOLE_CLIENT"
	sleep 1
	wget $GUACAMOLE_CLIENT_DOWNLOAD
fi
tar -xzf $GUACAMOLE_CLIENT_ARCHIVE
cd $GUACAMOLE_CLIENT
mvn -DskipTests package
cd ..


# build the guacamole-auth-url pluggin .jar file
echo -e "\n\nBuilding the guacamole-auth-url plugin"
cd $GUACAMOLE_AUTH_URL_MAVEN_FOLDER
mvn -DskipTests package
cd ..


# extract web applications results
echo -e "\n\nThe Guacamole web application will be saved here: ${GUACAMOLE_WAR_DESTINATION}"
mkdir -p $GUACAMOLE_WAR_DESTINATION
cp $GUACAMOLE_CLIENT/guacamole/target/$GUACAMOLE_WAR $GUACAMOLE_WAR_DESTINATION


# extract plugin .jar results
echo -e "\n\nThe guacamole-auth-url .jar file will be saved here: ${GUACAMOLE_WAR_DESTINATION}"
cp "${GUACAMOLE_AUTH_URL_BUILD_FOLDER}guacamole-auth-url"*.jar $GUACAMOLE_WAR_DESTINATION


# delete folders used to build Guacamole
echo -e "\n\nCleanup - removing installation folders."
rm -drf $GUACAMOLE_SERVER
rm -drf $GUACAMOLE_CLIENT



# the end
echo -e "\n\nInstallation of Guacamole is complete."
