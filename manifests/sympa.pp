#
# sympa.pp
#

class mailserver::sympa::params(
	$pkg_provider = undef,
	$db_type = "sqlite",
	$db_host = undef,
	$db_user = "sympa",
	$db_passwd = "sympa",
	$db_name = undef,

) {
        case $::osfamily {
                'FreeBSD':{
			$sqlite_db = "/var/db/sympa/sympa.sqlite3"
			$sqlite_db_dir = "/var/db/sympa"
			$mysql_db = 'sympa'
			$sympa_user = "sympa"
			$sympa_group = "sympa"
			$sympa_aliases = "/usr/local/etc/sympa/sympa_aliases"
			$sympa_sendmail_aliases ="/usr/local/etc/sympa/sympa_sendmail_aliases"

			$libexec_dir="/usr/local/libexec/sympa"
		}
	}
}


class mailserver::sympa
(
	$mta = $::mailserver::mta,

	$domain,
	$stitle = undef,
	$listmaster,
	$web_url,

	$localhost = "localhost",

	$db_user = $mailserver::sympa::params::db_user,
	$db_passwd = $mailserver::sympa::params::db_passwd,
	$db_host = $mailserver::sympa::params::db_host,
	$db_type = $mailserver::sympa::params::db_type,
	$db_name = $mailserver::sympa::params::db_name ? {
		undef => $db_type ? {
				'sqlite' => $mailserver::sympa::params::sqlite_db,
				'mysql' => $mailserver::sympa::params::mysql_db,
				default => undef, 
			},
		default => $mailserver::sympa::params::db_name
		},

	$virtual = false,
	$virtual_domains = [],
	$gecos =  undef, 
	$log_level = undef,
	$web_location = "/sympa",
	$static_web_location = "/static-sympa",

	$logo_html_definition = false,

#	$mailserver = "postfix",
	$fcgi_addr = false,
	$dmarc_protection_mode = undef,
)
inherits mailserver::sympa::params
{

	
	$makealiases_cmd = inline_template("<%= scope.lookupvar(\"mailserver::${mta}::makealiases_cmd\") %>")
	$makemap_cmd = inline_template("<%= scope.lookupvar(\"mailserver::${mta}::makemap_cmd\") %>")

	notify {"SYMPA: ($mta) $makealiases_cmd, $makemap_cmd":} 	

	$_sympa_domain = $domain

	$sympa_dmarc_protection_mode = $dmarc_protection_mode ? {
		"reject" => "dmarc_reject",
		default => "dmarc_accept",
	}


        case $::osfamily {
                'FreeBSD':{
			ensure_resource ("package","portupgrade",{})

			$packages = [
				"p5-DBD-SQLite",
				"p5-DBD-mysql",
				"p5-CGI-Fast",
				"mhonarc"
			]
			
			$sympa_dir = "/usr/local/etc/sympa"
			$sympa_data_dir = '/usr/local/share/sympa/list_data'
			$sympa_package = "sympa"
			$sympa_service="sympa"
			$sympa_fcgi_program="/usr/local/libexec/sympa/wwsympa.fcgi"
			$sympa_fcgi_socket="/var/run/wwsympa.socket"
			$sympa_health_check="/usr/sbin/chown -R sympa /usr/local/share/sympa && /usr/local/bin/sympa.pl --health_check"
			$sympa_static_dir="/usr/local/share/sympa/static"
			$sympa_aliases = "/usr/local/etc/sympa/sympa_aliases"
			$sympa_sendmail_aliases ="/usr/local/etc/sympa/sympa_sendmail_aliases"
			$sympa_transport = "/usr/local/etc/sympa/sympa_transport"
			$sympa_virtal_sympa = "/usr/local/etc/sympa/virtal.sympa"
			$sympa_transport_sympa = "/usr/local/etc/sympa/transport.sympa"

			$sympa_libexec_dir="/usr/local/libexec/sympa"
			$perl = "/usr/local/bin/perl"


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
					'SQLITE' => ('sqlite' == $db_type),
					'MYSQL' => ('mysql' == $db_type),
					
				},
				require => [Package["portupgrade"],Package[$packages]],
			}
			
			

		}
		default: {
#			$packages = []
			
			$sympa_dir = "/etc/sympa"
			$sympa_package = "sympa"
			$sympa_service="sympa"
			$sympa_fcgi_program="/usr/local/libexec/sympa/wwsympa.fcgi"
			$sympa_fcgi_socket="/var/run/wwsympa.socket"
			$sympa_health_check="/usr/sbin/chown -R sympa /usr/local/share/sympa && /usr/local/bin/sympa.pl --health_check"
			$sympa_static_dir="/usr/local/share/sympa/static"
			$sympa_aliases = "/usr/local/etc/sympa/sympa_aliases"
			$sympa_sendmail_aliases ="/usr/local/etc/sympa/sympa_sendmail_aliases"
			$sympa_transport = "/usr/local/etc/sympa/sympa_transport"
			$sympa_virtal_sympa = "/usr/local/etc/sympa/virtal.sympa"
			$sympa_transport_sympa = "/usr/local/etc/sympa/transport.sympa"

			$sympa_libexec_dir="/usr/local/libexec/sympa"
			$perl = "/usr/local/bin/perl"


			$mhonarc_cmd = "/usr/local/bin/mhonarc"
	
#			package {$packages:
#				ensure => installed	
#			}

			package {"sympa":
				ensure => "installed",
			}
			
		}
	}

	$sympa_conf = "$sympa_dir/sympa.conf"

        case $db_type {
		'mysql':{
			$_db_type = 'mysql'	
			# if no db host is given install a local mysql server
			if $db_host == undef {
				$_db_host = "$localhost"
				include '::mysql::server'
				mysql::db { "$db_name":
					user     => "$db_user",
					password => "$db_passwd",
					host     => "$_db_host",
					grant    => ['ALL'],
				}
				exec {"$sympa_health_check":
					refreshonly => true,
					subscribe => [File["$sympa_conf"],Mysql::Db[$db_name]],
					require => [File["$sympa_conf"],Mysql::Db[$db_name]],
				}
			} 
			else {
				$_db_host = $db_host
				exec {"$sympa_health_check":
					refreshonly => true,
					subscribe => File["$sympa_conf"],
					require => File["$sympa_conf"]
				}
			}
		}
		'sqlite':{
			$_db_type = 'SQLite'
			file {$sqlite_db_dir:
				ensure => directory,
				owner => $sympa_user,
				group => $sympa_group,
				mode => "600",
				require => [
					Package[$packages]
				] 
			} -> 
			file {$sqlite_db:
				ensure => file,
				owner => $sympa_user,
				group => $sympa_group,
				mode => "600",
			} 

			exec {"$sympa_health_check":
				refreshonly => true,
				subscribe => File["$sympa_conf"],
				require => File["$sympa_conf"]
			}
		}

	}

	file {"$sympa_dir":
		ensure => directory,
		owner => "sympa",
		require => Package["$sympa_package"]
	}

	$http_host = $domain

	file {"$sympa_conf":
		ensure => file,
		content => template("mailserver/sympa.conf.erb"),
		require => File["$sympa_dir"],
		owner => "sympa",
	}


	service {"$sympa_service":
		ensure => "running",
		require => Exec["$sympa_health_check"]
	}
	
#	Class {"mailserver::sympa::postfix":}




	if $fcgi_addr == false {
		$_sympa_fcgi_addr = "$localhost"
		class {"nginx": }

		nginx::resource::server {"sympa_web":
			listen_port => 80,
			ensure => present
		}

		nginx::resource::location {"sympa_web_location $domain":
			ensure => present,	
			server => "sympa_web",
			location => "$web_location",
			fastcgi=>"unix:$sympa_fcgi_socket",
			location_cfg_append => {
#				fastcgi_split_path_info => '^($web_location)(.*)$',
				fastcgi_split_path_info => join ( ['^(', $web_location,')(.*)$'],''),

			},
			fastcgi_param => {
				'SCRIPT_FILENAME' => "$sympa_fcgi_program",
				'PATH_INFO' => '$fastcgi_path_info',
				'SERVER_NAME' => $domain,
			}
		}



		$virtual_domains.each | $d | {


			$domain = $d[domain]
			$web_location = $d[web_location]
			$web_url = $d[web_url]
			$http_host = $d[domain]
			$stitle = $d[title]

			nginx::resource::location {"sympa_web $domain":
				ensure => present,	
				server => "sympa_web",
				location => $d[web_location],
				fastcgi=>"unix:$sympa_fcgi_socket",
				location_cfg_append => {
					fastcgi_split_path_info => join ( ['^(', $web_location,')(.*)$'],''),
				},
				fastcgi_param => {
					'SCRIPT_FILENAME' => "$sympa_fcgi_program",
					'PATH_INFO' => '$fastcgi_path_info',
					'SERVER_NAME' => $d[domain],	
				}
			}

			file {"$sympa_data_dir/$domain":
				ensure => directory,
				owner => sympa,
			}

			file {"$sympa_dir/$domain":
				ensure => directory,
				owner => sympa,
			}
			
			file {"$sympa_dir/$domain/robot.conf":
				ensure => present,
				require => File["$sympa_dir/$domain"],
				content => template("mailserver/sympa_robot.conf.erb"),
			}

		
		}



		nginx::resource::location {"sympa_static_location":
			ensure => present,	
			server => "sympa_web",
			location => "$static_web_location",
			location_cfg_append => {
				alias => "$sympa_static_dir",
			}
		}
	}
	else{
		$_sympa_fcgi_addr = $fcgi_addr
	}



	class {"mailserver::spawn_fcgi":
		username => "sympa",
		groupname => "sympa",
		app => "$perl",		
		app_args => "$sympa_fcgi_program",
		bindsocket => "$sympa_fcgi_socket",
		bindsocket_mode => "0600 -U www",
		bindaddr => $_sympa_fcgi_addr,
		bindport => $sympa_fcgi_port,
	}

 
	class {"mailserver::sympa::sendmail":
	}

}

class mailserver::sympa::sendmail()
inherits mailserver::sympa
{
	file {$sympa_sendmail_aliases:
		ensure => file,
		owner => $sympa_user,
		group => $sympa_group,
		mode => "640",
		require => Class["mailserver::sympa"],
	}->
	file {"$sympa_sendmail_aliases.db":
		ensure => file,
		owner => $sympa_user,
		group => $sympa_group,
		mode => "640",
		require => Class["mailserver::sympa"],
	}  


	file {"$sympa_dir/list_aliases.tt2":
		ensure => present,
		source => "puppet:///modules/mailserver/sympa_list_aliases.tt2",
		owner => "sympa",
		require => Class["mailserver::sympa"],
	}


	file {$sympa_aliases:
		ensure => file,
#		owner => $sympa_user,
#		group => $sympa_group,
		mode => "640",
		require => Class["mailserver::sympa"],
		content => template("mailserver/sympa/sympa_alias.erb"),
	}->
	file {"$sympa_aliases.db":
		ensure => file,
#		owner => $sympa_user,
#		group => $sympa_group,
		mode => "640",
		require => Class["mailserver::sympa"],
	}  


	exec {"$makealiases_cmd $sympa_aliases":
		refreshonly => true,
		subscribe => [
			File["$sympa_conf"],
			File[$sympa_sendmail_aliases]
		],
		require => [
			File[$sympa_conf],
			File[$sympa_sendmail_aliases]
		]
	}	

}


class mailserver::sympa::postfix() inherits mailserver::sympa {
	if $virtual {
		mailserver::service{ "Sympa":
			service => "sympa",
			type => "unix",
			private =>'-',
			unpriv => 'n',
			chroot => 'n',
			wakeup => '-',	
			maxproc => '-',
			command => "pipe",
			args => [
				"flags=hqRu user=sympa argv=$sympa_libexec_dir/queue \${nexthop}",
			]

		}

		mailserver::service{ "SympaBounce":
			service => "sympabounce",
			type => "unix",
			private =>'-',
			unpriv => 'n',
			chroot => 'n',
			wakeup => '-',	
			maxproc => '-',
			command => "pipe",
			args => [
				"flags=hqRu user=sympa argv=$sympa_libexec_dir/bouncequeue \${nexthop}",
			]
		}

		file {"$sympa_dir/list_aliases.tt2":
			ensure => present,
			source => "puppet:///modules/mailserver/sympa_list_aliases.tt2",
			owner => "sympa",
			require => Class["mailserver::sympa"],
		}

		file {"$sympa_transport_sympa":
			ensure => file,
			content => template("mailserver/transport.sympa.erb"),
			require => File["$sympa_conf"]
		}

		exec {"$postmap_cmd $sympa_transport_sympa":
			refreshonly => true,
			subscribe => File["$sympa_transport_sympa"],
			require => [File[$sympa_conf],File[$sympa_transport_sympa]]
		}	

		file {"$sympa_transport":
			ensure => file,
			owner => "sympa",
			group => "sympa",
			require => File["$sympa_conf"]
		}
			
		exec {"$postmap_cmd $sympa_transport":
			refreshonly => true,
			subscribe => File["$sympa_transport"],
			require => [File[$sympa_conf],File[$sympa_transport]]
		}	


	}
	else {
		file {"$sympa_dir/list_aliases.tt2":
			ensure => absent
		}
		file {"$sympa_aliases":
			ensure => file,
			content => template("mailserver/sympa_aliases.erb"),
			require => Class["mailserver::sympa"]
		}
		file {"$sympa_sendmail_aliases":
			ensure => file,
			owner => "sympa",
			group => "sympa",
			require => Class["mailserver::sympa"]
		}
		exec {"$postalias_cmd $sympa_sendmail_aliases":
			refreshonly => true,
			subscribe => File["$sympa_conf"],
			require => [File[$sympa_conf],File[$sympa_sendmail_aliases]]
		}	
		exec {"$postalias_cmd $sympa_aliases":
			refreshonly => true,
			subscribe => File["$sympa_conf"],
			require => [File[$sympa_conf],File[$sympa_aliases]]
		}	
#		$_virtual_sympa_mailbox_maps = ""

	}



}
