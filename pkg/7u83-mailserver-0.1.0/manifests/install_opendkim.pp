
class mailserver::install_opendkim(
	$dkim_source = "puppet:///dkim",
	$selector,

) inherits mailserver::params
{

	$keyfile  = "$opendkim_keysdir/${selector}.private"

        case $::osfamily {
                'FreeBSD':{
			package { "opendkim":
				ensure => installed
			}

			mailserver::sysrc{"milteropendkim_socket":
				ensure => "$opendkim_socket"
			}

			mailserver::sysrc{"milteropendkim_gid":
				ensure => "$opendkim_gid"
			}
			mailserver::sysrc{"milteropendkim_uid":
				ensure => "$opendkim_uid"
			}

		}
		default: {
			package { "opendkim":
				ensure => installed
			}

		}
	}

	file { "$opendkim_keysdir/${selector}.private":
		ensure => present,
		source => "$dkim_source/${selector}.private",
		mode => "600",
		owner => "postfix"
	}

	file { "$opendkim_cfgdir/opendkim.conf":
		ensure => present,
		content => template("mailserver/opendkim.conf.erb"),

	}

		
#	$dkim_keys.each | String $key | {
#		file { "$opendkim_keysdir/$key":
#			ensure => present,
#			source => "$dkim_source/$key",
#			mode => "600",
#			owner => "postfix"
#		}


#	}
	
}



#class mailserver::configure_dkim()
#inherits mailserver::params
#{
##	exec{ "/usr/sbin/sysrc  
#
#}
