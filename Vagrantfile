# -*- mode: ruby -*-
# vi: set ft=ruby :

hostname = "vagrant.dev"
synced_folder = "/var/www/#{hostname}"
public_folder = "/var/www/#{hostname}/public"

# Set a local private network IP address.
# See http://en.wikipedia.org/wiki/Private_network for explanation
# You can use the following IP ranges:
#   10.0.0.1    - 10.255.255.254
#   172.16.0.1  - 172.31.255.254
#   192.168.0.1 - 192.168.255.254
server_ip             = "172.#{Random.new.rand(16..31)}.#{Random.new.rand(0..255)}.#{Random.new.rand(1..254)}"
server_cpus           = "1"   # Cores
server_memory         = "384" # MB
server_swap           = "768" # Options: false | int (MB) - Guideline: Between one or two times the server_memory

# UTC        for Universal Coordinated Time
# EST        for Eastern Standard Time
# US/Central for American Central
# US/Eastern for American Eastern
server_timezone  = "UTC"

# Database Configuration
mysql_root_password   = "root"   # We'll assume user "root"
mysql_version         = "5.5"    # Options: 5.5 | 5.6 (5.5 is the default for Debian Jessie)
mysql_enable_remote   = "false"  # remote access enabled when true

# Languages and Packages
php_timezone          = "UTC"    # http://php.net/manual/en/timezones.php

# To install HHVM instead of PHP, set this to "true"
hhvm                  = "false"

if ARGV[0] == 'up'
	print "Edit Vagrantfile to update hostname and IP"
	print "\n\nProvisioning with hostname \"" + hostname + "\" and IP " + server_ip
	print "\n\nContinue? [y/n]"

	begin
		system("stty raw -echo")
		str = STDIN.getc
	ensure
		system("stty -raw echo")
	end

	print "\n"

	if str != 'Y' && str != 'y'
		exit
	end
end

scripts_path = "https://raw.githubusercontent.com/groovenectar/vagrant/master/_provision/"

Vagrant.configure("2") do |config|
	# Set server to Debian
	config.vm.box = "debian/jessie64"
	# Use this for Magento < 1.9 (PHP 5.4)
	# config.vm.box = "debian/wheezy64"

	# Resolve "stdin: is not a tty" errors
	config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
	# https://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
	# config.ssh.pty = true

	# Create a hostname, don't forget to put it to the `hosts` file
	# This will point to the server's default virtual host
	config.vm.hostname = hostname
	config.vm.network :private_network, ip: server_ip

	# config.vm.network :forwarded_port, guest: 80, host: 8000

	config.vm.synced_folder ".", synced_folder, :mount_options => ["dmode=777", "fmode=774"]

	config.vm.provider :virtualbox do |vb|
		vb.name = hostname

		# Set server cpus
		vb.customize ["modifyvm", :id, "--cpus", server_cpus]

		# Set server memory
		vb.customize ["modifyvm", :id, "--memory", server_memory]

		# Set the timesync threshold to 10 seconds, instead of the default 20 minutes.
		# If the clock gets more than 15 minutes out of sync (due to your laptop going
		# to sleep for instance, then some 3rd party services will reject requests.
		vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]

		# Prevent VMs running on Ubuntu to lose internet connection
		# vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
		# vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
	end

	config.vm.provision :shell, path: "#{scripts_path}base.sh", args: [server_swap, server_timezone]
	config.vm.provision :shell, path: "#{scripts_path}base_privileged.sh", privileged: true

	# Provision PHP
	config.vm.provision :shell, path: "#{scripts_path}php.sh", args: [php_timezone, hhvm]

	# Provision Nginx Base
	config.vm.provision :shell, path: "#{scripts_path}nginx.sh", args: [server_ip, public_folder, synced_folder, hostname]

	# Provision Apache Base
	# config.vm.provision "shell", path: "#{scripts_path}apache.sh", args: [server_ip, public_folder, synced_folder, hostname]

	# Provision MySQL
	# config.vm.provision "shell", path: "#{scripts_path}mysql.sh", args: [mysql_root_password, mysql_version, mysql_enable_remote]

	# Provision Composer
	config.vm.provision "shell", path: "#{scripts_path}composer.sh", privileged: false

	# Install Mailcatcher
	# config.vm.provision "shell", path: "#{scripts_path}mailcatcher.sh"

	# Extra provisioning
	if (File.exist?('provision.sh'))
		config.vm.provision "shell", path: "provision.sh", args: [server_ip, public_folder, synced_folder, hostname]
	end
end
