#!/usr/bin/env python

import sys

try:
     import pygtk
     pygtk.require("2.0")
except:
      pass
try:
    import gtk
    import gtk.glade
    import os
    import commands
    import threading
    import datetime
    from user import home
except:
    print "You do not have all the dependencies!"
    sys.exit(1)

from subprocess import Popen, PIPE

class MessageDialog:
	def __init__(self, title, message, style):
		self.title = title
		self.message = message
		self.style = style

	def show(self):
		
		dialog = gtk.MessageDialog(None, gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT, self.style, gtk.BUTTONS_OK, self.message)
		dialog.set_icon_from_file("/usr/lib/linuxmint/mint-upgrade-tool-main/icon.png")
		dialog.set_title("Upgrade Linux Mint")
		dialog.set_position(gtk.WIN_POS_CENTER)
	        dialog.run()
	        dialog.destroy()		

class upgradeThread(threading.Thread):

	def __init__(self, socketId, wTree):
		threading.Thread.__init__(self)
		self.socketId = socketId
		self.wTree = wTree

	def run(self):
		try:			
			gtk.gdk.threads_enter()
			self.wTree.get_widget("main_window").window.set_cursor(gtk.gdk.Cursor(gtk.gdk.WATCH))		
			gtk.gdk.threads_leave()

			# Step 1 Backup overwritten files
			if os.path.exists("/etc/apt/sources.list"):
				os.system("gksu cp /etc/apt/sources.list /etc/apt/sources.list.mint7")
			if os.path.exists("/etc/apt/preferences"):
				os.system("gksu cp /etc/apt/preferences /etc/apt/preferences.mint7")
			if os.path.exists("/etc/apt/apt.conf"):
				os.system("gksu cp /etc/apt/apt.conf /etc/apt/apt.conf.mint7")
			if os.path.exists("/etc/cups/cups-pdf.conf"):
				os.system("gksu cp /etc/cups/cups-pdf.conf /etc/cups/cups-pdf.conf.mint7")			
			if os.path.exists("/etc/cups/printers"):
				os.system("gksu cp /etc/cups/printers /etc/cups/printers.mint7")			
			if os.path.exists("/etc/sound/events/gnome-2.soundlist"):
				os.system("gksu cp /etc/sound/events/gnome-2.soundlist /etc/sound/events/gnome-2.soundlist.mint7")			
			if os.path.exists("/etc/pulse/default.pa"):
				os.system("gksu cp /etc/pulse/default.pa /etc/pulse/default.pa.mint7")			
			if os.path.exists("/etc/bash.bashrc"):
				os.system("gksu cp /etc/bash.bashrc /etc/bash.bashrc.mint7")			
			if os.path.exists("/root/.bashrc"):
				os.system("gksu cp /root/.bashrc /root/.bashrc.mint7")				
			if os.path.exists(home + "/.linuxmint"):
				os.system("cp -R " + home + "/.linuxmint " + home + "/.linuxmint.mint7")

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step1").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 2 Upgrade Ubuntu base

			os.system("gksu cp /usr/lib/linuxmint/mint-upgrade-tool-main/sources.list /etc/apt/sources.list")
			os.system("gksu cp /usr/lib/linuxmint/mint-upgrade-tool-main/preferences /etc/apt/preferences")
			os.system("gksu cp /usr/lib/linuxmint/mint-upgrade-tool-main/apt.conf /etc/apt/apt.conf")
			os.system("gksu \"synaptic --non-interactive --hide-main-window --update-at-startup --upgrade-mode --parent-window-id " + self.socketId + "\"")			

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step2").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 3 Install additional mint packages
			os.system("gksu \"synaptic --non-interactive --hide-main-window --set-selections-file /usr/lib/linuxmint/mint-upgrade-tool-main/additional.list --parent-window-id " + self.socketId + "\"")
			os.system("gksu \"synaptic --non-interactive --hide-main-window --update-at-startup --parent-window-id " + self.socketId + "\"")

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step3").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 4 Dist-Upgrade
			os.system("gksu \"synaptic --non-interactive --hide-main-window --update-at-startup --dist-upgrade-mode --parent-window-id " + self.socketId + "\"")

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step4").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 5 Ensure upgrade and dist-upgrade
			os.system("gksu \"synaptic --non-interactive --hide-main-window --update-at-startup --upgrade-mode --parent-window-id " + self.socketId + "\"")
			os.system("gksu \"synaptic --non-interactive --hide-main-window --update-at-startup --dist-upgrade-mode --parent-window-id " + self.socketId + "\"")

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step5").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()			

			# Step 6 Install additional mint packages
			os.system("gksu \"synaptic --non-interactive --hide-main-window --set-selections-file /usr/lib/linuxmint/mint-upgrade-tool-main/additional2.list --parent-window-id " + self.socketId + "\"")
			os.system("gksu \"synaptic --non-interactive --hide-main-window --update-at-startup --parent-window-id " + self.socketId + "\"")

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step6").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 7 Adjust filesystem changes
			os.system("gksu /usr/lib/linuxmint/mint-upgrade-tool-main/adjust.sh")

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step7").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 8 configure gconf
			os.system("gksu /usr/lib/linuxmint/mint-upgrade-tool-main/gconf.sh")

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step8").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 9 Reconfigure artwork package
			os.system("gksu \"aptitude reinstall -y mint-artwork-gnome\"")		

			gtk.gdk.threads_enter()
			self.wTree.get_widget("step9").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()

			# Step 10 Cleaning up
			os.system("gksu /usr/lib/linuxmint/mint-upgrade-tool-main/cleanup.sh")
			os.system("rm -rf " + home + "/.linuxmint")
			os.system("mintmenu clean")
		
			gtk.gdk.threads_enter()
			self.wTree.get_widget("step10").set_from_stock(gtk.STOCK_YES,4)
			gtk.gdk.threads_leave()		
			

			gtk.gdk.threads_enter()
			self.wTree.get_widget("main_window").window.set_cursor(None)		
			gtk.gdk.threads_leave()

			gtk.gdk.threads_enter()			
			message = MessageDialog("Upgrade finished", "The upgrade process is finished, please reboot your computer. If you've seen error messages you can run this tool again or seek help from the forums.", gtk.MESSAGE_INFO)
	    		message.show()			
			gtk.gdk.threads_leave()	

			gtk.main_quit()
			

		except Exception, detail:
			print detail
			#gtk.gdk.threads_enter()			
			message = MessageDialog("Error", "An error occurred during the upgrade: " + str(detail), gtk.MESSAGE_ERROR)
	    		message.show()	
			#gtk.gdk.threads_leave()	
			#gtk.main_quit()

class mainWindow:

    def __init__(self):
	# Set the Glade file
        self.gladefile = "/usr/lib/linuxmint/mint-upgrade-tool-main/upgrader.glade"
        self.wTree = gtk.glade.XML(self.gladefile,"main_window")	
	self.vbox = self.wTree.get_widget("vbox_main")
	self.wTree.get_widget("main_window").set_icon_from_file("/usr/lib/linuxmint/mint-upgrade-tool-main/icon.png")

	# Get the window socket (needed for synaptic later on)
	socket = gtk.Socket()
	self.vbox.pack_start(socket)
	socket.show()
	self.socketId = repr(socket.get_id())
	# Start the upgrade
	upgrade = upgradeThread(self.socketId, self.wTree)
	upgrade.start()	

class warningWindow:

    def __init__(self):
	#Set the Glade file
        self.gladefile = "/usr/lib/linuxmint/mint-upgrade-tool-main/upgrader.glade"
        self.wTree = gtk.glade.XML(self.gladefile,"warning_dialog")
	self.wTree.get_widget("warning_dialog").connect("destroy", gtk.main_quit)
	self.wTree.get_widget("button_cancel").connect("clicked", gtk.main_quit)
	self.wTree.get_widget("button_confirm").connect("clicked", self.confirm)
	self.wTree.get_widget("warning_dialog").set_icon_from_file("/usr/lib/linuxmint/mint-upgrade-tool-main/icon.png")
   	self.wTree.get_widget("warning_dialog").set_title("Warning message")

    def confirm(self, widget):
	self.wTree.get_widget("warning_dialog").hide()
	mainWindow()
	
if __name__ == "__main__":
	gtk.gdk.threads_init()
	mainwin = warningWindow()
	gtk.main()


