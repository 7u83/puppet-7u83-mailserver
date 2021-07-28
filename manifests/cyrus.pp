#
# cyrus imap server
#
class mailserver::cyrus::params(){
  case $::osfamily {
    'FreeBSD':{
			$cfg_dir = "/usr/local/etc"
			$pkg_name = "cyrus-imapd30"
		}
	}
	$cyrus_conf = "$cfg_dir/cyrus.conf"
	$imapd_conf = "$cfg_dir/imapd.conf"
}

class mailserver::cyrus(
	$pkg_name = $mailserver::cyrus::params::pkg_name,
	$pkg_version = "latest",
	$pkg_settings = undef,

)
inherits mailserver::cyrus::params
{
  class {"mailserver::cyrus::install":

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
  }
	anchor {"cyrus_pkg_installed":}

}
