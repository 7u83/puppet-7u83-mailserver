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
	  	$cert_dir = "/usr/local/certs"
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
	$mbx_default = true,
	$cert_source = undef,
	$cert_content = undef,
	$cert_key_source = undef,
	$cert_key_content = undef,
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

  if $::osfamily == 'FreeBSD' {
	  $ssl_set = $ssl ? {
			true => "SET",
			default => "UNSET",
		}
		$ssl_and_plain_set = $ssl_and_plain ? {
			true => "SET",
			default => "UNSET",
		}

  $bsdport_cclient_options=inline_template("# This file is auto-generated by 'make config'.
# Options for cclient-2007f_3,1
_OPTIONS_READ=cclient-2007f_3,1
_FILE_COMPLETE_OPTIONS_LIST=IPV6 MBX_DEFAULT SSL SSL_AND_PLAINTEXT
OPTIONS_FILE_SET+=IPV6
OPTIONS_FILE_UNSET+=MBX_DEFAULT
OPTIONS_FILE_<%=@ssl_set%>+=SSL
OPTIONS_FILE_<%=@ssl_and_plain_set%>+=SSL_AND_PLAINTEXT
		")

		$bsdport_uwimap_options=inline_template("# This file is auto-generated by 'make config'.
# Options for imap-uw-2007f_1,1
_OPTIONS_READ=imap-uw-2007f_1,1
_FILE_COMPLETE_OPTIONS_LIST=DOCS NETSCAPE_BRAIN_DAMAGE SSL SSL_AND_PLAINTEXT
OPTIONS_FILE_SET+=DOCS
OPTIONS_FILE_UNSET+=NETSCAPE_BRAIN_DAMAGE
OPTIONS_FILE_<%=@ssl_set%>+=SSL
OPTIONS_FILE_<%=@ssl_and_plain_set%>+=SSL_AND_PLAINTEXT")

    file {"/var/db/ports/mail_cclient/options":
  		ensure => file,
  		content => $bsdport_cclient_options
  	}
  	file {"/var/db/ports/mail_imap-uw/options":
  		ensure => file,
  		content => $bsdport_uwimap_options
  	}
  }

	
	if $cert_key_source or cert_key_content {
		file {$cert_dir:
			ensure => directory
		} ->
		file {"$cert_dir/imapd.pem.key":
			ensure => file,
			content => $cert_key_content,
			source => $cert_key_source,
		} ->
		file {"$cert_dir/imapd.pem.crt":
			ensure => file,
			content => $cert_content,
			source => $cert_source,
		} ->
		exec {"/bin/cat $cert_dir/imapd.pem.key $cert_dir/imapd.pem.crt > $cert_dir/imapd.pem":
			refreshonly => true,
			subscribe => [
				File["$cert_dir/imapd.pem.crt"],
				File["$cert_dir/imapd.pem.key"],
			]	
		}
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


