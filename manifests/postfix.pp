#
#postfix
#
class mailserver::postfix::params(){
        case $::osfamily {
                'FreeBSD':{
			$cfg_dir = "/usr/local/etc/postfix"
			$service = 'postfix'
			$command_directory = "/usr/local/sbin"
			$daemon_directory = "/usr/local/libexec/postfix"
			$data_directory = "/var/db/postfix"
			$meta_directory = " /usr/local/libexec/postfix" 
			$shlib_directory = "/usr/local/lib/postfix"
			$mail_owner = 'postfix'
			$setgid_group = 'maildrop'
		}
		'Debian':{
			$cfg_dir = "/etc/postfix"
			$service = 'postfix'
			$command_directory = "/usr/sbin"
			$daemon_directory = "/usr/lib/postfix/sbin"
			$data_directory = "/var/lib/postfix"
			$meta_directory = "/etc/postfix"
			$shlib_directory = "/usr/lib/postfix"
			$mail_owner = 'postfix'
			$setgid_group = 'postdrop'
		}
	}

	$master_cf = "$cfg_dir/master.cf"
	$main_cf = "$cfg_dir/main.cf"

}



class mailserver::postfix(
	$ldap = false,
	$mysql = false,
	$pgsql = false,
	$sasl = false,

	$input_milters = [],


	$local_userdb = ["passwd"],
	$message_size_limit = 20000000,
	$mailbox_size_limit = 0,

	$ensure = present,
	$version = installed,


	$myhostname = $trusted['hostname'],
	$myorigin = $myhostname,
	$mydestination = [$myhostname],

	$groups = [],

) inherits ::mailserver::postfix::params{

	case $ensure {
		present:{
			$ensure_version = $version
			$ensure_file = file
			$ensure_service = running
		}
		absent: {
			$ensure_version = absent
			$ensure_file = absent
			$ensure_service = stopped
		}
	}


        case $::osfamily {
                'FreeBSD':{
			$packages = 'postfix'

			if $ldap or $mysql {
				$package_settings = {
					'LDAP' => $ldap,
					'MYSQL' => $mysql,
					'PGSQL' => $pgsql,
				}
				$package_provider = "portsng"
				$package_reqquire = Package["portsng"]
			}

			ensure_resource("file","/usr/local/etc/mail",{
				ensure => directory
			})

			package { $packages:
				provider => $package_provider,
				package_settings => $package_settings,
				ensure => $ensure_version,
				require => $package_require
			} ->
			file { "postfix_mailer_conf":
				path => "/usr/local/etc/mail/mailer.conf",
				ensure => $ensure_file,
				content => template("mailserver/mailer.conf.erb"),
				require => File["/usr/local/etc/mail"],
			}
		}
		'Debian': {

                        $packages = "postfix"
			package {"postfix":
                                ensure => $ensure_version
                        }
                        if $ldap {
                                package {'postfix-ldap':
                                        ensure => $ensure_version 
                                }
                        }
			if $mysql {
                                package {'postfix-mysql':
                                        ensure => $ensure_version
                                }
			}
			if $pgsql {
                                package {'postfix-pgsql':
                                        ensure => $ensure_version
                                }
			}
#                        package {"maildrop":
#                                ensure => 'installed'
#                        }
#
 
		}
	}


	$non_smtpd_milters = concat ($input_milters,"'")[0]

	concat { "$master_cf": 
		ensure => $ensure,
		require => [
			Package[$apckages]
#			Class["mailserver::postfix"],
#			Class["mailserver::clamav"]
		]
	}

	concat::fragment { "$master_cf header":
		target => "$master_cf",
		order => '00',
		content => template('mailserver/postfix/master.cf.header.erb'),
	}

	if $ensure != absent {
		service { "$service":
			ensure => $ensure_service,
			require => Concat["$master_cf"],
			subscribe => [
				Concat["$master_cf"],

			], 
		}
	}

	file { "$main_cf":
		ensure => $ensure,
		content => template("mailserver/postfix/main.cf.erb"),
		require => [
			Package[$packages]
		],
		notify => Service[$service],
	}

	user {"$mail_owner":
		ensure => present,
		groups => $groups,
		require => Package[$packages]
	}


	mailserver::postfix::service{"smtp-service":
		service => smtp,
		command => smtp,
		type => unix,
		private => "-",
		args => [
	#		"{ -o non_smtpd_milters = $smtpd_milters }",
		] 

		
	}

}

define mailserver::postfix::service(
	$service,
	$type = 'inet',
	$private = 'n',
	$unpriv = '-',
	$chroot = 'n',
	$wakeup = '-',
	$maxproc = '-',
	$command, 
	$args = [],
){
	concat::fragment  { "$title":
		target => "$::mailserver::postfix::params::master_cf",
		content => template("mailserver/postfix/master.cf.service.erb");
	}	
}


