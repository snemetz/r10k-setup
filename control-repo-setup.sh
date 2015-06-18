#!/bin/bash
# Initialize a puppet control repo for r10k

# Author: Steven Nemetz

repo='puppet-r10k'
#git_url="ssh://git@stash.barnesandnoble.com:7777/nook_cloud_systems/${repo}.git
# GitLab can't handle repo without master branch
#git_url="git@git.techops.fireeye.com:${repo}.git"
git_url="git@github.com:snemetz/${repo}.git"

mkdir $repo
cd $repo
git init
mkdir {hieradata,manifests}

cat > README.txt <<"README"
r10k puppet control repository for Production environment
README

cat >hieradata/README.txt <<"hREADME"
Hiera data for Production environment
hREADME

cat >manifests/README.txt <<"mREADME"
Manifests for Production environment
mREADME

cat >environment.conf <<"ENV"
modulepath          = modules:$basemodulepath
config_version      = '/usr/bin/git --git-dir $confdir/environments/$environment/.git rev-parse HEAD'
environment_timeout = 3m
ENV

cat >hiera.yaml <<"HIERA"
---
:hierarchy:
  - "%{::location}/%{::hostname}/%{module_name}"
  - "%{::location}/%{module_name}"
  - "%{module_name}"
  - common

:backends:
  - yaml
:yaml:
# When specifying a datadir, make sure the directory exists.
  :datadir: "/etc/puppetlabs/puppet/environments/%{::environment}/hieradata"
HIERA

cat > Puppetfile <<"PUPPET"
forge "http://forge.puppetlabs.com"

# Modules from the Puppet Forge
# mod "<user>/<module>"[, '<version>']
mod "puppetlabs/apache"
mod "puppetlabs/ntp"

# mod '<module>'[, '<version>']
#   :git =>
#   :path =>
#   :ref => <branch/sha/tag/anything that git will recognize>
#   :github_tarball =>

# Modules from Github using various references
mod 'notifyme',
  :git => 'git://github.com/glarizza/puppet-notifyme',
  :ref => '50c01703b2e3e352520a9a2271ea4947fe17a51f'

mod 'profiles',
  :git => 'git://github.com/glarizza/puppet-profiles',
  :ref => '3611ae4253ff01762f9bda1d93620edf8f9a3b22'

PUPPET

cat > configure_r10k.pp <<"cR10K"
######         ######
##  Configure R10k ##
######         ######

##  This manifest requires the zack/R10k module and will attempt to
##  configure R10k according to glarizza's blog post on directory environments.
##  Beware! (and good luck!)

class { 'r10k':
  #version           => '1.3.2',
  sources           => {
    'puppet' => {
      # 'remote'  => 'https://github.com/glarizza/puppet_repository.git',
      'remote'  => 'https://github.com/snemetz/puppet-r10k.git',
      'basedir' => "${::settings::confdir}/environments",
      'prefix'  => false,
    }
  },
  purgedirs         => ["${::settings::confdir}/environments"],
  manage_modulepath => false,
}
cR10K

cat > configure_directory_environments.pp <<"cDirEnv"
######                           ######
##  Configure Directory Environments ##
######                           ######

##  This manifest requires the puppetlabs/inifile module and will attempt to
##  configure puppet.conf according to the blog post on using R10k and
##  directory environments.  Beware!

# Default for ini_setting resources:
Ini_setting {
  ensure => present,
  path   => "${::settings::confdir}/puppet.conf",
  # notify => Exec['trigger_r10k'],
}

ini_setting { 'Configure environmentpath':
  section => 'main',
  setting => 'environmentpath',
  value   => '$confdir/environments',
}

ini_setting { 'Configure basemodulepath':
  section => 'main',
  setting => 'basemodulepath',
  value   => '$confdir/modules:/opt/puppet/share/puppet/modules',
}

exec { 'trigger_r10k':
  command     => 'r10k deploy environment -p',
  path        => '/opt/puppet/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
  refreshonly => true,
}
cDirEnv

cat <<INSTALL >install.sh
#!/bin/bash
puppet module install zack/r10k
puppet apply configure_r10k.pp
# puppet apply configure_directory_environments.pp
r10k deploy environment -pv
# Copy hiera.yaml from production environment to confdir
hiera=$(puppet config print | grep hiera_config | cut -d= -f2)
environments=$(puppet config print | grep environmentpath | cut -d= -f2)
cp ${environments}/production/hiera.yaml ${hiera}
INSTALL
chmod +x install.sh

git add --all
git commit -m 'Initial creation'
git branch -m master production
echo "url: $git_url"
git remote add origin $git_url
echo "push"
git push --set-upstream origin production
git --git-dir `pwd`/.git symbolic-ref HEAD refs/heads/production
# Change default branch in git portal gui
# Add puppet data files

