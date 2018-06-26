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
			$postmap_cmd = "/usr/local/sbin/postmap"
			$postalias_cmd = "/usr/local/sbin/postalias"


			$dovecot_service = 'dovecot'
			$dovecot_cfgbasedir = '/usr/local/etc/dovecot'
			$dovecot_cfgconfdir = '/usr/local/etc/dovecot/conf.d'
			$dovecot_deliver = '/usr/local/libexec/dovecot/deliver'
			$dovecot_lda = '/usr/local/libexec/dovecot/dovecot-lda'


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


			$sympa_dir = "/usr/local/etc/sympa"
			$sympa_conf = "/usr/local/etc/sympa/sympa.conf"
			$sympa_aliases = "/usr/local/etc/sympa/sympa_aliases"
			$sympa_sendmail_aliases ="/usr/local/etc/sympa/sympa_sendmail_aliases"

			$sympa_transport = "/usr/local/etc/sympa/sympa_transport"
			$sympa_virtal_sympa = "/usr/local/etc/sympa/virtal.sympa"
			$sympa_transport_sympa = "/usr/local/etc/sympa/transport.sympa"


			$sympa_libexec_dir="/usr/local/libexec/sympa"
			$sympa_static_dir="/usr/local/share/sympa/static"
			$sympa_health_check="/usr/sbin/chown -R sympa /usr/local/share/sympa && /usr/local/bin/sympa.pl --health_check"
			$sympa_service="sympa"
			$sympa_fcgi_program="/usr/local/libexec/sympa/wwsympa.fcgi"
			$sympa_fcgi_socket="/var/run/wwsympa.socket"
			
			$mhonarc_cmd = "/usr/local/bin/mhonarc"
			
			$perl = "/usr/local/bin/perl"
			$spawn_fcgi_service = "spawn-fcgi"

		}
	}

	$mailman_user = "mailman"
	$mailman_group = "mailman"
	$mailman_postmap_command = "$postmap_cmd"

	$ssldir = "$etcdir/ssl"


	$aliasmaps_dir = "$postfix_dir/aliasmaps"
}

