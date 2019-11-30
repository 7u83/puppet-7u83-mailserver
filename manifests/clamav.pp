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

			$freshclam_service="clamav-freshclam"
			$freshclam="/usr/local/bin/freshclam"
			$freshclam_file="/var/db/clamav/main.cvd"
			$freshclam_conf="/usr/local/etc/freshclam.conf"
			$freshclam_receivetimeout=300
		}
		default: {
       			$packages = "clamav-milter"
		}
	}

}

class mailserver::clamav(
	$ldap = true,
	$oninfected = "Reject",
	$packages = $::mailserver::clamav::params::packages,
	$freshclam_receivetimeout = $::mailserver::clamav::params::freshclam_receivetimeout,
	$ensure = 'installed',

) inherits mailserver::clamav::params{

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

