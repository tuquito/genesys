#!/bin/bash

gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --load /usr/lib/linuxmint/mint-upgrade-tool-main/nautilus-actions.gconf
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --load /usr/lib/linuxmint/mint-upgrade-tool-main/panel.gconf
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --load /usr/lib/linuxmint/mint-upgrade-tool-main/ctrl.gconf
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type boolean --set /apps/nautilus/desktop/computer_icon_visible true
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type boolean --set /apps/nautilus/desktop/home_icon_visible true
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type boolean --set /apps/nautilus/desktop/volumes_visible true
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type bool --set /apps/nautilus/preferences/enable_delete true
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type string --set /desktop/gnome/url-handlers/mailto/command "thunderbird %s"
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type bool --set /apps/gedit-2/preferences/editor/save/create_backup_copy false
gconftool-2 --type string --set /apps/nautilus/preferences/background_color "#AD3841"
gconftool-2 --type bool --set /apps/nautilus/preferences/background_set true
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type string --set /desktop/gnome/background/picture_options "zoom"
gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type bool --set /desktop/gnome/interface/menus_have_icons true

