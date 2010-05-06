#!/bin/bash

mkdir -p /etc/linuxmint
cp /usr/lib/linuxmint/mint-upgrade-tool-main/cups-pdf.conf /etc/cups/cups-pdf.conf
cp /usr/lib/linuxmint/mint-upgrade-tool-main/printers.conf /etc/cups/printers.conf
cp /usr/lib/linuxmint/mint-upgrade-tool-main/gnome-2.soundlist /etc/sound/events/gnome-2.soundlist
cp /usr/lib/linuxmint/mint-upgrade-tool-main/default.pa /etc/pulse/default.pa
cp /usr/lib/linuxmint/mint-upgrade-tool-main/bash.bashrc /etc/bash.bashrc
rm -rf /etc/skel/.bashrc
rm -rf /root/.bashrc
cp /usr/lib/firefox-addons/searchplugins/en-US/* /usr/lib/firefox-addons/searchplugins/

