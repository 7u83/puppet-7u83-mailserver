#
# rspamd.pp
#
#
class mailserver::rspamd::params
{
  case $::osfamily {

    'FreeBSD':{
      ensure_resource ("package","portupgrade",{})

			$pkg = "rspamd"
			$service = "rspamd"
			$cfg_dir = "/usr/local/etc/rspamd"
			$milter_socket = "/var/run/rspamd/milter"
			$milter_socket_mode = "0666"

			package {"$pkg":
				ensure => 'installed',
			}

		}
		'Debian': {
			$pkg = "rspamd"
			$service = "rspamd"
			$cfg_dir = "/etc/rspamd"
			$milter_socket = "/var/run/rspamd/milter"
			$milter_socket_mode = "0666"
			apt::source {"rspamd_source":
				location =>  "http://rspamd.com/apt-stable/",
				repos => 'main',
				key => {
					id => "3FA347D5E599BE4595CA2576FFA232EDBF21E25E",
					server => "keys.gnupg.net",
				},
				include => {
					'src' => true,
					'dev' => true,
				}
				
			}	
			package {"$pkg":
				ensure => 'installed',
				require => Apt::Source['rspamd_source'],
			}
		}
	}	

  $db_backend = 'sqlite3'
  $fuzzy_db_backend = 'sqlite'
}

class mailserver::rspamd(
	$reject_score = undef,
	$greylist_score = undef,
	$add_header_score = undef,
  $control_secure_ips = [
  ],
  $fuzzy_allow_update = "localhost",
  $local_fuzzy_servers = "localhost:11335"

  ) inherits mailserver::rspamd::params
  {
    $local_dir = "$cfg_dir/local.d"

    $cfgfiles = [
      "local.d/milter_headers.conf",
      "local.d/actions.conf",
      "local.d/worker-normal.inc",
      "local.d/worker-proxy.inc",
      "local.d/worker-controller.inc",
      "local.d/classifier-bayes.conf",
      "local.d/worker-fuzzy.inc",
      "local.d/fuzzy_check.conf",
    ]

    file {"$local_dir":
      ensure => directory,
      require => Package[$pkg]
    }

    class {"mailserver::rspamd::update_cfgfiles":}

    service {"$service":
      ensure => running,
      require => Class["mailserver::rspamd::update_cfgfiles"],
      subscribe => Class["mailserver::rspamd::update_cfgfiles"],
    }

  }


  class mailserver::rspamd::update_cfgfiles()
  inherits mailserver::rspamd{

    $cfgfiles.each | String $file | {
      file { "$cfg_dir/$file":
        ensure => file,
        content => template("mailserver/rspamd/$file.erb"),
        require => File["$local_dir"],
      }
    }
  }

