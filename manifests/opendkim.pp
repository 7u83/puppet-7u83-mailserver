#
# opendkim installation
#
class mailserver::opendkim::params {
        case $::osfamily {
                'FreeBSD':{
			$service = "milter-opendkim"
			$cfgdir = "/usr/local/etc/mail"
			$cfgfile = "/usr/local/etc/mail/opendkim.conf"
			$keysdir = "/var/db/dkimkeys"
			$uid='mailnull'
			$gid='mailnull'
			$pkg = "opendkim"
			$milter_sock='local:/var/run/milteropendkim/opendkim.sock'
			$pid_file='/var/run/milteropendkim/opendkim.pid'
		}
		'Debian': {
			$service = "opendkim"
			$cfgdir = "/etc/mail"
			$cfgfile = "/etc/opendkim.conf"
			$keysdir = "/etc/dkimkeys"
			$uid='opendkim'
			$gid='opendkim'
			$milter_sock='local:/var/run/opendkim/opendkim.sock'
			$pid_file='/var/run/opendkim/opendkim.pid'
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
	$pid_file = $mailserver::opendkim::params::pid_file,

) inherits mailserver::opendkim::params
{


	package { $pkg:
		ensure => installed
	}

	$dkmynetworks = join($mynetworks,", ")

	ensure_resource("file","$cfgdir",{
		ensure => directory
	})


	if $keyfile_content or $keyfile_source {

		file { "$keysdir":
			ensure => directory,
			owner => "$uid",
			group => "$gid",
			mode => '700',
		}

		file { "$keysdir/${selector}.private":
			ensure => present,
			source => $keyfile_source,
			content => $keyfile_content,
			mode => "600",
			owner => "$uid",
			group => "$gid",
			require => [
				Package[$pkg], 
				File["$keysdir"]
			],
			notify => Service[$service],
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

	file { "$cfgfile":
		ensure => present,
		content => template("mailserver/opendkim.conf.erb"),
		require => [Package[$pkg],Anchor[pre-config]],
		notify => Service[$service],
	}


        if $::osfamily == 'FreeBSD' {
		mailserver::sysrc { "milteropendkim_socket_perms":
			ensure => "775",
			notify => Service[$service]
		}
	} ->
	service {$service:
		ensure => running,
		require => File["$cfgfile"],
	}


	
}

