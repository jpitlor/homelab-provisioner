#!/usr/bin/env bash

wget https://apt.puppetlabs.com/puppet7-release-focal.deb
sudo dpkg -i puppet7-release-focal.deb
sudo apt-get update
sudo apt-get install puppet-agent

source /etc/profile.d/puppet-agent.sh
puppet config set server puppet.pitlor.dev --section main
puppet ssl bootstrap
# On the server
# sudo puppetserver ca sign --certname <name>
# then run puppet ssl bootstrap again
