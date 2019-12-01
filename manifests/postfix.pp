#postfix
#
class mailserver::postfix::params(){

}



class mailserver::postfix(
	$ldap = false,
	$mysql = false,
	$pgsql = false,

) inherits ::mailserver::postfix::params{

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
				ensure => installed,
				require => $package_require
			} ->
			file {"/usr/local/etc/mail/mailer.conf":
				ensure => present,
				content => template("mailserver/mailer.conf.erb")
			}
		}
		'Debian': {

                        $packages = "postfix"
			package {"postfix":
                                ensure => 'installed'
                        }
                        if $ldap {
                                package {'postfix-ldap':
                                        ensure => 'installed'
                                }
                        }
			if $mysql {
                                package {'postfix-mysql':
                                        ensure => 'installed'
                                }
			}
			if $pgsql {
                                package {'postfix-pgsql':
                                        ensure => 'installed'
                                }
			}
#                        package {"maildrop":
#                                ensure => 'installed'
#                        }
#
 
		}
	}

}
