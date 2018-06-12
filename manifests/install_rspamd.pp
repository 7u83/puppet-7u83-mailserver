
class mailserver::install_rspamd()
inherits mailserver::params
{
        case $::osfamily {
                'FreeBSD':{

			package {"dovecot":
				provider => "portsng",
				ensure => 'installed',
				package_settings => {
					'LDAP' => $ldap,
					'SOLR' => $solr,
					'LUCENE' => $lucene
				},
				require => Package["portupgrade"]
			}
		}
	}	
}
