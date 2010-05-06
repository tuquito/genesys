#!/bin/sh
# (c) Mario Colque <mario@tuquito.org.ar>
# LICENSE: GPL
# Purpose: Generador de distros a partir de la base de ubuntu
# Depends: whiptail, gettext, sed, modconf

DIALOG=whiptail
USER=`whoami`
TITLE="Genesys 0.2"

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

gconf() {
	cd tmp/gconf/
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
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load nautilus-desktop.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load panel.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --load sound.gconf
	gconftool-2 --direct   --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults   --type string   --set /desktop/gnome/url-handlers/mailto/command "thunderbird %s"
	gconftool-2 --type string --set /apps/nautilus/preferences/background_color "#D6767D"
	gconftool-2 --type bool --set /apps/nautilus/preferences/background_set true

	#sudo -u gdm gconftool-2 -s /desktop/gnome/interface/gtk_theme --type string "bamboo-zen"
	#sudo -u gdm gconftool-2 -s /desktop/gnome/interface/icon_theme --type string "showtime"

	cd ..
}

clean() {
	#rm $SOURCESLIST".genesys"
	for pkg in `dpkg --list | grep "^rc" | awk '{print $2}'`; do
		dpkg -P $pkg;
	done
	aptitude keep-all
	apt-get autoremove
	apt-get clean
	aptitude unmarkauto ~M
	updatedb
}

installTuquitoBase() {
	echo "DISTRIB_ID=$ID" > /etc/lsb-release
	echo "DISTRIB_RELEASE=$RELEASE" >> /etc/lsb-release
	echo "DISTRIB_CODENAME=$CODENAME" >> /etc/lsb-release
	echo "DISTRIB_DESCRIPTION=\"$DESC\"" >> /etc/lsb-release

	# Instalando aplicaciones de Tuquito
	aptito -u $TBASE

	# Sobreescribiendo archivos del sistema
	if [ -d /etc/cups/ ]; then
		cp cups-pdf.conf /etc/cups/
		cp printers.conf /etc/cups/
	fi
	cp default.pa /etc/pulse/default.pa
	cp face /etc/skel/.face
	rm -rf /etc/skel/.bashrc
	rm -rf /root/.bashrc
	rm -rf /etc/bash.bashrc
	cp bashrc /etc/skel/.bashrc
	cp lsb-base-logging.sh /etc/lsb-base-logging.sh
	#sed "s/release/$RELEASE/" bash.bashrc > /etc/bash.bashrc
	#sed "s/idRel/$ID/" /etc/bash.bashrc > /etc/bash.bashrc2
	cp bash.bashrc /etc/bash.bashrc
	if [ "$DESK"  == "GNOME" ]; then
		cp guake.desktop /etc/xdg/autostart/
		#cp gnome-2.soundlist /etc/sound/events/gnome-2.soundlist
		gconf		
	fi;

	clean
	finish
	exit
}

desktop() {
	DESK2=$TMPDIR"desktop"
	$DIALOG --clear --title "Entorno de Escritorio" --backtitle "$TITLE" --radiolist "Seleccione el entorno de escritorio preferido:" 0 0 4 "GNOME" "" on "KDE" "" off "XFCE" "" off "LXDE" "" off 2> $DESK2
	DESK="`cat $DESK2`"
	case $DESK in
		GNOME)
			aptito -u $GBASE
		;;
		KDE)
			aptito $KBASE
	 	;;
		XFCE)
			aptito $XBASE
	 	;;
		LXDE)
			aptito $LBASE
	 	;;
	esac
	installTuquitoBase
}

description() {
	#Repositorios y apt
	RELBASE="`lsb_release -sc`"
	DIRSOURCES="/etc/apt/"
	SOURCESLIST=$DIRSOURCES"sources.list"
	cp $SOURCESLIST $SOURCESLIST".genesys"
	cp sources.list $SOURCESLIST
	add-apt-repository ppa:tualatrix/ppa
	add-apt-repository ppa:paquetes-tuquito/main
	add-apt-repository ppa:paquetes-tuquito/update
	wget -q -O- http://archive.getdeb.net/getdeb-archive.key | apt-key add -
	#add-apt-repository ppa:paquetes-tuquito/unstable
	rm -f etc/apt/sources.list.d/paquetes-tuquito*
	cp preferences $DIRSOURCES"preferences"
	#cp apt.conf $DIRSOURCES"apt.conf"

	apt-get update

	DESC="$ID $RELEASE"
	echo $DESC > $TMPDIR"desc"
	$DIALOG --clear --title "Instalación" --backtitle "$TITLE" --yesno "Se va a instalar la base de la distro, por lo que necesita estar conectasdo a internet.\n\n¿Desea continuar?" 0 0
	if [ $? != 0 ]; then
		exit
	else
		aptito -u $BASE
	fi;
	desktop
}

codename() {
	CODENAME2=$TMPDIR"codename"
	$DIALOG --clear --title "Nombre clave" --backtitle "$TITLE" --radiolist "¿Que nombre clave va a tener su distro?" 0 0 4 "base32" "" on "base64" "" off "32bits" "" off "64bits" "" off "uni32" "" off "uni64" "" off 2> $CODENAME2
	CODENAME="`cat $CODENAME2`"
	if [ $? != 0 ]; then
		exit
	else
		description
	fi;
}

release() {
	RELEASE2=$TMPDIR"release"
	$DIALOG --clear --title "Versión" --backtitle "$TITLE" --inputbox "¿Que versión está por generar? (Ej. 3.1)" 0 0 "4.0" 2> $RELEASE2
	RELEASE="`cat $RELEASE2`"
	if [ $? != 0 ]; then
		exit
	else
		codename
	fi;
}

id() {
	ID2=$TMPDIR"id"
	$DIALOG --clear --title "Nombre" --backtitle "$TITLE" --inputbox "¿Que nombre va a tener la distro?" 0 0 "Tuquito" 2> $ID2
	ID="`cat $ID2`"
	if [ $? != 0 ]; then
		exit
	else
		release
	fi;
}

if [ "$USER" != "root" ]; then
	echo "Tiene que tener permisos de root para trabajar..."
else
	if [ ! -d $TMPDIR ]; then
		mkdir -p $TMPDIR
	fi;

	apt-get install whiptail axel

	sleep 1

	$DIALOG --clear --title "$TITLE" --yesno "Bienvenido a Genesys, la aplicación que le guiará en la contrucción de su versión de Tuquito.\n\nSolo tendrá que responder unas pocas preguntas de configuración.\n\n¿Desea continuar?" 0 0

	if [ $? != 0 ]; then
		exit
	else
		id
	fi;
fi;
