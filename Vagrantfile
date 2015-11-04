# -*- mode: ruby -*-
# vi: set ft=ruby :

hostname = "vagrant.dev"
synced_folder = "/var/www/#{hostname}"
public_folder = "/var/www/#{hostname}/public"

local_http_url="http://#{hostname}/"
local_https_url="http://#{hostname}/"

magento="false"
wordpress="false"
laravel="false"

# Create new MySQL database
database_name         = "" # Blank to skip
database_user         = ""
database_pass         = "" # Blank to prompt
database_table_prefix = ""

# Import a remote MySQL database
# `vagrant ssh` to start import
remote_database_ssh_user     = "" # Blank to skip
remote_database_ssh_host     = ""
remote_database_name         = ""
remote_database_user         = ""
remote_database_pass         = "" # Blank to prompt
remote_database_table_prefix = ""

# http://en.wikipedia.org/wiki/Private_network
# 10.0.0.1    - 10.255.255.254
# 172.16.0.1  - 172.31.255.254
# 192.168.0.1 - 192.168.255.254
server_ip     = "172.23.103.200" # Static IP
# server_ip   = "172.#{Random.new.rand(16..31)}.#{Random.new.rand(0..255)}.#{Random.new.rand(1..254)}"

# Magento < 1.9 needs PHP <= 5.5
vm_box = "debian/jessie64"  # Debian 8, PHP 5.6, MySQL 5.5
# vm_box = "debian/wheezy64"  # Debian 7, PHP 5.4, MySQL 5.5
# vm_box = "ubuntu/vivid64"   # Ubuntu 15.04, PHP 5.6, MySQL 5.5
# vm_box = "ubuntu/trusty64"  # Ubuntu 14.04, PHP 5.5, MySQL 5.5
# vm_box = "ubuntu/precise64" # Ubuntu 12.04, PHP 5.3, MySQL 5.5

webserver = "nginx" # ["nginx"|"apache"|"none"]

# UTC        for Universal Coordinated Time
# EST        for Eastern Standard Time
# US/Central for American Central
# US/Eastern for American Eastern
server_timezone = "UTC"
php_timezone    = "UTC"    # http://php.net/manual/en/timezones.php

# Database Configuration
mysql_root_password = "root"  # Blank to prompt
mysql_enable_remote = "false" # remote access enabled when true
mysql_version       = "5.6"   # ["5.5"|"5.6"]

# To install HHVM instead of PHP, set this to "true"
hhvm = "false"

first_run = Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/#{hostname}/*").empty?
if (first_run && (ARGV[0] == 'up' || ARGV[0] == 'provision'))
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

if (first_run && (ARGV[0] == 'up' || ARGV[0] == 'provision') && mysql_root_password == '')
	print "\nEnter MySQL root password: "
	mysql_root_password = STDIN.noecho(&:gets).chomp
end

if (first_run && (ARGV[0] == 'up' || ARGV[0] == 'provision') && database_name != '' && database_pass == '')
	print "\nEnter new MySQL database password: "
	database_pass = STDIN.noecho(&:gets).chomp
end

if (first_run && (ARGV[0] == 'up' || ARGV[0] == 'provision') && remote_database_ssh_user != '' && remote_database_pass == '')
	# print "\nEnter remote MySQL database password: "
	# remote_database_pass = STDIN.noecho(&:gets).chomp
	print "\nYou will be prompted for remote database connection information on first `vagrant ssh` session.\n"
	print "Press any key to continue..."
	STDIN.getch
	print "\n\n"
end

# Globals
$repo_url = "https://raw.githubusercontent.com/groovenectar/vagrant/master"
$scripts_path = "/_provision"

# Get local or remote path to script/conf
def script_path(script)
	if (File.exist?(".#{$scripts_path}/#{script}"))
		return ".#{$scripts_path}/#{script}"
	end
	return "#{$repo_url}#{$scripts_path}/#{script}"
end

server_cpus           = "1"   # Cores
server_memory         = "384" # MB
server_swap           = "768" # Options: false | int (MB) - Guideline: Between one or two times the server_memory

Vagrant.configure("2") do |config|
	config.vm.box = "#{vm_box}"

	config.vm.define "#{hostname}" do |vapro|
	end

	# Resolve "stdin: is not a tty" errors
	config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
	# https://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
	# config.ssh.pty = true

	# Create a hostname, don't forget to put it to the `hosts` file
	# This will point to the server's default virtual host
	config.vm.hostname = hostname
	# Use a private network (the whole IP specified above)
	config.vm.network :private_network, ip: server_ip
	# Use a forwarded port
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
		if ("#{vm_box}" == 'ubuntu/vivid64' || "#{vm_box}" == 'ubuntu/trusty64' || "#{vm_box}" == 'ubuntu/precise64')
			vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
			vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
		end
	end

	# Base scripts
	config.vm.provision "shell", path: script_path('base.sh'), args: [server_swap, server_timezone, synced_folder, public_folder]
	config.vm.provision "shell", path: script_path('base_privileged.sh'), args: [server_swap, server_timezone, synced_folder, public_folder], privileged: true

	# Provision Apache
	if (webserver == 'apache')
		config.vm.provision "shell", path: script_path('apache.sh'), args: [server_ip, public_folder, synced_folder, hostname, script_path('vhost-apache.conf')]
	end

	# Provision Nginx, using PHP-FPM
	if (webserver == 'nginx')
		config.vm.provision "shell", path: script_path('nginx.sh'), args: [server_ip, public_folder, synced_folder, hostname, script_path('nginx.conf'), script_path('vhost-nginx.conf')]
	end

	# Provision MySQL
	config.vm.provision "shell", path: script_path('mysql.sh'), args: [
		mysql_root_password,
		mysql_enable_remote,
		database_name,
		database_user,
		database_pass,
		database_table_prefix,
		remote_database_ssh_user,
		remote_database_ssh_host,
		remote_database_name,
		remote_database_user,
		remote_database_pass,
		remote_database_table_prefix,
		synced_folder,
		local_http_url,
		local_https_url,
		script_path('mysql_remote_pull.sh'),
		mysql_version,
		local_http_url,
		local_https_url,
		magento,
		wordpress
	]

	# Provision PHP
	config.vm.provision "shell", path: script_path('php.sh'), args: [php_timezone, hhvm]

	# Provision Composer
	config.vm.provision "shell", path: script_path('composer.sh'), privileged: false

	# Install Mailcatcher
	# config.vm.provision "shell", path: script_path('mailcatcher.sh')

	# Extra provisioning
	if (File.exist?('provision.sh'))
		config.vm.provision "shell", path: "provision.sh", args: [server_ip, public_folder, synced_folder, hostname, mysql_root_password, database_name, database_user, database_pass]
	end
end
