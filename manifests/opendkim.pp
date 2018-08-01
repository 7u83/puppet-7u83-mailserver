# dkim install

class mailserver::opendkim(
	$dkim_source = "puppet:///dkim",
	$selector,
	$domains,
	$mynetworks,

) inherits mailserver::params
{

        case $::osfamily {
                'FreeBSD':{

			$service = "milter-opendkim"
			$cfgdir = "/usr/local/etc/mail"
			$keysdir = "/usr/local/etc/mail"
			$uid='postfix'
			$gid='postfix'
			$socket='/var/spool/postfix/private/opendkim'
			$milter_sock='unix:/var/spool/postfix/private/opendkim'
			$pkg = "opendkim"

			package { "$pkg":
				ensure => installed
			}

			mailserver::sysrc{"milteropendkim_socket":
				ensure => "$socket"
			}

			mailserver::sysrc{"milteropendkim_gid":
				ensure => "$gid"
			}
			mailserver::sysrc{"milteropendkim_uid":
				ensure => "$uid"
			}

		}
		default: {
			$service = "opendkim"
			$cfgdir = "/etc/mail"
			$keysdir = "/etc/mail"
			$uid='opendkim'
			$gid='opendkim'
			$socket='/var/spool/postfix/private/opendkim'
			$milter_sock='unix:/var/spool/postfix/private/opendkim'
			$pkg = "opendkim"

			package { "$pkg":
				ensure => installed
			}

		}
	}

	$keyfile  = "$keysdir/${selector}.private"
	$dkmynetworks = join($mynetworks,", ")



	file { "$keysdir/${selector}.private":
		ensure => present,
		source => "$dkim_source/${selector}.private",
		mode => "600",
		owner => "$uid",
		require => Package["$pkg"],
	}

	file { "$cfgdir/opendkim.conf":
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
