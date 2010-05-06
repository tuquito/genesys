# This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#GNU General Public License for more details.
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#GSL - www.gsl.unt.edu.ar
#Tuquito GNU/linux - Garfio - www.tuquito.org.ar

#Variables para la instalacion
DISTRO="Tuquito GNU/linux"
DISTRO2="Instalación de Tuquito GNU/linux"
MOUNTPOINT=/mnt
SBIN=/garfio/bin
DHCP=""
MANUAL=""
TECLADO=""
USER=""
ROOTDIR=/garfio/
LOGDIR=/tmp
DIALOG=Xdialog
#

####FUNCIONES PARA LA INSTALACION########
conf_info()

{

$DIALOG --backtitle "$DISTRO2" --title "Instalación de $DISTRO" \
--yesno " Nótese que para instalar Tuquito en su computadora necesita
          crear una partición mínina de 2 gigas. " 0 0

if [  $? != 0 ]; then

exit

fi



}

add_cdrom_mountpoints() {

		if [ -f "/proc/sys/dev/cdrom/info" ] ; then
			cds=$(grep "^drive name:" /proc/sys/dev/cdrom/info)
			cds=${cds#drive\ name\:}
			num=0
			for i in $cds ; do
				if [ ${i%?} = 'sr' ]; then
					i="scd${i#sr}"
				fi
				add_cdrom $num /dev/${i}
				chmod 777 /mnt/dev/${i}
				let num=$num+1
			done
		fi
	}


add_cdrom() {
		NUM=$1
		DEV=$2
			echo "none  /media/cdrom${NUM}  supermount  dev=${DEV},fs=iso9660  0  0" >> /mnt/etc/fstab
			mkdir /mnt/media/cdrom${NUM} && mount /mnt/media/cdrom${NUM} 2> /tmp/addcdrom
	}


conf_error()

{

$DIALOG --backtitle "$DISTRO2"  --msgbox "Se produjo un error ,presione ENTER para volver al menu" 0 0


}


grubconfig()
{

# Variables
KERNEL=`uname -r`
KERNELMINOR=`uname -r | cut -d"." -f1,2`

. /garfio/libs/libouput.sh

# empieza el trabajo de localizar discos, particiones y sistemas
###########################################################
# empieza el trabajo de localizar discos, particiones y sistemas
for i in a b c d e f g
do
    DISCO=hd$i
    esta=`grep $DISCO /mnt/boot/grub/device.map | cut -c12-14`
    if [ -n "$esta" ]; then 
        fdisk -l /dev/$DISCO | grep ^/dev >> /tmp/salfdisk
    fi
done
# SCSI
for i in a b c d e f g
do
    DISCO=sd$i
    esta=`grep $DISCO /mnt/boot/grub/device.map | cut -c12-14`
    if [ -n "$esta" ]; then
        fdisk -l /dev/$DISCO | grep ^/dev >> /tmp/salfdisk
    fi
done
########################
# función para convertir las unidades y particiones en
# formato GRUB. uso: convierte tipo disco parte
TIPOL=""
DISCOL=""
PARTIL=""
convierte () {
# Ahora el nombre en formato GRUB
  DRIVE=$1$2
  NUMERO=`grep $DRIVE /mnt/boot/grub/device.map | cut -c2-4`
  let PART=$3-1
  NOMBRE="(${NUMERO},${PART})"
if [ "$1" = "sd" ]; then INFORME="SCSI"
	else INFORME="IDE"
fi
}
# fin de funcion
#
# lineas para la Distro
debug "Borramos antiguo menu.lst"
rm -f /mnt/boot/grub/menu.lst
SOS=1
echo "
timeout 8
default 0
fallback 1
" >> /mnt/boot/grub/menu.lst

# veamos Linux
TIPOL=`echo $1 | cut -c6-7`
DISCOL=`echo $1 | cut -c8-8`
PARTIL=`echo $1 | cut -c9-9`
convierte "$TIPOL" "$DISCOL" "$PARTIL"
nucleo=`ls /boot/ | grep vmlinuz | grep "$KERNEL$"`
initrd="/boot/initrd"
SPLASHON=$(grep -c on /proc/splash)
if [ $SPLASHON = 1 ]; then SPLASHPARAMS="splash=silent vga=791" ; else SPLASHPARAMS="" ; fi

if [ $KERNELMINOR = "2.4" ] ; then
	# Parametros scsi
	for i in /tmp/cdroms/* ; do
		DEV=`cat $i`
		PARAMS="$DEV=ide-scsi "
	done
fi

# Splashimage configuration in grub
cp /live/cdrom/boot/grub/Tuquito-grub.xpm.gz /mnt/boot/grub/
echo "splashimage=$NOMBRE/boot/grub/Tuquito-grub.xpm.gz" >> /mnt/boot/grub/menu.lst
cp /garfio/templates/bootsplash/initrd /mnt/boot/

echo "
title Linux ($DISTRO)
root $NOMBRE
kernel /boot/vmlinuz root=/dev/${TIPOL}${DISCOL}${PARTIL} ${SPLASHPARAMS} ${PARAMS}" >> /mnt/boot/grub/menu.lst
echo "initrd $initrd" >> /mnt/boot/grub/menu.lst

# Other grub boots

  echo "
title Linux ($DISTRO) no-splash
root $NOMBRE
kernel /boot/vmlinuz root=/dev/${TIPOL}${DISCOL}${PARTIL} ${PARAMS}" >> /mnt/boot/grub/menu.lst

# Rescue boot
echo "
title Linux ($DISTRO) rescue
root $NOMBRE
kernel /boot/vmlinuz root=/dev/${TIPOL}${DISCOL}${PARTIL} ${PARAMS} single" >> /mnt/boot/grub/menu.lst

#
# lineas de WIN
win () {
    let SOS=SOS+1
    echo "##########################
title $TITULO en Disco $INFORME $TIPOD$DISCO$PARTI $TIPOP
rootnoverify $NOMBRE
makeactive
chainloader +1 " >> /mnt/boot/grub/menu.lst
}
# fin de la función win

#
# otros sistemas operativos
otros_so () {
# uso: otros_so linea_de_fichero_dev/XXXX
# empezamos con los Win en FAT32
TIPOD=`cat $1 | grep FAT32 | cut -c6-7`
DISCO=`cat $1 | grep FAT32 | cut -c8-8`
PARTI=`cat $1 | grep FAT32 | cut -c9-9`
TIPOP=FAT32
if [ -z $DISCO ]; then
    :
else
		convierte "$TIPOD" "$DISCO" "$PARTI"
		mount -t vfat -o ro /dev/"$TIPOD""$DISCO""$PARTI" /mnt/mnt

		if [ $? -ne 0 ]; then
			# si falla el montaje ... por defecto windows (aunque no arranque pq no este formateada)
			TITULO="WINDOWS"
			win
		elif [ -f /mnt/mnt/boot.ini ]; then
			BUSCA=`cat /mnt/mnt/boot.ini | grep Windows | grep XP`
			if [ -z "$BUSCA" ]; then
				TITULO="WINDOWS 2000 "
				win
			else
				TITULO="WINDOWS XP "
				win
			fi
                else
                        if [ -f /mnt/mnt/autoexec.bat ]; then
				TITULO="WINDOWS 9X"
				win
                        fi
                fi
		umount /mnt/mnt
	fi
	# Win en NTFS
	#
	TIPOD=`cat $1 | grep NTFS | cut -c6-7`
	DISCO=`cat $1 | grep NTFS | cut -c8-8`
	PARTI=`cat $1 | grep NTFS | cut -c9-9`
	TIPOP=NTFS
	if [ -z $DISCO ]; then :
        else
		convierte "$TIPOD" "$DISCO" "$PARTI"
		mount -t ntfs-fuse /dev/"$TIPOD""$DISCO""$PARTI" /mnt/mnt
		if [ -f /mnt/mnt/boot.ini ]; then
			BUSCA=`cat /mnt/mnt/boot.ini | grep Windows | grep XP`
                        if [ -z "$BUSCA" ]; then
				TITULO="WINDOWS 2000 "
				win
                        else
				TITULO="WINDOWS XP "
				win
                        fi
                fi
		umount /mnt/mnt
fi
#
# otros linux
#
TIPOD=`cat $1 | grep Linux | grep 83 | cut -c6-7`
DISCO=`cat $1 | grep Linux | grep 83 | cut -c8-8`
PARTI=`cat $1 | grep Linux | grep 83 | cut -c9-9`
if [ -z $DISCO ]; then :
else
	debug "Encontradas particiones Linux"
	TMPMOUNT=/mnt/mnt
	convierte "$TIPOD" "$DISCO" "$PARTI"
	mount -t auto -o ro /dev/"$TIPOD""$DISCO""$PARTI" $TMPMOUNT
	if [ -d $TMPMOUNT/boot ]; then
		debug "Kernels encontrados:"
		ls $TMPMOUNT/boot | grep vmlinuz > /tmp/ficheros
        	wc -l /tmp/ficheros | cut -c7-7 > /tmp/filas
		nfilas=`wc -l /tmp/ficheros | cut -c1-2`

		#Lin: no sabemos para que se hizo esto
		#nfilas=`sed -n 1,1p  /tmp/filas | head --bytes=1`

		for i in `seq 1 $nfilas`;
		do
			sed -n "$i","$i"p /tmp/ficheros > /tmp/fila
			KERNEL=`cat /tmp/fila`
			NUMERACION=`cat /tmp/fila | cut -c8-22`
			if [ -f $TMPMOUNT/boot/initrd.img"$NUMERACION" ]; then
				LINEA2="initrd /boot/initrd.img"$NUMERACION""
			fi
			otrolinux
        	done
		fi
		umount $TMPMOUNT
	fi
}
#
otrolinux () {
	let SOS=SOS+1
	echo "
title Linux en Disco $INFORME "$TIPOD""$DISCO""$PARTI" Kernel"$NUMERACION"
root $NOMBRE
kernel /boot/$KERNEL root=/dev/"$TIPOD""$DISCO""$PARTI" vga=791
$LINEA2 " >> /mnt/boot/grub/menu.lst
}

#
############################################################3
# trabajo con salfdisk
wc /tmp/salfdisk | cut -c6-7 > /tmp/lineas
nlineas=`sed -n 1,1p  /tmp/lineas | head --bytes=2`
for i in `seq 1 $nlineas`;
do
        sed -n "$i","$i"p /tmp/salfdisk > /tmp/linea
        PRIMEROS=`cat /tmp/linea | head -c9`
        if [  "$PRIMEROS" = "/dev/"$TIPOL""$DISCOL""$PARTIL"" ]; then :
        else
            PRIMEROS=`cat /tmp/linea | head -c5`
            if [ "$PRIMEROS" = "/dev/" ]; then 
            	otros_so /tmp/linea
            fi
        fi
    done
if [ $SOS -gt 1 ]; then
	sed -e 's/timeout 1/timeout 12/g' /mnt/boot/grub/menu.lst > /tmp/menut.tmp
	mv -f /tmp/menut.tmp /mnt/boot/grub/menu.lst
fi
debug "SO encontrados: $SOS"
rm -f /tmp/salfdisk
rm -f /tmp/filas
rm -f /tmp/ficheros
rm -f /tmp/lineas
rm -f /tmp/linea
rm -f /tmp/fila


}




conf_idioma()
{
	IDIOMA=Y

	TEMPFILE="/tmp/menu"
	$DIALOG --backtitle "$DISTRO2" --title "Idioma / Language" --menu "" 0 0 5\
	  es "Selecciona esta opción para continuar Español"\
	  en "Choose this option to continue in english" 2>/tmp/menuitem.$$
	  
	MENUITEM=`cat /tmp/menuitem.$$`  
	case $MENUITEM in
		es) LANGUAGE="es";;
		en) LANGUAGE="en";;
  		*) LANGUAGE="es";;
	esac

case "$LANGUAGE" in
es)
# Spanish version
TCOUNTRY="es"
TLANG="es_ES@euro"
TKEYTABLE="es"
TXKEYBOARD="es"
TKDEKEYBOARD="es"
TCHARSET="iso8859-15"
TLC_ALL=es_ES
KDEKEYBOARDS="us,fr,de"
;;
*)
# US version
LANGUAGE="us"
TCOUNTRY="us"
TLANG="C"
TKEYTABLE="us"
TXKEYBOARD="us"
TKDEKEYBOARD="us"
TCHARSET="iso8859-1"
TLC_ALL=us_US
KDEKEYBOARDS="de,fr"
;;
esac

export LANGUAGE TLC_ALL

echo "export LANGUAGE=$LANGUAGE COUNTRY=$TCOUNTRY LANG=$TLANG LC_ALL=$TLC_ALL" >> /etc/profile


}



conf_teclado()

{


FILE=`dialog --stdout --title "elija un mapa de teclado.Seleccione con la barra espaciadora"  --fselect /usr/share/keymaps/i386/qwerty/ 14 65 `

case $? in
	0)

		loadkeys  $FILE
		
		$DIALOG --backtitle "$DISTRO2" --title "Configuración de teclado" --clear \
        --msgbox "El mapa de teclado fue cambiado a $FILE" 0 0

	;;

	1)

		continue;;
	255)
		continue;;
esac


	TECLADO=Y

}

conf_hostname()
{

	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG  --backtitle "$DISTRO2" --title "Configuración del Hostname"\
	  --inputbox "`gettext -s "Elija un nombre para el sistema. \n\
		¿Cuál será el nombre de su equipo?"`" 0 0 $HOSTNAME 2> $TEMPFILE
		
	HOSTNAME="$(cat $TEMPFILE)"

	rm -f $TEMPFILE 2> /dev/null


}

conf_user()
{
	TEMPFILE="/tmp/user"
	rm -f $TEMPFILE 2> /dev/null
	
	$DIALOG --backtitle "$DISTRO2" --title "Configuración de usuarios" \
	  --inputbox "`gettext -s "Elija nombre de usuario en el sistema. \n\
		¿Cuál será su nombre de Usuario?"`" 0 0 $USERNAME 2> $TEMPFILE
		
	USERNAME="$(cat $TEMPFILE)"
	
	# Password
	$DIALOG --backtitle "$DISTRO2" --title "Configuración de usuarios" \
	  --passwordbox "`gettext -s " Elija una clave para el usuario $USERNAME. \n\
		Escriba la clave del usuario $USERNAME"`" 0 0 2> $TEMPFILE
		
	UPASSWORD="$(cat $TEMPFILE)"
	
	STARTUSER="$USERNAME"

	# Limpiando
	rm -f $TEMPFILE 2> /dev/null

	USER=Y
    

}


conf_passroot()
{ 
	TEMPFILE="/tmp/root"
	$DIALOG --backtitle "$DISTRO2" --title "Configuración de root" \
	  --passwordbox "`gettext -s "Elija una clave para el Administrador (root). \n\
		Escriba la clave del usuario root"`" 0 0 2> $TEMPFILE
		
	RPASSWORD="$(cat $TEMPFILE)"

	# Limpiando
	rm -f $TEMPFILE 2> /dev/null

	

}

conf_red()
{


#devs=$(grep [0-9]: /proc/net/dev | tr -s '  ' ' ' | cut -d ' ' -f 2 | cut -d ':' -f 1)

#for eth in $devs;
#do

tempfile=/tmp/qred

$DIALOG --backtitle "$DISTRO2" --clear --title "Configuración de red" \
        --menu "elija una configuración para su placa de red:" 0 0 4 \
        "DHCP"  "Configura la red con DHCP" \
        "MANUAL" "Configura la red manualmente"  2> $tempfile

retval=$?

choice=`cat $tempfile`

case $retval in
  0)
if [ "$choice" = "DHCP" ]; then
    
	DHCP=Y
	MANUAL=N

fi

if [ "$choice" = "MANUAL" ]; then

	MANUAL=Y
	DHCP=N

	TEMPFILE="/tmp/redconfig"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2" --title "Configuración de red" \
	  --inputbox "`gettext -s "Ingrese el ip de la interface de red"`" 0 0 $IP 2> $TEMPFILE
		
	IP="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null

	TEMPFILE="/tmp/redconfig"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2"  --title "Configuración de red" \
	  --inputbox "`gettext -s "Ingrese la mascara de red "`" 0 0 $NETMASK 2> $TEMPFILE
		
	NETMASK="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null

	TEMPFILE="/tmp/redconfig"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2"  --title "Configuración de red" \
	  --inputbox "`gettext -s "Ingrese el broadcast "`" 0 0 $BROADCAST 2> $TEMPFILE
		
	BROADCAST="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null

#done
	TEMPFILE="/tmp/redconfig"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2"  --title "Configuración de red" \
	  --inputbox "`gettext -s "Ingrese la puerta de enlace, deje en blanco si no dispone "`" 0 0 $GATEWAY 2> $TEMPFILE
		
	GATEWAY="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null



	TEMPFILE="/tmp/redconfig"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2"  --title "Configuración de red" \
	  --inputbox "`gettext -s "Ingrese su servidor de DNS primario, deje en blanco si no dispone "`" 0 0 $DNS1 2> $TEMPFILE
		
	DNS1="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null



	TEMPFILE="/tmp/redconfig"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2"  --title "Configuración de red" \
	  --inputbox "`gettext -s "Ingrese su servidor de DNS secundario, deje en blanco si no dispone "`" 0 0 $DNS2 2> $TEMPFILE
		
	DNS2="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null





fi


  ;;
  1)
      menu_instalacion_manual;;
  255)
      menu_instalacion_manual;;
esac


}

conf_particionar()
{
#
# Presentation
#
conf_info
#
# Disks
#
# Tamaño de particiones: mind. 2.0 GB Filesystem, mind. 128 MB Swap.
FSMIN=2000
SWAPMIN=128
# Tamaño total del Sistema descomprimido
NCLOOPFSMIN=4400

# Tamaño del initrd: 2.5 MB
INSIZE=2500

# Auswahl der Platte zum Partitionieren
rm -f /tmp/partitions
TMP="/tmp/partitions"
NUMHD=0
if [ -f /proc/partitions ] ; then
  while read x x x p x
  do
    case "$p" in
      hd?)
        if [ "`cat /proc/ide/$p/media`" = "disk" ] ; then
          echo "$p `tr ' ' _ </proc/ide/$p/model`" >> $TMP
          NUMHD=$[NUMHD+1]
        fi
        ;;
      sd?)
        x="`scsi_info /dev/$p | grep MODEL | tr ' ' _`"
        x=${x#*\"}
        x=${x%\"*}
        echo "$p $x" >> $TMP
        NUMHD=$[NUMHD+1]
        ;;
      *) ;;
    esac
  done < /proc/partitions
fi
HARDDISKS="`cat $TMP`"

$DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" \
--radiolist "Seleccione un disco duro:" 0 0 $NUMHD \
  $(echo "$HARDDISKS" | while read p model ; do echo "$p" "$model" off ; done) 2> $TMP
  
HDCHOICE="`cat $TMP`"

if [ -z "$HDCHOICE" ] ; then
  $DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" --msgbox "No se ha seleccionado un disco duro." 0 0

  menu_instalacion_manual
fi




# Abrimos un treminal para ver logs
sbin/getty 38400 tty2  >> /tmp/getty.log 2>&1 &

# Desmontamos la SWAp para que se pueda cambiar la tabla de particiones
while [ -n "`swapon -s | grep dev`" ]; do
        sync
        swapoff -a >> /tmp/install.log 2>&1
done

$DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" \
--msgbox "Ha elegido el Disco duro /dev/$HDCHOICE. \
Ahora se arrancará la herramienta cfdisk \
de particionado." 0 0

cfdisk /dev/$HDCHOICE 2>> /tmp/install.log



}



conf_modulos2()

{
		PCIDB="/garfio/templates/hwdata/pci.lst"
		IDS=`cut -f 2 /proc/bus/pci/devices`
		MODULE=""
		for ID in $IDS ; do
			MODULE=`grep $ID $PCIDB 2> /tmp/hw.log | cut -f 2`
			
			if [ -n "$MODULE" ]; then

				echo $MODULE
			        modprobe $MODULE > /tmp/hw.log 2>&1 && echo $MODULE >> /tmp/modules
				ver_error

			if [ $(echo $MODULE | grep snd-) ]; then
				modprobe snd-mixer-oss >/tmp/hw.log 2>&1 && echo snd-mixer-oss  >> /tmp/modules
			
			    
			fi

		     fi
		done

}

conf_modulos()

{


NUMMOD=0


TMPMOD="/tmp/modules"
TMP=/tmp/modules.etc
MODS=""
i=""
modules=""

rm -rf $TMPMOD
rm -rf $TMP

cat <<EOF >$TMPMOD
# /etc/modules: kernel modules to load at boot time.
#
# This file should contain the names of kernel modules that are
# to be loaded at boot time, one per line.  Comments begin with
# a #, and everything on the line after them are ignored.

EOF
modules=`tail +1 /proc/modules | grep -v '\[.*\]' | grep -v loop | grep -v squashfs | cut -d " " -f 1`
for mod in $modules
do
	
	MODS="$MODS $mod"
	NUMMOD=$[NUMMOD+1]
	
done


$DIALOG --backtitle "$DISTRO2" --title "Configuración de Módulos" \
--checklist "Seleccione los módulos que desea agregar:" 0 0 $NUMMOD \
  $(for i in $MODS;	do echo $i $i off ; done) 2> $TMP
  
modules=`tail +1 /tmp/modules.etc | tr -d '"'`

if [ $? == 0 ]; then

    for mod in $modules
    do
	echo $mod >>$TMPMOD	

    done

fi


}



conf_activar()
{


rm -f /tmp/partitions
rm -f /tmp/mountpoint
rm -f /tmp/choisepartition

PARTITIONS=`/sbin/fdisk -l | awk '/^\/dev\// {if ($2 == "*"){if ($6 == "83") \
{ print $1 };} else {if ($5 == "83") { print $1 };}}'`


if [ -z "$PARTITIONS" ]; then
		$DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" \
		--msgbox "No se han detectado particiones compatibles con \
		GNU/linux. Tendrá a que volver a particionar su disco duro." 0 0

		menu_instalacion_manual
fi 


TEMPFILE=/tmp/mountpoint


TMP="/tmp/partition"
rm -f $TMP 2> /dev/null

NUMPART=0
for i in $PARTITIONS
	do 
	NUMPART=$[NUMPART+1]
done

$DIALOG --backtitle "$DISTRO2" --title "Active una partición" \
--radiolist "Seleccione la partición donde se instalará el sistema. (La barra espaciadora selecciona):" 0 0 $NUMPART \
  $(for i in $PARTITIONS;	do echo "$i" "$i" off ; done) 2> $TMP
  
PART="`cat $TMP`"

if [ ! -b "$PART" ]; then
	$DIALOG --backtitle "$DISTRO2
	" --title "Particionar el disco duro" \
		--msgbox "$PART no es una partición válida, presione ENTER para volver al menu" 0 0

	menu_instalacion_manual
else

echo $PART  > /tmp/choicepartition


fi

mount=$(grep $PART /etc/mtab | cut -d ' ' -f 2)

if [ "$mount" != "" ]; then

    umount $mount

fi


$DIALOG --backtitle "$DISTRO2" --title "Activar partición" \
  --yesno "`gettext -s "Se va a formatear $PART con el sistema de archivo ext3\
 para preparar la instalación. Se perderán todos los datos, desea continuar? "`" 0 0  2> $TEMPFILE


if [ $? == "0" ]; then

mkfs.ext3 $PART

if [ $? == "0" ]; then

mount -t ext3 $PART $MOUNTPOINT >> /tmp/mount.log 2>&1

if [ $? == "0" ]; then

FOK=Y
else

conf_error 

fi
  
else
conf_error
fi

else
menu_instalacion_manual
fi

if [ $? == "0" ]; then


$DIALOG --backtitle "$DISTRO2"  --title "Activar partición" --msgbox " Partición activada con éxito" 0 0



else

 $DIALOG --backtitle "$DISTRO2" --msgbox "No se pudo activar la partición $PART" 0 0
 menu_instalacion_manual
 
fi

}



conf_verify()
{

FSCHOICE=$PART
SWCHOICE=`/sbin/fdisk -l | awk '/^\/dev\// {if ($2 != "*") {if ($5 == "82") { print $1 }}}'`

# Funtions
LOGDIR="/tmp/"


if [ "$PART" == "" ]; then

$DIALOG --backtitle "$DISTRO2" --title "Importante" \
  --msgbox "`gettext -s "No hay una partición válida, presione ENTER para volver al menu"`" 0 0

	
		menu_instalacion_manual
fi



if [ ! -b $PART ]; then

$DIALOG --backtitle "$DISTRO2" --title "Importante" \
  --msgbox "`gettext -s "No hay una partición válida, presione ENTER para volver al menu"`" 0 0

		menu_instalacion_manual
		

fi


if [ "$FOK" != "Y" ]; then

$DIALOG --backtitle "$DISTRO2" \
  --msgbox "`gettext -s "No se activó y particionó la partición para la instalación, presione ENTER para volver al menu"`" 0 0


		menu_instalacion_manual


fi

INSTALAR=completa
instalacion_tuquito


}



conf_reniciar()
{

TECLADO=""
USER=""
DHCP="Y"
MANUAL=""
HOSTNAME="tuquito"
PART=""


}

conf_salir()
{

$DIALOG --title "Tuquito K GNU/linux"\
 --msgbox "Salió de la instalación, presione ENTER, el sistema se reiniciará" 0 0

umount $MOUNTPOINT
sync

reboot -f -d -i
exit
}

conf_presentacion()

{

$DIALOG --backtitle "$DISTRO2" --title "Instalación de $DISTRO" \
--msgbox " Nótese que Tuquito  esta todavia en \
desarrollo. El autor no toma ninguna responsabilidad \
en caso de perdida de datos o daño del hardware." 0 0


}


conf_teclado2()
{

KEYMAPS=`ls /usr/share/keymaps/i386/qwerty/ | cut -d "." -f 1`
COUNT=0

for n in $KEYMAPS;do

let COUNT=$COUNT+1


done

rm -f /tmp/teclado

TMP=/tmp/teclado

whiptail --backtitle "$DISTRO2" --clear  --title "Keymaps" \
--radiolist "Seleccione una configuración para el teclado" 0 0 $COUNT \
  $(for key in $KEYMAPS; do echo "$key" "$key" off; done) 2> $TMP
		
arch=`cat $TMP`


TECLADO=Y

loadkeys /usr/share/keymaps/i386/qwerty/$arch.kmap.gz
FILE="/usr/share/keymaps/i386/qwerty/$arch.kmap.gz"



}


conf_teclado_system()
{


	TEMPFILE="/tmp/menu"
	$DIALOG --backtitle "$DISTRO" --title "Idioma / Language / Hizkuntza" --menu "" 15 100 6\
	  es "Selecciona esta opcion para continuar Español"\
	  eu "Aukeratu hau Euskaraz jarraitzeko"\
	  en "Choose this option to continue in english" 2>/tmp/menuitem.$$
	  
	MENUITEM=`cat /tmp/menuitem.$$`  
	case $MENUITEM in
		es) LANGUAGE="es";;
		eu) LANGUAGE="eu";;
		en) LANGUAGE="en";;
  		*) LANGUAGE="es";;
	esac

        # Locales
        . /garfio/custom/lang.conf 2>> $LOGDIR/install.log
        # Set default keyboard before interactive setup
        [ -n "$KEYTABLE" ] && loadkeys -q $KEYTABLE 2>> $LOGDIR/install.log



}

conf_hostname_system()
{
	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO" \
	  --inputbox "`gettext -s "Elija un nombre para el sistema. \n\
		¿Cuál será el nombre de su equipo?"`" 12 50 $HOSTNAME 2> $TEMPFILE
		
	HOSTNAME="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null


}

conf_user_system()
{
	TEMPFILE="/tmp/user"
	rm -f $TEMPFILE 2> /dev/null
	# NAME
	$DIALOG --backtitle "$DISTRO" \
	  --inputbox "`gettext -s "Tanto si va a instalar, como si va a arrancar\n\
	  desde el CDROM, deberá elegir un nombre de usuario en el sistema. \n\
		¿Cuál será su nombre de Usuario?"`" 12 50 $USERNAME 2> $TEMPFILE
		
	USERNAME="$(cat $TEMPFILE)"
	
	# PASSWORD
	$DIALOG --backtitle "$DISTRO" \
	  --passwordbox "`gettext -s "Tanto si va a instalar, como si va a arrancar\n\
	  desde el CDROM, deberá elegir una clave para el usuario $USERNAME. \n\
		Escriba la clave del usuario $USERNAME"`" 12 50 2> $TEMPFILE
		
	UPASSWORD="$(cat $TEMPFILE)"
	
	STARTUSER="$USERNAME"

	# Limpiando
	rm -f $TEMPFILE 2> /dev/null


}


conf_passroot_system()
{ 
	TEMPFILE="/tmp/root"
	$DIALOG --backtitle "$DISTRO" \
	  --passwordbox "`gettext -s "Tanto si va a instalar, como si va a arrancar\n\
	  desde el CDROM, deberá elegir una clave para el Administrador (root). \n\
		Escriba la clave del usuario root"`" 12 50 2> $TEMPFILE
		
	RPASSWORD="$(cat $TEMPFILE)"

	# Limpiando
	rm -f $TEMPFILE 2> /dev/null



}

conf_red_system()
{

	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2" \
	  --inputbox "`gettext -s "Ingrese el ip "`" 0 0 $IP 2> $TEMPFILE
		
	IP="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null

	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2" \
	  --inputbox "`gettext -s "Ingrese la mascara de red "`" 0 0 $NETMASK 2> $TEMPFILE
		
	NETMASK="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null

	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2" \
	  --inputbox "`gettext -s "Ingrese el broadcast "`" 0 0 $BROADCAST 2> $TEMPFILE
		
	BROADCAST="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null


	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2" \
	  --inputbox "`gettext -s "Ingrese la puerta de enlace, deje en blanco si no dispone "`" 0 0 $GATEWAY 2> $TEMPFILE
		
	GATEWAY="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null



	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2" \
	  --inputbox "`gettext -s "Ingrese su servidor de DNS primario, deje en blanco si no dispone "`" 0 0 $DNS1 2> $TEMPFILE
		
	DNS1="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null



	TEMPFILE="/tmp/hostname"
	rm -f $TEMPFILE 2> /dev/null
	$DIALOG --backtitle "$DISTRO2" \
	  --inputbox "`gettext -s "Ingrese su servidor de DNS secundario, deje en blanco si no dispone "`" 0 0 $DNS2 2> $TEMPFILE
		
	DNS2="$(cat $TEMPFILE)"
	# Limpiando
	rm -f $TEMPFILE 2> /dev/null


}



########################################

########INSTALACION #####################

tipo_instalacion()

{

tempfile=/tmp/qinst


$DIALOG --clear --backtitle "$DISTRO2" --title "$DISTRO" \
        --menu "elija el método de instalación:" 0 0 3 \
        "Automática"  "Recomendada para usuarios novatos" \
        "Manual" "Instalación advanzada"  2> $tempfile

retval=$?

choice=`cat $tempfile`

case $retval in
  0)
if [ "$choice" = "Automática" ]; then
    
	TIPO=auto
	menu_instalacion_auto
	
fi

if [ "$choice" = "Manual" ]; then
    
	TIPO=manual
	menu_instalacion_manual

fi
;;


1)
$DIALOG --backtitle "$DISTRO2" --title "$DISTRO"\
 --msgbox "Salió de la instalación, presione enter, el sistema se reiniciará" 0 0
reboot -f -d -i -n
exit
;;

255)
$DIALOG --backtitle "$DISTRO2" --title "$DISTRO"\
 --msgbox "Salió de la instalación, presione enter, el sistema se reiniciará" 0 0
reboot -f -d -i -n
exit
;;

esac


}



menu_instalacion_manual()
{

$DIALOG --clear  --backtitle "$DISTRO2" --title "Tuquito-K GNU/linux" \
        --menu "Bienvenidos a la instalación avanzada de Tuquito" 0 0 17 \
	 $(echo "$NEXT" "$TEXT")  \
	 $(echo "$ANT" "$TEXT2" ) \
	 "" "" \
	"Idioma" "Configure el idioma del sistema" \
	"Teclado" "Configure la distribución del teclado" \
        "Hostname"  "Configure el nombre del sistema" \
        "Red" "Configure la red" \
        "Particionar"  "Particione el disco rígido" \
        "Activar"  "Active las particiones" \
	"Módulos" "Configure los módulos" \
        "Instalar"  "Instale Tuquito-k GNU/linux" \
        "Grub"  "Instale Grub"\
	"Reiniciar"  "Reinicie las variables de instalación"\
	"Salir" "Salir de la instalación" 2> $tempfile

retval=$?

choice=`cat $tempfile`

case $retval in
  0)
    
	if [ "Hostname" == "$choice" ] ; then
	
		conf_hostname

		ANT="Teclado"
		NEXT="Red"
		TEXT="Siguiente-->"
		TEXT2=" <--Anterior"

		
		menu_instalacion_manual
		
	fi

	if [ "Teclado" == "$choice" ] ; then
	
		conf_teclado2
		ANT="Idioma"
		NEXT="Hostname"
		TEXT="Siguiente-->"
		TEXT2="<--Anterior"
		menu_instalacion_manual
		
	fi

	if [ "" == "$choice" ] ; then
	
	
		menu_instalacion_manual
		
	fi

	if [ "Idioma" == "$choice" ] ; then
	
		conf_idioma
		ANT=""
		NEXT="Teclado"
		TEXT="Siguiente-->"
		TEXT2=""

		menu_instalacion_manual
		
	fi

	if [ "Red" == "$choice" ] ; then
	
		conf_red

		ANT="Hostname"
		NEXT="Particionar"
		TEXT="Siguiente-->"
		TEXT2=" <--Anterior"

		menu_instalacion_manual
		
	fi


	if [ "Particionar" == "$choice" ] ; then
	
		
		conf_particionar
		ANT="Red"
		NEXT="Activar"
		TEXT="Siguiente-->"
		TEXT2=" <--Anterior"
		
		
		menu_instalacion_manual
		
	fi


	if [ "Grub" == "$choice" ] ; then
	
		conf_grub 
		NEXT="Salir"
		ANT="Instalar"
		TEXT="Siguiente-->"
		TEXT2=" <--Anterior"

		menu_instalacion_manual
		
	fi

	if [ "Activar" == "$choice" ] ; then
	
		conf_activar 
		ANT="Particionar"
		NEXT="Módulos"
		TEXT="Siguiente-->"
		TEXT2=" <--Anterior"

		menu_instalacion_manual
		
	fi

	if [ "Instalar" == "$choice" ] ; then
	
		conf_verify

		ANT="Módulos"
		NEXT="Grub"
		TEXT="Siguiente-->"
		TEXT2=" <--Anterior"

		menu_instalacion_manual
		
	fi

	if [ "Módulos" == "$choice" ] ; then
	
		conf_modulos

		NEXT="Instalar"
		ANT="Activar"
		TEXT="Siguiente-->"
		TEXT2=" <--Anterior"

		menu_instalacion_manual
		
	fi

	if [ "Reiniciar" == "$choice" ] ; then
	
		conf_reniciar
		ANT=""
		NEXT=""
		TEXT=""
		TEXT2=""


		menu_instalacion_manual
		
	fi

	if [ "Salir" == "$choice" ] ; then
	
		conf_salir
		
	fi

;;
  1)
  tipo_instalacion    
  exit
  ;;
  255)
  tipo_instalacion
    exit
    ;;
esac
}



menu_instalacion_auto()
{
# Presentation
#
conf_info
#
# Disks
#

rm -f /tmp/partitions
TEMPFILE=/tmp/dialog

# Auswahl der Platte zum Partitionieren
TMP="/tmp/partitions"
NUMHD=0
if [ -f /proc/partitions ] ; then
  while read x x x p x
  do
    case "$p" in
      hd?)
        if [ "`cat /proc/ide/$p/media`" = "disk" ] ; then
          echo "$p `tr ' ' _ </proc/ide/$p/model`" >> $TMP
          NUMHD=$[NUMHD+1]
        fi
        ;;
      sd?)
        x="`scsi_info /dev/$p | grep MODEL | tr ' ' _`"
        x=${x#*\"}
        x=${x%\"*}
        echo "$p $x" >> $TMP
        NUMHD=$[NUMHD+1]
        ;;
      *) ;;
    esac
  done < /proc/partitions
fi
HARDDISKS="`cat $TMP`"

#$DIALOG --backtitle "$DISTRO" --title "Particionar el disco duro" \
#--radiolist "Seleccione un disco duro (La barra espaciadora selecciona):" 0 0 $NUMHD \
#  $(echo "$HARDDISKS" | while read p model ; do echo "$p" "$model" off ; done) 2> $TMP
#  
#HDCHOICE="`cat $TMP`"
#
#if [ -z "$HDCHOICE" ] ; then
#  $DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" --msgbox "No se ha seleccionado un disco duro. El script finalizará." 0 0
#  rm -f $TMP
#  tipo_instalacion
#fi

# Abrimos un treminal para ver logs
#sbin/getty 38400 tty2  >> /tmp/getty.log 2>&1 &

# Desmontamos la SWAp para que se pueda cambiar la tabla de particiones
while [ -n "`swapon -s | grep dev`" ]; do
        sync
        swapoff -a >> /tmp/install.log 2>&1
done

$DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" \
--msgbox "Ahora se arrancará la herramienta GPARTED \
de particionado." 0 0

gparted 2>> /tmp/install.log

PARTITIONS=`/sbin/fdisk -l | awk '/^\/dev\// {if ($2 == "*"){if ($6 == "83") \
{ print $1 };} else {if ($5 == "83") { print $1 };}}'`


if [ -z "$PARTITIONS" ]; then
	
$DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" --msgbox "No se han detectado particiones compatibles con Linux. Tendra a que volver a particionar su disco duro. " 0 0

menu_instalacion_auto

fi 

TMP="/tmp/partition"
rm -f $TMP 2> /dev/null

NUMPART=0
for i in $PARTITIONS
	do 
	NUMPART=$[NUMPART+1]
done

$DIALOG --backtitle "$DISTRO" --title "Particionar el disco duro" \
--radiolist "Seleccione una partición (La barra espaciadora selecciona):" 0 0 $NUMPART \
  $(for i in $PARTITIONS;	do echo "$i" "$i" off ; done) 2> $TMP
  
PART="`cat $TMP`"

if [ ! -b "$PART" ]; then
	
	$DIALOG --backtitle "$DISTRO2" --title "Particionar el disco duro" --msgbox "$PART no es una partición válida, presione ENTER para continuar" 0 0
	
	menu_instalacion_auto
else

#mkfs.ext3 $PART && metodo_instalacion
mount=$(grep $PART /etc/mtab | cut -d ' ' -f 2)

if [ "$mount" != "" ]; then

    umount $mount
    mount -a

fi

$DIALOG --backtitle "$DISTRO2" --title "Activar partición" \
  --yesno "Se va a formatear $PART con el sistema de archivo ext3 para prepararla para la instalación.
   Se perderán todos los datos, desea continuar? " 0 0  2> $TEMPFILE


if [ $? == "0" ]; then

rm /tmp/mkfs_end 2>> /tmp/install.log



test -f /tmp/inst-end && rm /tmp/inst-end

(mkfs.ext3 $PART && touch /tmp/inst-end)&

while [ ! -f /tmp/inst-end ];do

kdialog --passivepopup "Formateando, espere" 2

done

if [ $? == "0" ]; then

mount -t ext3 $PART $MOUNTPOINT >> /tmp/mount.log 2>&1

if [ $? == "0" ]; then

FOK=Y
else

conf_error 

fi
  
else
conf_error
fi

else
menu_instalacion_auto
fi

if [ $? == "0" ]; then


$DIALOG --backtitle "$DISTRO2" --msgbox "Partición activada con éxito..." 0 0

else

$DIALOG --backtitle "$DISTRO2" --msgbox "No se pudo activar la partición $PART" 0 0
menu_instalacion_auto
 
fi

#metodo_instalacion
#metodo_instalacion
INSTALAR=completa
instalacion_tuquito


fi
}



metodo_instalacion()

{

	  TEMPFILE="/tmp/inst"

	 $DIALOG --backtitle "$DISTRO2" --title "Instalacion"\
	 --menu "elija el tipo de instalacion" 0 0 3\
	  "Básica" "Instalación Básica"\
	  "Completa" "Instalación completa" 2>$TEMPFILE
	  
	  choice=`cat /tmp/inst`
	  

  case $choice in 


    Básica)

	  INSTALAR=base
          instalacion_tuquito    
;;
    Completa)


         INSTALAR=completa
         instalacion_tuquito
;;

255)
	if [ "$TIPO" = "auto" ]; then  
	
		menu_instalacion_auto
		
	fi		

	if [ "$TIPO" = "manual" ]; then  
	
		menu_instalacion_manual
		
	fi		

;;

-1)



	if [ "$TIPO" = "auto" ]; then  
	
		menu_instalacion_auto
		
	fi		

	if [ "$TIPO" = "manual" ]; then  
	
		menu_instalacion_manual
		
	fi		


;;
	

esac

}

instalacion_tuquito()
{


FSCHOICE=$PART
SWCHOICE=`/sbin/fdisk -l | awk '/^\/dev\// {if ($2 != "*") {if ($5 == "82") { print $1 }}}'`

if [ "$TIPO" = "auto" ]; then

mount $PART $MOUNTPOINT

fi

# Funtions
LOGDIR="/tmp/"


echo 0 > /proc/sys/kernel/printk

(echo "0" ; sleep 2 ; 

# Creando particion SWAP
if [ -n "$SWCHOICE" ]; then
	echo "XXX"
	echo "Activando partición SWAP....."
	echo "XXX"
	SWPOINT="$SWCHOICE"
else
	echo "XXX"
	echo "Creando archivo SWAP en $FSCHOICE....."
	echo "XXX"
	SWCHOICE="$MOUNTPOINT/swap"
	SWPOINT="/swap"
	head -c 128m /dev/zero > $SWCHOICE
fi
#sleep 2;
echo "15"; sleep 2;
echo "XXX"
echo "Activando partición SWAP....."
echo "XXX"
echo "25"
mkswap $SWCHOICE > /tmp/mkswap.log 2>&1
swapon $SWCHOICE > /tmp/swapon.log 2>&1
sleep 2;

echo "XXX"
echo "Instalando Tuquito-k GNU/linux en la partición $FSCHOICE....."
echo "XXX"
echo "30"

if [ "$INSTALAR" = "completa" ]; then

TOTAL=$(grep TOTAL /garfio/custom/custom.conf | cut -d '=' -f 2)
echo "TOTAL=$TOTAL" 2>> $LOGDIR/install.log

test -f /tmp/cp_end && rm /tmp/cp_end 2>> $LOGDIR/install.log

(cp -af /live/Distro/* $MOUNTPOINT/ > /tmp/cp_meta.log 2>&1 ; touch /tmp/cp_end) &

while [ ! -f "/tmp/cp_end" ]; do
	TAM=`du -s $MOUNTPOINT/ | cut -f 1`
	TAM=${TAM%M}
	echo $((($TAM * 50/ $TOTAL) + 30))
	sleep 2
done
fi

if [ "$INSTALAR" = "base" ]; then

TOTAL=669580
echo "TOTAL=$TOTAL" 2>> $LOGDIR/install.log

dbfile=`cat /garfio/templates/inst/base/lista.img`
dbdir=`cat /garfio/templates/inst/base/listadir.img`

test -f /tmp/cp_end && rm /tmp/cp_end 2>> $LOGDIR/install.log

(for i in $dbdir; do mkdir -p  $MOUNTPOINT$i ; done ; touch /tmp/cp_end)&


while [ ! -f "/tmp/cp_end" ]; do

	TAM=`du -s $MOUNTPOINT/ | cut -f 1`
	TAM=${TAM%M}
	echo $((($TAM * 50/ $TOTAL) + 30))
	sleep 2
done

test -f /tmp/cp_end && rm /tmp/cp_end 2>> $LOGDIR/install.log

(for i in $dbfile; do cp -af /live/Distro$i $MOUNTPOINT$i > /tmp/cp_base.log ; done ; touch /tmp/cp_end)&


while [ ! -f "/tmp/cp_end" ]; do
	TAM=`du -s $MOUNTPOINT/ | cut -f 1`
	TAM=${TAM%M}
	echo $((($TAM * 50/ $TOTAL) + 30))
	sleep 2
done


#Misc tuquito
cp -af /live/Distro/home/ /mnt/home/ 2>> $LOGDIR/install.log
#cp -af /TUQUITO/var/lib/apt/* /mnt/var/lib/apt/ 
chmod 777 /mnt/tmp 2>> $LOGDIR/install.log
#cp -af /TUQUITO/etc/cupsys/ /mnt/etc/
cp -af /garfio/templates/config/cache/* /mnt/var/lib/dpkg/ 2>> $LOGDIR/install.log
cp -af /live/Distro/dev/video* /mnt/dev/ 2>> $LOGDIR/install.log

fi

echo "TAM=$TAM" > $LOGDIR/install.log

#
# Kernel and Modules
#
echo "XXX"
echo "Copiando el Kernel y los módulos....."
echo "XXX"
echo "95"

cp -f /live/cdrom/boot/grub/vmlinuz $MOUNTPOINT/boot/vmlinuz 2>> $LOGDIR/install.log
cp -af /lib/modules/ $MOUNTPOINT/lib/ 2>> $LOGDIR/install.log


echo "XXX"
echo "Creando enlaces a los dispositivos....."
echo "XXX"
echo "97"


#
# Check for pcmcia
#
if [ ! -f "/tmp/pcmcia" ]; then
	chroot $MOUNTPOINT update-rc.d -f pcmcia remove >> $LOGDIR/pcmcia.log 2>&1
else
    echo "set bell-style none" >> $MOUNTPOINT/etc/inputrc
fi

	

#Enabled k3b user
#chmod 4777 $MOUNTPOINT/usr/bin/cdrecord*
#chmod 4777 $MOUNTPOINT/usr/bin/cdrdao

#
# CREAR /etc/fstab
#

test ! -d /mnt/media && mkdir /mnt/media

cat <<EOF >$MOUNTPOINT/etc/fstab
# /etc/fstab: static file system information.
#
# The following is an example. Please see fstab(5) for further details.
# Please refer to mount(1) for a complete description of mount options.
#
# Format:
#  <file system>         <mount point>   <type>  <options>      <dump>  <pass>
$FSCHOICE  /  ext3  defaults,errors=remount-ro  0  1
EOF
if [ "$SWCHOICE" != "none" ] ; then
  echo "$SWPOINT  none  swap  sw  0  0" >> $MOUNTPOINT/etc/fstab
fi
cat <<EOF >>$MOUNTPOINT/etc/fstab
proc /proc  proc  defaults  0  0
none /proc/bus/usb   usbdevfs  rw   0 0
none /media/a: supermount dev=/dev/fd0,fs=vfat,sync  0  0
EOF
		WINUM=1
		NTNUM=1
		LXNUM=1
		OTNUM=1

if [ -f /proc/partitions ]; then
    fdisk -l | awk '/^\/dev\// {
	if ($2 == "*") 
	{ print $1" "$6" "$7" "$8" "$9 } 
	else 
	{ print $1" "$5" "$6" "$7" "$8" "$9 }
	}' | \

		while read p n t; do

			options="user,exec"
			ID="1000"
			fnew=""

			# FIXME: Guess OS Version using osprobe udeb after detecting partition type
			# http://packages.debian.org/unstable/debian-installer/os-prober

			# For partition codes, please refer to
			#  http://www.win.tue.nl/~aeb/partitions/partition_types-1.html
			case "$n" in
				# 0B => WIN95 OSR2 FAT32
				# 0C => WIN95 OSR2 FAT32, LBA-mapped
				# 0E => WIN95: DOS 16-bit FAT, LBA-mapped
				b|c|e)
					options="${options},uid=$ID,gid=$ID";
					# FIXME unused $options
					fnew="$p /media/Windows9X$WINUM vfat auto,user,umask=000 0 0"
					echo "$fnew" >> $MOUNTPOINT/etc/fstab
					mkdir $MOUNTPOINT/media/Windows9X$WINUM
					
					WINUM=$[WINUM+1]
					;;
				# 07 => OS/2 IFS (e.g., HPFS)
				# 07 => Windows NT NTFS
				# 07 => Advanced Unix
				# 07 => QNX2.x pre-1988 (see below under IDs 4d-4f)
				7)
					options="${options},uid=$ID,gid=$ID";
					fnew="$p /media/WindowsXP$NTNUM ntfs-fuse auto,$options 0 0"
					echo "$fnew" >> $MOUNTPOINT/etc/fstab
					mkdir $MOUNTPOINT/media/WindowsXP$NTNUM
					
					NTNUM=$[NTNUM+1]
					;;
				# Linux native partition
				83)

					if [ "$p" != "$FSCHOICE" ]; then
					
					fnew="$p /media/Linux$LXNUM auto auto,$options 0 0"
					echo "$fnew" >> $MOUNTPOINT/etc/fstab
					mkdir $MOUNTPOINT/media/Linux$LXNUM
					LXNUM=$[LXNUM+1]
					
					fi
					
					;;
				# Linux swap
				82)
					# We need the entry in /etc/fstab to do a clean "swapon/swapoff -a" later
					fnew="$p swap swap defaults 0 0"
					mkswap $p
					swapon $p 2>/dev/tty2 && echo "$fnew" >> $MOUNTPOINT/etc/fstab
					;;
				# DOS 3.3+ Extended Partition
				5) ;;
				# 0F => WIN95: Extended partition, LBA-mapped
				f) ;;
				# Hidden WIN95 OSR2 FAT32
				1b) ;;
				# Hidden WIN95 OSR2 FAT32, LBA-mapped 
				1c) ;;
				# Hibernation partition
				84) ;;
				# Linux extended partition
				85) ;;
				# Other partition type
				*)
					fnew="$p /media/Otro$OTNUM auto auto,$options 0 0"
					echo "$fnew" >> $MOUNTPOINT/etc/fstab
					mkdir $MOUNTPOINT/media/Otro$OTNUM
					
					OTNUM=$[OTNUM+1]
					;;
			esac
		done
fi

# CDroms
#add_cdrom_mountpoints

# Add USB mount points
#SDA=`grep sda /etc/fstab | grep -v usb`
#SDB=`grep sdb /etc/fstab | grep -v usb`
#NUM=0
#if [ -z "$SDA" ]; then
#	echo "none /media/usb$NUM supermount dev=/dev/sda1,fs=vfat,sync  0  0" >> $MOUNTPOINT/etc/fstab
#	mkdir $MOUNTPOINT/media/usb$NUM 2>> /tmp/install.log
#	NUM=$[NUM+1]
#fi
#if [ -z "$SDB" ]; then
#	echo "none /media/usb$NUM supermount dev=/dev/sdb1,fs=vfat,sync  0  0" >> $MOUNTPOINT/etc/fstab
#	mkdir $MOUNTPOINT/media/usb$NUM 2>> /tmp/install.log
#fi


#
# COPY /etc/X11/XF86Config*
#
if [ -f "/etc/X11/XF86Config" ]; then
	cp -af /etc/X11/XF86Config $MOUNTPOINT/etc/X11/XF86Config 2>> $LOGDIR/install.log
fi

if [ -f "/etc/X11/XF86Config-4" ]; then
	cp -af /etc/X11/XF86Config-4 $MOUNTPOINT/etc/X11/XF86Config-4 2>> $LOGDIR/install.log
fi

if [ -f "/etc/X11/xorg.conf" ]; then
	cp -af /etc/X11/xorg.conf $MOUNTPOINT/etc/X11/xorg.conf 2>> $LOGDIR/install.log
fi

#Diskette
#test ! -d /media/a: && mkdir $MOUNTPOINT/media/a: 2>> /tmp/install.log
#ln -s /media/a: /a:

sync


echo "XXX"
echo "La instalación finalizó con éxito, ahora se terminará de configurar el sistema"
echo "XXX"
echo  "100";sleep 2;

) | \

Xdialog --clear --backtitle "$DISTRO2" --title "Tuquito-K GNU/linux" --gauge "Bienvenidos a la instalación de Tuquito" 10 40 0

if [ "$?" = "255" ] ; then
	
		menu_instalacion_auto
fi


#----------LIBERTAD---------------
#
#
#
export FTUCO=Xdialog
cd /garfio/templates/libertad/ && sh Libertad.sh
#
#
#



Xdialog --backtitle "$DISTRO2" --title "Instalación de $DISTRO" \
--yesno " Desea instalar Tuquito 3D Beryl?. " 0 0

	if [  $? = 0 ]; then

    
	    cp /garfio/templates/beryl/.bashrc /mnt/home/usuario
	    cp /garfio/templates/beryl/beryl-manager.desktop /mnt/home/usuario/.kde/Autostart/
    


	    Xdialog --backtitle "$DISTRO2" --title "Instalación de $DISTRO" \
		--yesno "Dispone de una placa de video nvidia. " 0 0


		if [  $? = 0 ]; then
		
				rm /mnt/usr/lib/libGL.so
				rm /mnt/usr/lib/libGL.so.1
				rm /mnt/usr/lib/xorg/modules/extensions/libglx.so
				ln -s /usr/lib/libGL.so.1.0.9631 /mnt/usr/lib/libGL.so
				ln -s /usr/lib/libGL.so.1.0.9631 /mnt/usr/lib/libGL.so.1
				ln -s /usr/lib/xorg/modules/extensions/libglx.so.1.0.9631 /mnt/usr/lib/xorg/modules/extensions/libglx.so


		fi
		
	fi



    cp /garfio/templates/beryl/sky360.png /mnt/usr/share/pixmaps/sky360.png
    #rm /mnt/home/usuario/.beryl-managerrc
    test -f /mnt/home/usuario/.beryl-managerrc && rm  /mnt/home/usuario/.beryl-managerrc
    cp /garfio/templates/config/issue /mnt/etc/

    rm /tmp/modules 2>>$LOGDIR/install.log

TPM="/tmp/modules"

modules=`tail +1 /proc/modules | grep -v '\[.*\]' | grep -v loop | grep -v squashfs | cut -d " " -f 1`

for mod in $modules
do
	echo $mod >> $TMP	
done

cp -f $TMP $MOUNTPOINT/etc/modules 2>> $LOGDIR/install.log


#echo "XXX Configurando splash.....XXX"

#SPLASH=$(grep SPLASH /conf/var.conf | cut -d '=' -f 2)

#if [ "$SPLASH" != "Y" ]; then

#	rm -f $MOUNTPOINT/boot/initrd

#fi



#configuracion del host
conf_hostname_system
echo "$HOSTNAME" > $MOUNTPOINT/etc/hostname 2>> $LOGDIR/hostname.log

#
#Configuracion del teclado
conf_teclado_system
echo "loadkeys -q $LANGUAGE" > /etc/init.d/loadkeys 2>> $LOGDIR/install.log
chmod 755 /etc/init.d/loadkeys 2>> $LOGDIR/install.log
ln -s /etc/init.d/loadkeys /etc/rcS.d/S41loadkeys 2>> $LOGDIR/install.log
cp /etc/init.d/loadkeys /mnt/etc/init.d/loadkeys  2>> $LOGDIR/install.log
cp -af /etc/rcS.d/S41loadkeys /mnt/etc/rcS.d/ 2>> $LOGDIR/install.log

echo "export LANGUAGE=es COUNTRY=es LANG=es_ES LC_ALL=es_ES" > /etc/init.d/language
chmod 755 /etc/init.d/language 2>> $LOGDIR/install.log
ln -s /etc/init.d/language /etc/rcS.d/S41language 2>> $LOGDIR/install.log
cp /etc/init.d/language /mnt/etc/init.d/ 2>> $LOGDIR/install.log
cp -af /etc/rcS.d/S41language /mnt/etc/rcS.d/ 2>> $LOGDIR/install.log


#
# set /etc/hosts
echo "127.0.0.1      ${HOSTNAME}       localhost
::1             localhost       ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
ff02::3         ip6-allhosts" > $MOUNTPOINT/etc/hosts 2> $LOGDIR/hosts.log




#-----------------configuracion del sistema--------------------

# set /etc/network/interfaces
echo "auto lo
iface lo inet loopback" > $MOUNTPOINT/etc/network/interfaces 2> $LOGDIR/interfaces.log

#Xdialog --backtitle "$DISTRO" \
#	  --yesno "¿Desea configurar su conexión de red?" 0 0 
#		
#	if [ $? = 0 ]; then
#
#
#$DIALOG --clear --title "Tuquito K GNU/linux" \
#        --menu "elija una configuración para su placa de red:" 0 0 4 \
#        "DHCP"  "Configura la red con DHCP" \
#        "MANUAL" "Configura la red manualmente"  2> $tempfile
#
#retval=$?
#
#choice=`cat $tempfile`
#
#case $retval in
#  0)
#if [ "$choice" = "DHCP" ]; then
#	echo "auto	eth0
#iface eth0 inet dhcp" >> $MOUNTPOINT/etc/network/interfaces 2> $LOGDIR/interfaces.log
#fi
#
#if [ "$choice" = "MANUAL" ]; then
#
#conf_red_system
#
#echo "auto	eth0
#iface eth0 inet static
#address $IP
#netmask $NETMASK
#broadcast $BROADCAST
#gateway $GATEWAY" >> $MOUNTPOINT/etc/network/interfaces 2> $LOGDIR/interfaces.log
#	echo "search
#nameserver $DNS1" > $MOUNTPOINT/etc/resolv.conf 2> $LOGDIR/resolv.log
#echo "nameserver $DNS2" >> $MOUNTPOINT/etc/resolv.conf 2> $LOGDIR/resolv.log
#
#fi
#  ;;
#  1)
#    continue;;
#  255)
#    continue;;
#esac
#fi
#
#
#. /tmp/var.conf
$DIALOG --backtitle "$DISTRO2" --msgbox "Se comenzará a configurar GRUB(Gestor de arranque) en $FSCHOICE, puede llevar unos minutos " 0 0
#sleep 2
#Fuse
echo fuse >> /mnt/etc/modules

#if [  -f "/sbin/grub" -o -f "/sbin/grub-install" ] ; then
	if [ ! -d "/mnt/boot/grub" ] ; then
		mkdir -p /mnt/boot/grub > $LOGDIR/grub.log 2>&1 &
	fi
	# Eliminar archivos antariores
	rm -f /mnt/boot/grub/device.map > $LOGDIR/grub.log 2>&1 &
	rm -f /mnt/boot/grub/menu.lst > $LOGDIR/grub.log 2>&1 &
	# Eliminar mensajes del kernel mientras se detectan dispositivos
	echo "0" > /proc/sys/kernel/printk
	# Crear el devices.map 
	grub-install --no-floppy --root-directory=/mnt $FSCHOICE > $LOGDIR/grub-install.log 2>&1
	# Crear el menu.lst
	grubconfig $FSCHOICE 
	# Volver a activas lo mensajes del Kernel
	echo "6" > /proc/sys/kernel/printk

	# Ahora el nombre en formato GRUB
	DRIVE=${FSCHOICE%[0-9]}
	let PART=${FSCHOICE#$DRIVE}-1
	GRUB_DEV=`grep $DRIVE /mnt/boot/grub/device.map | cut -c2-4`
	ROOT="(${GRUB_DEV},${PART})"
	chroot /mnt/ grub --batch --device-map=/boot/grub/device.map <<EOT
root    $ROOT
setup   (hd0)
quit
EOT
	
	
rm -f /mnt/etc/mtab 2>> $LOGDIR/install.log
touch /mnt/etc/mtab 2>> $LOGDIR/install.log
sync


LOGDIR="/tmp"

umount /mnt 2>> $LOGDIR/install.log
mount -a
sync

echo 6 > /proc/sys/kernel/printk


Xdialog  --title "Instalación" --msgbox "Se terminó con exito la instalación de $DISTRO en su disco duro." 0 0

echo 6 > /proc/sys/kernel/printk
#reboot  -d -i -f

exit

}

umount /media/*
umount /mnt
export TIPO=auto
menu_instalacion_auto
