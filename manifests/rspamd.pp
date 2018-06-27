#
# rspamd.pp
#

class mailserver::rspamd()
{
        case $::osfamily {

                'FreeBSD':{
			ensure_resource ("package","portupgrade",{
			})

			$pkg = "rspamd"
			$cfg_dir = "/usr/local/etc/rspamd"
			$milter_socket = "/var/run/rspamd/milter"
			$milter_socket_mode = "0666"

			package {"$pkg":
				provider => 'portsng',
				ensure => 'installed',
				require => Package['portupgrade']
			}
		}
	}	

	$local_dir = "$cfg_dir/local.d"


	$cfgfiles = [
		"local.d/milter_headers.conf",
		"local.d/worker-normal.inc",
		"local.d/worker-proxy.inc",
	]


	file {"$local_dir":
		ensure => directory
	}

	$cfgfiles.each | String $file | {
		file { "$cfg_dir/$file":
			ensure => file,
			content => template("mailserver/rspamd/$file.erb"),
			require => File["$local_dir"],
		}
	}


}
