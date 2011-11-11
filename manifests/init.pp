#
# Author:: James Turnbull <james@puppetlabs.com>
# Module Name:: bprobe
#
# Copyright 2011, Puppet Labs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class bprobe {

  require bprobe::params
  require bprobe::dependencies

  $username       = $bprobe::params::username
  $apikey         = $bprobe::params::apikey
  $collector      = $bprobe::params::collector
  $collector_port = $bprobe::params::collector_port

  file { '/usr/local/bin/provision_meter.sh':
    mode => '0755',
    source => 'puppet:///modules/bprobe/provision_meter.sh',
  }

  exec { 'boundary_meter':
    command => "/usr/local/bin/provision_meter.sh -a $username:$apikey -d /etc/bprobe",
    creates => '/etc/bprobe/key.pem',
    require => File['/etc/bprobe'],
  }

  # boundary_meter { $fqdn:
  #   ensure   => present,
  #   username => $username,
  #   apikey   => $apikey,
  #   provider => boundary_meter,
  # }

  file { '/etc/bprobe/':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  package { 'bprobe':
    ensure  => latest,
    require => File['/etc/bprobe'],
  }

  file { '/etc/bprobe/bprobe.defaults':
    ensure  => present,
    content => template('bprobe/bprobe.defaults.erb'),
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    notify  => Service['bprobe'],
    require => Package['bprobe'],
  }

  file { '/etc/bprobe/ca.pem':
    ensure  => present,
    source  => 'puppet:///modules/bprobe/ca.pem',
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    notify  => Service['bprobe'],
    require => Package['bprobe'],
  }

  service { 'bprobe':
    ensure  => running,
    enable  => true,
    require => [Package['bprobe'], Exec['boundary_meter']],
  }
}
