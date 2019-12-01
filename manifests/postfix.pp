#postfix
#
class mailserver::postfix::params(){
}



class mailserver::postfix(
	$ldap = true,
	$mysql = false,

) inherits ::mailserver::postfix::params{
        case $::osfamily {
                'FreeBSD':{

			if $ldap {
				package {"postfix":
					provider => "portsng",
					ensure => 'installed',
					package_settings => {
						'LDAP' => $ldap,
						'MYSQL' => $mysql,
					},
					require => Package["portupgrade"]
				}
			}
			else {
				package {"postfix":
					ensure => 'installed'
				}
			}

#			ensure_resource("file","/usr/local/etc/mail",{
#				ensure => directory
#			})

			file {"/usr/local/etc/mail/mailer.conf":
				ensure => present,
				content => template("mailserver/mailer.conf.erb")
			}

		}
		default: {
                        $postfix_pkg = "postfix"
#                        package {"maildrop":
#                                ensure => 'installed'
#                        }

                        package {"postfix":
                                ensure => 'installed'
                        }
                        if $ldap {
                                package {'postfix-ldap':
                                        ensure => 'installed'
                                }
                        }
		}
	}


}
