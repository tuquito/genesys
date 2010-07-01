#!/bin/sh
# (c) Mario Colque <mario@tuquito.org.ar>
# LICENSE: GPL
# Purpose: Generador de distros a partir de la base de ubuntu
# Depends: whiptail, gettext, sed, modconf

DIALOG=whiptail
USER=`whoami`
TITLE="Genesys 0.4"

#Variables del sistema
ID="Tuquito"

DIR="/usr/share/genesys/"
TMPDIR=$DIR"tmp/"

BASE="`cat base.lst`"
GBASE="`cat base-gnome.lst`"
KBASE="`cat base-kde.lst`"
XBASE="`cat base-xfce.lst`"
LBASE="`cat base-lxde.lst`"
TBASE="`cat base-tuquito.lst`"

finish() {
	$DIALOG --clear --title "Finalizado" --backtitle "$TITLE" --yesno "$ID $RELEASE se ha generado correctamente!\n\nAhora puede reiniciar su pc para terminar de aplicar los cambios.\n\n¿Desea reiniciar su pc ahora?" 0 0

	if [ $? != 0 ]; then
		case $DESK in
			GNOME)
				/etc/init.d/gdm restart
			;;
			KDE)
				/etc/init.d/kdm restart
		 	;;
			XFCE)
				/etc/init.d/xxx restart
		 	;;
			LXDE)
				/etc/init.d/xxx restart
		 	;;
		esac
	else
		reboot
	fi;

}

clean() {
	apt-get --purge remove ubuntuone-client ubufox

	echo "DISTRIB_ID=$ID" > /etc/lsb-release
	echo "DISTRIB_RELEASE=$RELEASE" >> /etc/lsb-release
	echo "DISTRIB_CODENAME=$CODENAME" >> /etc/lsb-release
	echo "DISTRIB_DESCRIPTION=\"$DESC\"" >> /etc/lsb-release

	rm $SOURCESLIST".genesys"
	for pkg in `dpkg --list | grep "^rc" | awk '{print $2}'`; do
		dpkg -P $pkg;
	done

	aptitude keep-all
	apt-get autoremove
	apt-get clean
	aptitude unmarkauto ~M
	updatedb
	finish
}

gconf() {
	cd /usr/share/genesys/gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load background.gconf
	#gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load compiz.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load ctrl.gconf
	#gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load cursor.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load desktop-interface.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load gedit.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load gnome-terminal.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load guake.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load metacity.gconf
	#gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load mount-systray.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load nautilus-actions.gconf
	#gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load nautilus-desktop.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load nautilus.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load panel.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load sound.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --type string   --set /desktop/gnome/url-handlers/mailto/command "thunderbird %s"
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type bool --set /apps/totem/autoload_subtitles true
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type string --set /apps/metacity/general/button_layout "menu:minimize,maximize,close"
	#gconftool-2 --type string --set /apps/nautilus/preferences/background_color "#D6767D"
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type string --set /apps/nautilus/preferences/background_color "#CA3C46"
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type bool --set /apps/nautilus/preferences/background_set true
	cd ..
	clean
}

configGnome() {
	# Sobreescribiendo archivos del sistema
	#if [ -d /etc/cups/ ]; then
	#	cp cups-pdf.conf /etc/cups/
	#	cp printers.conf /etc/cups/
	#fi

	#Iconos
	cp icons/ubuntu-logo16.png /usr/share/icons/gnome/16x16/places/ubuntu-logo.png
	cp icons/ubuntu-logo22.png /usr/share/icons/gnome/22x22/places/ubuntu-logo.png
	cp icons/ubuntu-logo24.png /usr/share/icons/gnome/24x24/places/ubuntu-logo.png
	cp icons/ubuntu-logo32.png /usr/share/icons/gnome/32x32/places/ubuntu-logo.png
	cp icons/ubuntu-logosc.svg /usr/share/icons/gnome/scalable/places/ubuntu-logo.svg

	cp default.pa /etc/pulse/default.pa
	cp skel/face /etc/skel/.face
	cp -af skel/themes /etc/skel/.themes
	cp skel/gtkrc-2.0 /etc/skel/.gtkrc-2.0
	rm -rf /etc/skel/.bashrc
	rm -rf /root/.bashrc
	rm -rf /etc/bash.bashrc
	cp skel/bashrc /etc/skel/.bashrc
	cp lsb-base-logging.sh /etc/lsb-base-logging.sh
	cp bash.bashrc /etc/bash.bashrc
	cp guake.desktop /etc/xdg/autostart/
	cp applications.menu /etc/xdg/menus/
	cp gnome-2.soundlist /etc/sound/events/gnome-2.soundlist
	gconf
}

desktopBase() {
	apt-get install tuquito-gnome
	apt-get install tuquito-desktop-base
	configGnome
}

desktopMain() {
	apt-get install tuquito-gnome
	apt-get install tuquito-desktop-base
	configGnome
}

base32(){
	aptito -u tuquito-info-32
	desktopBase
}

main32(){
	aptito -u tuquito-info-32
	desktopMain
}

base64(){
	aptito -u tuquito-info-64
	desktopBase
}

main64(){
	aptito -u tuquito-info-64
	desktopMain
}

lxde(){
	aptito -u tuquito-info-lxde
	aptito -u tuquito-lxde
	aptito -u tuquito-desktop-lxde
}

repo() {
	#Repositorios y apt
	RELBASE="`lsb_release -sc`"
	DIRSOURCES="/etc/apt/"
	SOURCESLIST=$DIRSOURCES"sources.list"
	cp $SOURCESLIST $SOURCESLIST".genesys"
	cp /usr/share/genesys/repositorios/sources.list $SOURCESLIST
	cp /usr/share/genesys/repositorios/getdeb.list $SOURCESLIST".d/"
	cp /usr/share/genesys/repositorios/tualatrix-ppa-lucid.list $SOURCESLIST".d/"
	cp /usr/share/genesys/repositorios/elementaryart-elementarydesktop-lucid.list $SOURCESLIST".d/"
	if [ "$VERSION" != "lxde" ]; then
		cp /usr/share/genesys/repositorios/am-monkeyd-nautilus-elementary-ppa-lucid.list $SOURCESLIST".d/"
		#clave repo de nautilus-mods
		apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2E206FF0
	fi	
	#clave repo de tuquito
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5DBA3347
	#clave repo elementaryart
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com FC5D50C5
	#clave repo de ubuntu-tweak
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0624A220
	#clave repo getdeb
	wget -q -O- http://archive.getdeb.net/getdeb-archive.key | apt-key add -

	cp preferences $DIRSOURCES"preferences"
	apt-get update
	apt-get install tuquito-minimal

	cp po/terminal-es.mo /usr/share/tuquito/locale/es/LC_MESSAGES/terminal.mo
	cp po/terminal-pt.mo /usr/share/tuquito/locale/pt/LC_MESSAGES/terminal.mo

	`cat $VERSION2`
}

version() {
	VERSION2=$TMPDIR"version"
	$DIALOG --clear --title "Versión" --backtitle "$TITLE" --radiolist "¿Que versión va a ser su distro?" 0 0 4 "base32" "" on "base64" "" off "main32" "" off "main64" "" off "lxde" "" off 2> $VERSION2
	VERSION="`cat $VERSION2`"
	if [ $? != 0 ]; then
		exit
	else
		repo
	fi;
}

codename() {
	CODENAME2=$TMPDIR"codename"
	$DIALOG --clear --title "Nombre clave" --backtitle "$TITLE" --inputbox "¿Que nombre clave va a tener la distro? (Ej. toba)" 0 0 "toba" 2> $CODENAME2
	CODENAME="`cat $CODENAME2 | awk '{print tolower ($0)}'`"
	if [ $? != 0 ]; then
		exit
	else
		version
	fi;
}

release() {
	RELEASE2=$TMPDIR"release"
	$DIALOG --clear --title "Versión" --backtitle "$TITLE" --inputbox "¿Que versión está por generar? (Ej. 3.1)" 0 0 "4" 2> $RELEASE2
	RELEASE="`cat $RELEASE2`"
	if [ $? != 0 ]; then
		exit
	else
		codename
	fi;
}

if [ "$USER" != "root" ]; then
	echo "Tiene que tener permisos de root para trabajar..."
else
	if [ ! -d $TMPDIR ]; then
		mkdir -p $TMPDIR
	fi;
	
	cp aptito /usr/bin/aptito

	apt-get install whiptail axel add-apt-key

	$DIALOG --clear --title "$TITLE" --yesno "Bienvenido a Genesys, la aplicación que le guiará en la contrucción de su versión de Tuquito.\n\nSolo tendrá que responder unas pocas preguntas de configuración.\n\n¿Desea continuar?" 0 0

	if [ $? != 0 ]; then
		exit 0
	else
		release
	fi;
fi;
