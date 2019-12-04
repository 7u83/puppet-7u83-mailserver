# dkim install
#
#
class mailserver::opendkim::params {
        case $::osfamily {
                'FreeBSD':{

			$service = "milter-opendkim"
			$cfgdir = "/usr/local/etc/mail"
			$keysdir = "/usr/local/etc/mail"
			$uid='mailnull'
			$gid='mailnull'
#			$socket='/var/run/milteropendkim/opendkim.sock'
			$pkg = "opendkim"
			$milter_sock='local:/var/run/milteropendkim/opendkim.sock'
		}
		default: {
			$service = "opendkim"
			$cfgdir = "/etc/mail"
			$keysdir = "/etc/mail"
			$uid='opendkim'
			$gid='opendkim'
#			$socket='/var/spool/postfix/private/opendkim'
			$milter_sock='unix:/var/spool/postfix/private/opendkim'
			$pkg = "opendkim"

		}
	}
}

class mailserver::opendkim(
	$selector,
	$domains = "*",
	$mynetworks = ['127.0.0.1'],
	$keyfile = "$keysdir/${selector}.private",
	$keyfile_content = undef,
	$keyfile_source = undef,
	$uid = $mailserver::opendkim::params::uid,
	$gid = $mailserver::opendkim::params::gid,
	$milter_sock = $mailserver::opendkim::params::milter_sock,

) inherits mailserver::opendkim::params
{
	package { $pkg:
		ensure => installed
	}

	$dkmynetworks = join($mynetworks,", ")


	if $keyfile_content or $keyfile_source {	
		file { "$keysdir/${selector}.private":
			ensure => present,
			source => $keyfile_source,
			content => $keyfile_content,
			mode => "600",
			owner => "$uid",
			group => "$gid",
			require => Package[$pkg],
		}
	}



        if $::osfamily == 'FreeBSD' {
		mailserver::sysrc{"milteropendkim_socket":
			ensure => $milter_sock
		} ->
		mailserver::sysrc{"milteropendkim_gid":
			ensure => $gid
		} ->
		mailserver::sysrc{"milteropendkim_uid":
			ensure => $uid
		} ->
		anchor {"pre-config":}
	}
	else {
		anchor {"pre-config":}
	}

	file { "$cfgdir/opendkim.conf":
		ensure => present,
		content => template("mailserver/opendkim.conf.erb"),
		require => [Package[$pkg],Anchor[pre-config]],
		notify => Service[$service],
	}

	service {$service:
		ensure => running,
		require => File["$cfgdir/opendkim.conf"],
	}
	
}




