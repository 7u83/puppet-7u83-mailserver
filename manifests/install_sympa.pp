#
class mailserver::install_sympa
(
#	$domain,
#	$listmaster,

)
inherits mailserver::params

{

        case $::osfamily {
                'FreeBSD':{
			$packages = ["p5-DBD-mysql","p5-CGI-Fast"]

			package {$packages:
				ensure => installed	
			}

			package {"sympa":
				ensure => "installed",
				provider => "portsng",
				package_settings => {
					'APACHE' => false,
					'FASTCGI' => true,
				},
				require => Package["portupgrade"],
			}
			
			

		}
		default: {
		}
	}


 
}



