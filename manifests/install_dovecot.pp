#
#
class mailserver::install_dovecot(
	$solr = true,
	$lucene = false,
	$protocols = "",
	$listen = "",
	$mail_location, 

	$ldap = false,
	$ldap_auth_bind,
	$ldap_base,
	$ldap_pass_filter,
	$ldap_user_filter,
	$ldap_hosts,
	$ldap_dn,
	$ldap_pass,

	$disable_plaintext_auth,
	$auth_system,

	$imap_ssl = true,
	$imap_sslkey,
	$imap_sslcert,



) inherits mailserver::params {
	$dovecot_ldap_hosts = join($ldap_hosts," ")

        case $::osfamily {
                'FreeBSD':{

			package {"dovecot":
				provider => "portsng",
				ensure => 'latest',
				package_settings => {
					'LDAP' => $ldap,
					'SOLR' => $solr,
					'LUCENE' => $lucene
				},
				require => Package["portupgrade"]
			}
		}
		default: {
                        $postfix_pkg = "dovecot"
#                        package {"postfix":
#                                ensure => 'installed'
#                        }
#                        if $ldap {
#                                package {'postfix-ldap':
#                                        ensure => 'installed'
 #                               }
 #                       }
		}
	}


	file { "$dovecot_cfgbasedir":
		ensure => directory
	}

	file { "$dovecot_cfgconfdir":
		ensure => directory,
		require => File[ $dovecot_cfgbasedir ]
	}

	file { "$dovecot_cfgbasedir/dovecot.conf":
		ensure => file,
		content => template('mailserver/dovecot/dovecot.conf.erb'),
		require => File["$dovecot_cfgbasedir"],
	}
	
	$cfgfiles = [
		"conf.d/10-master.conf",
		"conf.d/10-mail.conf",
		"conf.d/10-auth.conf",
		"conf.d/10-ssl.conf",
		"conf.d/20-imap.conf",
		"dovecot-ldap.conf.ext",
		"conf.d/auth-system.conf.ext",
		"conf.d/auth-ldap.conf.ext",
	]

	$cfgfiles.each | String $file | {
		file { "$dovecot_cfgbasedir/$file":
			ensure => file,
			content => template("mailserver/dovecot/$file.erb"),
			require => File["$dovecot_cfgconfdir"],
		}
	}


	exec  {"/usr/bin/openssl dhparam -out /usr/local/etc/dovecot/dh.pem 2048":
		creates => "/usr/local/etc/dovecot/dh.pem",
		require => File["$dovecot_cfgbasedir"],
	}

}




