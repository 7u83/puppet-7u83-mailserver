#
# uwimap
#

class mailserver::uwimap::params(){
        case $::osfamily {
                'FreeBSD':{
			ensure_resource ("package","portupgrade",{})
			$pkg_name = "mail/imap-uw"
			$prepkg_name = "mail/cclient"
			$pkg_provider = portsng
			$inetd_conf = "/etc/inetd.conf"
			$inetd_service = "inetd"
		}
	}
}

class mailserver::uwimap(
	$pkg_name = $mailserver::uwimap::params::pkg_name,
	$pkg_version = 'latest',
	$pkg_provider = $mailserver::uwimap::params::pkg_provider,
	$ensure = present,
	$ssl = true ,
	$ssl_and_plain = true,
	$mbx_default = false,
) 
inherits mailserver::uwimap::params
{
	$prepkg_settings = {
		'IPV6' => true,
		'MBX_DEFAULT' => $mbx_default,
		'SSL' => $ssl,
		'SSL_AND_PLAINTEXT' => $ssl_and_plain
	}
	$pkg_settings = {
		'SSL' => $ssl,
		'SSL_AND_PLAINTEXT' => $ssl_and_plain
	}

	ensure_resource('class','mailserver::inetd',{})
	package {$prepkg_name:
		ensure => $ensure ? {
			absent => absent,
			default => $pkg_version,
		},
		provider => $pkg_provider,
		package_settings => $prepkg_settings,
	} ->

	package {$pkg_name:
		ensure => $ensure ? {
			absent => absent,
			default => $pkg_version,
		},
		provider => $pkg_provider,
		package_settings => $pkg_settings,
	}  ->
	anchor {"mailserver_uw_imap_installed":}

	mailserver::inetd::service {"imap4":
		socket_type => 'stream',
		protocol => 'tcp',
		cmd => '/usr/local/libexec/imapd',
		args => 'imapd',
		require => [
			Anchor['mailserver_uw_imap_installed'],
		],
		ensure => $ensure
	}

}


class mailserver::uwimap::configure_inetd ()
inherits mailserver::uwimap
{
		
}

