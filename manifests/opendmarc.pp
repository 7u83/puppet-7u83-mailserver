#
# install opendmarc
#

class mailserver::opendmarc(
	$umask = undef,
	$reject_failures = true,
	$software_header = true,
	$spf_self_validate = true,
) 
{
        case $::osfamily {
                'FreeBSD':{
			$conf = "/usr/local/etc/mail/opendmarc.conf"
			$pkg = "opendmarc"
			$service = "opendmarc"
			$milter_socket = "/var/run/opendmarc/milter"
			$pid_file='/var/run/opendmarc/opendmarc.pid'

			package { "$pkg":
				ensure => installed,
				require => Mailserver::Sysrc["opendmarc_socketspec"]
			}

			mailserver::sysrc{"opendmarc_socketspec":
				ensure => "$milter_socket"
			}

		}
		'Debian': {
			$pkg = "opendmarc"
			$conf = "/etc/opendmarc.conf"
			$service = "opendmarc"
			$milter_socket = "/var/run/opendmarc/milter"
			$pid_file='/var/run/opendmarc/opendmarc.pid'
			package { "$pkg":
				ensure => installed
			}

		}
	}
	
	service{ "$service":
		ensure => running,
		require => File["$conf"],
		subscribe => File["$conf"],
	}

	file { "$conf":
		ensure => present,
		content => template("mailserver/opendmarc.conf.erb"),
		require => Package["$pkg"],
	}

}
