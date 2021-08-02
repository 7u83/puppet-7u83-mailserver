#
# clamav installer 
#
class mailserver::clamav::params {

        case $::osfamily {
                'FreeBSD':{
			$packages = "clamav"

			$milter_sock="unix:/var/run/clamav/clmilter.sock"
			$milter_conf="/usr/local/etc/clamav-milter.conf"
			$milter_service="clamav-milter"

			$clamd_conf="/usr/local/etc/clamd.conf"
			$clamd_service="clamav-clamd"
			$clamd_sock="unix:/var/run/clamav/clamd.sock"

			$freshclam_service="clamav-freshclam"
			$freshclam="/usr/local/bin/freshclam"
			$freshclam_file="/var/db/clamav/main.cvd"
			$freshclam_conf="/usr/local/etc/freshclam.conf"
			$db_dir = "/var/db/clamav"
		}
		'Debian':{
       			$packages = ["clamav-milter","clamav-daemon"]

			$milter_sock="/var/run/clamav/clamav-milter.ctl"
			$milter_conf="/usr/local/etc/clamav-milter.conf"
			$milter_service="clamav-milter"

			$clamd_conf="/etc/clamav/clamd.conf"
			$clamd_service="clamav-daemon"
			$clamd_sock="unix:/var/run/clamav/clamd.ctl"

			$freshclam_service="clamav-freshclam"
			$freshclam="/usr/bin/freshclam"
			$freshclam_file="/var/lib/clamav/main.cvd"
			$freshclam_conf="/etc/clamav/freshclam.conf"
			$db_dir = "/var/lib/clamav"

		}
		default: {
       			$packages = "clamav-milter"

#			$freshclam_service="clamav-freshclam"
#			$freshclam="/usr/local/bin/freshclam"
#			$freshclam_file="/var/db/clamav/main.cvd"
#			$freshclam_conf="/usr/local/etc/freshclam.conf"


		}
	}
			$freshclam_receivetimeout=300

}

class mailserver::clamav(
	$ldap = true,
	$oninfected = "Reject",
	$packages = $::mailserver::clamav::params::packages,
	$freshclam_receivetimeout = $::mailserver::clamav::params::freshclam_receivetimeout,
	$ensure = 'installed',

) inherits mailserver::clamav::params{

  if $ensure == 'installed'{
  	package {$packages:
  		ensure => $ensure
  	} ->
  	file {$freshclam_conf:
  		ensure => file,
  		content => template('mailserver/clamav/freshclam.conf.erb')
  	} ->
  	exec {"$freshclam":
  		creates => "$freshclam_file",
  		timeout => 600,
  	} 

  	service {"$freshclam_service":
  		ensure => running,
  		require => [
  			Exec["$freshclam"]
  		], 
  	}

  	file { "$milter_conf":
  		ensure => present,
  		content => template("mailserver/clamav-milter.conf.erb"),
  		require => Package[$packages]
  	} ->
  	service {"$milter_service":
  		ensure => running,
  		require => [
  			Service["$clamd_service"]
  		],
  		subscribe => File["$milter_conf"],
  	}
  	service {"$clamd_service":
  		ensure => running,
  		require => [
  			Exec["$freshclam"],
  		]
  	}
  }
  else {
    #  	service {"$freshclam_service":
    #		ensure => stopped,
    #}->
    #service {"$clamd_service":
    #	ensure => stopped,
    #}->
    #service {"$milter_service":
    #	ensure => stopped,
    #}
    package {$packages:
  		ensure => $ensure 
  	} 
  }
}

