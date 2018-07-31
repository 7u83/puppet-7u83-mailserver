#
# install opendmarc
#

class mailserver::opendmarc(
	$umask = undef,
	$reject_failures = undef,
	$software_header = undef,
	$spf_self_validate,
) 
{
        case $::osfamily {
                'FreeBSD':{
			$conf = "/usr/local/etc/mail/opendmarc.conf"
			$pkg = "opendmarc"
			$service = "opendmarc"
			$milter_socket = "/var/run/opendmarc/milter"

			package { "$pkg":
				ensure => installed,
				require => Mailserver::Sysrc["opendmarc_socketspec"]
			}

			mailserver::sysrc{"opendmarc_socketspec":
				ensure => "$milter_socket"
			}

		}
		default: {
			$pkg = "opendmarc"
			$conf = "/etc/mail/opendmarc.conf"
			$service = "opendmarc"
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
