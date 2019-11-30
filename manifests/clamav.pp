#
# clamav installer 
#
class mailserver::clamav::params {

        case $::osfamily {
                'FreeBSD':{
			$milter_sock="unix:/var/run/clamav/clmilter.sock"
			$milter_conf="/usr/local/etc/clamav-milter.conf"
			$clamd_conf="/usr/local/etc/clamd.conf"
			$packages = "clamav"

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
}

