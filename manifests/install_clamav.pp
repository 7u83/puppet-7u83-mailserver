#

class mailserver::install_clamav(
	$ldap = true
) {
        case $::osfamily {
                'FreeBSD':{
			package {"clamav-milter":
#				provider => "portsng",
				ensure => 'installed',
			}
		}
		default: {
       			package {"clamav-milter":
#				provider => "portsng",
				ensure => 'installed',
			}
		}
	}
}
