#
class mailserver::install_sympa
(
	$domain,
	$listmaster,

)
inherits mailserver::params

{

        case $::osfamily {
                'FreeBSD':{
			$packages = ["sympa","p5-DBD-mysql"],
			package {$packages:
				ensure => "installed",
			}
			

		}
		default: {
		}
	}

	file {"$sympa_conf":
		ensure => file,
		content => template("mailserver/sympa.conf.erb"),
	}


 
}



