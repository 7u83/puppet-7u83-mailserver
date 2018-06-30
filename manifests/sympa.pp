#
# sympa.pp
#

class mailserver::sympa
(
	$domain,
	$listmaster,

	$localhost = undef,
	$web_url,

	$db_user = "sympa",
	$db_passwd = "sympa",
	$db_name = "sympa",
	$db_host = undef,

	$virtual = false,
	$log_level = undef,

	$mailserver = "postfix",
)
inherits mailserver::params

{
	if $localhost == undef {
		$_localhost = "loclahost"
	}


        case $::osfamily {
                'FreeBSD':{
			ensure_resource ("package","portupgrade",{})

			$packages = ["p5-DBD-mysql","p5-CGI-Fast","mhonarc"]
			
			$sympa_dir = "/usr/local/etc/sympa"
			$sympa_package = "sympa"
			$sympa_service="sympa"
			$sympa_fcgi_program="/usr/local/libexec/sympa/wwsympa.fcgi"
			$sympa_fcgi_socket="/var/run/wwsympa.socket"
			$mhonarc_cmd = "/usr/local/bin/mhonarc"
	
			package {$packages:
				ensure => installed	
			}

			package {"sympa":
				ensure => "installed",
				provider => "portsng",
				package_settings => {
					'APACHE' => false,
					'FASTCGI' => true,
				},
				require => [Package["portupgrade"],Package[$packages]],
			}
			
			

		}
		default: {
		}
	}

	$sympa_conf = "$sympa_dir/sympa.conf"

	# if no db host is given install a local mysql server
	if $db_host == undef {
		$_db_host = "$_localhost"
		include '::mysql::server'
		mysql::db { "$db_name":
			user     => "$db_user",
			password => "$db_passwd",
			host     => "$_db_host",
			grant    => ['ALL'],
		}
	} 
	else {
		$_db_host = $db_host
	}

	file {"$sympa_dir":
		ensure => directory,
		owner => "sympa",
		require => Package["$sympa_package"]
	}

	file {"$sympa_conf":
		ensure => file,
		content => template("mailserver/sympa.conf.erb"),
		require => File["$sympa_dir"],
		owner => "sympa",
	}
	

}



