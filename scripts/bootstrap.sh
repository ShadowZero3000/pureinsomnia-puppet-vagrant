#!/usr/bin/env bash
#
# This bootstraps Puppet on Ubuntu 12.04 LTS.
#
set -e

# Load up the release information
. /etc/lsb-release

REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT
#--------------------------------------------------------------------
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if which puppet > /dev/null 2>&1 -a apt-cache policy | grep --quiet apt.puppetlabs.com; then
  echo "Puppet is already installed."
  exit 0
fi
checkfile="/tmp/system_has_provisioned"
if [ ! -f $checkfile ]; then
	# Do the initial apt-get update
	echo "Initial apt-get update..."
	apt-get update >/dev/null

	# Install wget if we have to (some older Ubuntu versions)
	echo "Installing wget..."
	apt-get install -y wget >/dev/null

	# Install the PuppetLabs repo
	echo "Configuring PuppetLabs repo..."
	repo_deb_path=$(mktemp)
	wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
	dpkg -i "${repo_deb_path}" >/dev/null
	apt-get update >/dev/null

	# Install Puppet
	echo "Installing Puppet..."
	DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install puppet >/dev/null

	echo "Puppet installed!"

	# Install RubyGems for the provider
	echo "Installing RubyGems..."
	if [ $DISTRIB_CODENAME != "trusty" ]; then
	  apt-get install -y rubygems >/dev/null
	fi
	gem install --no-ri --no-rdoc rubygems-update
	update_rubygems >/dev/null

	echo "Installing Git"
	apt-get install -y git >/dev/null

	echo "Installing r10k"
	gem install --no-ri --no-rdoc r10k >/dev/null

	touch $checkfile
else
	echo "Initial run already completed"
fi
vagrantfile=/vagrant/Vagrantfile
if [ ! -f $vagrantfile ]; then
	repo_home=/vagrant/pureinsomnia_puppet
else
	repo_home=/opt/puppet_repo
fi
echo "Running r10k"

pushd ${repo_home} >/dev/null
PUPPETFILE_DIR=/etc/puppet/modules \
r10k -v INFO puppetfile install
popd >/dev/null
