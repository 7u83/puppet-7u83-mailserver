class mailserver::params {
        case $::osfamily {
                'FreeBSD':{
			$sucmd = "/usr/bin/su"

			$etcdir = "/usr/local/etc"


                        $postfix_pkg = 'postfix'
			$postfix_pkg_provider = 'portsng'
			$postfix_main_cf = '/usr/local/etc/postfix/main.cf'
			$postfix_master_cf = '/usr/local/etc/postfix/master.cf'
			$postfix_service = 'postfix'
			$postfix_dir = "/usr/local/etc/postfix"


			$dovecot_service = 'dovecot'
			$dovecot_cfgbasedir = '/usr/local/etc/dovecot'
			$dovecot_cfgconfdir = '/usr/local/etc/dovecot/conf.d'
			$dovecot_deliver = '/usr/local/libexec/dovecot/deliver'


			$alias_database = 'hash:/etc/mail/aliases'
			$alias_maps = 'hash:/etc/mail/aliases'


			$clamav_milter_sock="unix:/var/run/clamav/clmilter.sock"
			$clamav_milter_conf="/usr/local/etc/clamav-milter.conf"
			$clamav_clamd_conf="/usr/local/etc/clamd.conf"

			$clamav_milter_service="clamav-milter"
			$clamav_clamd_service="clamav-clamd"
			$clamav_freshclam_service="clamav-freshclam"
			$clamav_freshclam="/usr/local/bin/freshclam"
			$clamav_freshclam_file="/var/db/clamav/main.cvd"

			package { "portupgrade":
				ensure => installed
			}


			$opendkim_service = "milter-opendkim"
			$opendkim_cfgdir = "/usr/local/etc/mail"
			$opendkim_keysdir = "/usr/local/etc/mail"
			$opendkim_uid='postfix'
			$opendkim_gid='postfix'
			$opendkim_socket='/var/spool/postfix/private/opendkim'
			$opendkim_milter_sock='unix:/var/spool/postfix/private/opendkim'


			$mailman_vardir = "/usr/local/mailman3"
			$mailman_cfg = "/usr/local/etc/mailman.cfg"
			$mailman_shell = "/bin/sh"
			$mailman_dbdir = "/var/db/mailman"
			$mailman_piddir = "/var/run/mailman"
			$mailman_bindir = "/usr/local/bin"
			$mailman_etcdir = "/usr/local/etc"
			$mailman_spooldir = "/var/spool/mailman"
			$mailman_logdir = "/var/log/mailman"
			$mailman_postmap_command = "/usr/local/sbin/postmap"


		}
	}

	$mailman_user = "mailman"
	$mailman_group = "mailman"

	$ssldir = "$etcdir/ssl"
}

