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

			}
		default: {
       			package {"clamav-milter":
				ensure => 'installed',
			}
		}
	}

}

class mailserver::clamav(
	$ldap = true,
	$packages = $::mailserver::clamav::params::packages,
	$ensure = 'installed',

) inherits mailserver::clamav::params{

	package {$packages:
		ensure => $ensure
	}

}
