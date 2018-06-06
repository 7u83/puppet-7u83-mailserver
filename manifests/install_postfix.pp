
class mailserver::install_postfix(
	$ldap = true
) {
        case $::osfamily {
                'FreeBSD':{

			if $ldap {
				package {"postfix":
					provider => "portsng",
					ensure => 'installed',
					package_settings => {
						'LDAP' => $ldap
					},
					require => Package["portupgrade"]
				}
			}
			else {
				package {"postfix":
					ensure => 'installed'
				}
			}

			file {"/usr/local/etc/mail/mailer.conf":
				ensure => present,
				content => template("mailserver/mailer.conf.erb")
			}

		}
		default: {
                        $postfix_pkg = "postfix"
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
