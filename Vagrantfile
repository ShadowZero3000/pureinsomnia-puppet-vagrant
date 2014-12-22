# -*- mode: ruby -*-
# vi: set ft=ruby :
require "yaml"

_config = YAML.load(File.open(File.join(File.dirname(__FILE__), "config.yaml"), File::RDONLY).read)
CONF = _config

# If you want port forwarding, put it here. Ideally I'll add this to the config file later
nodes = [
  { :hostname => CONF['hostname'],  :box => CONF['box'] || 'precise', :box_url => CONF['box_url'] || 'default'}
]

Vagrant.configure("2") do |config|
  host_arch = ENV['X86_HOST'] ? '32' : '64'
  box_base_url = 'https://s3-us-west-1.amazonaws.com/ocx/vagrant/boxes/'
  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|

      # Name of the base box
      box = node[:box] + host_arch
      node_config.vm.box = box

      full_url = box_base_url + box + '.box'
      if node[:box_url] != 'default'
        full_url = node[:box_url]
      end


      # URL from where the box will be fetched if it does not already
      # exist on the user's system.
      node_config.vm.box_url = full_url

      node_config.vm.hostname = node[:hostname]

      # Private network
      if CONF['ip']
        node_config.vm.network :private_network, ip: CONF['ip']
      end
      node_config.vm.network :private_network, :auto_network => true

      # Port forwarding
      if node[:ports]
        node[:ports].each do |port|
          node_config.vm.network :forwarded_port, guest: port[:guest], host: port[:host]
        end
      end

      # Modify the VirtualBox image settings
      node_config.vm.provider :virtualbox do |vb|
        if node[:gui]
          # Don't boot in headless mode
          vb.gui = true
        end

        vb.customize [
          'modifyvm', :id,
          '--name', node[:hostname],
          '--natdnshostresolver1', 'on'
        ]
      end

      # Synced folders
      node_config.vm.synced_folder '.', "/mnt/shared"

      # Bootstrap in your puppet install and modules
      node_config.vm.provision "shell", path: "pureinsomnia_puppet/bootstrap.sh"

      # Provision using puppet
      node_config.vm.provision :puppet do |puppet|
        puppet.manifests_path = 'pureinsomnia_puppet/manifests'
        puppet.manifest_file = 'default.pp'
        puppet.module_path = 'pureinsomnia_puppet/modules'
        puppet.facter = CONF['facts'] || {}
        puppet.hiera_config_path = 'puppet/hiera.yaml'
        puppet.working_directory = '/vagrant/puppet/'
      end
      if File.exist?('puppet/manifests/' + node[:hostname] + '.pp')
        # Provision using puppet
        node_config.vm.provision :puppet do |puppet|
          puppet.manifests_path = 'puppet/manifests'
          puppet.manifest_file = 'default.pp'
          puppet.module_path = 'puppet/modules'
          puppet.facter = CONF['facts'] || {}
          puppet.hiera_config_path = 'puppet/vagrant.yaml'
          puppet.working_directory = '/tmp/vagrant-puppet'
        end
      end
    end
  end
end
