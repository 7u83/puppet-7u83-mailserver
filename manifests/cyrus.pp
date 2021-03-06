#
# cyrus imap server
#
class mailserver::cyrus::params(){
  case $::osfamily {
    'FreeBSD':{
			$cfg_dir = "/usr/local/etc"
			$pkg_name = "cyrus-imapd34"
      $db_dir = "/var/imap"
      $cyrus_user = "cyrus"
      $mkimapcmd = "/usr/local/cyrus/sbin/mkimap"
		}
	}
	$cyrus_conf = "$cfg_dir/cyrus.conf"
	$imapd_conf = "$cfg_dir/imapd.conf"
  $imap_server_cert = $::mailserver::imap_server_cert
  $imap_server_key = $::mailserver::imap_server_key
}

class mailserver::cyrus(
	$pkg_name = $mailserver::cyrus::params::pkg_name,
	$pkg_version = "latest",
	$pkg_settings = undef,
  $sieve = undef,
  $lmtp_port = '24',
)
inherits mailserver::cyrus::params
{
  class {"mailserver::cyrus::install":

  }
  service {"imapd":
    ensure    => running,
    require   => Anchor['cyrus_pkg_installed'],
    subscribe => [
      File[$cyrus_conf],
      File[$imapd_conf]
    ]
  }
}


class mailserver::cyrus::saslauthd::params()
{
	case $::osfamily {
		'FreeBSD':{
			$service = 'saslauthd'
			$pkg = 'cyrus-sasl-saslauthd'
		}
	}
}

class mailserver::cyrus::saslauthd()
inherits mailserver::cyrus::saslauthd::params
{
	package {$pkg:
		ensure => $pkg_version
	}
	service{$service:
		ensure => running
	} ->
	anchor {"saslauthd_installed":}
}

class mailserver::cyrus::install()
inherits mailserver::cyrus
{
  package {$pkg_name:
    ensure => installed
  } ->
  file{$cyrus_conf:
    ensure =>  file,
    content => template("mailserver/cyrus/cyrus.conf.erb"),
  } ->
  file{$imapd_conf:
    ensure =>  file,
    content => template("mailserver/cyrus/imapd.conf.erb"),
  } ->
  exec {"$mkimapcmd":
    creates => $db_dir 
  }

 	anchor {"cyrus_pkg_installed":}
}
