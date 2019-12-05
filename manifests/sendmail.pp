# sendmail

class mailserver::sendmail::params(){
        case $::osfamily {
                'FreeBSD':{
			$service = 'sendmail'
			$etc_mail = '/etc/mail'
			$mail_uid = 'mailnull'
			$mail_gid = 'mailnull'
			$ostype = 'freebsd6'
			$mta_domain = 'generic'
			$submit_domain = 'generic'
		}
		'Debian':{
			$service = 'sendmail'
			$etc_mail = '/etc/mail'
			$ostype = 'debian'
			$mail_uid = 'smmta'
			$mail_gid = 'smmta'
			$mta_domain = 'debian-mta'
			$submit_domain = 'debian-msp'
		}
	}

	$local_host_names = "$etc_mail/local-host-names"
	$sendmail_mc = "$etc_mail/sendmail.mc"
	$sendmail_cf = "$etc_mail/sendmail.cf"
	$submit_mc = "$etc_mail/submit.mc"
	$submit_cf = "$etc_mail/submit.cf"

        case $::osfamily {
                'FreeBSD':{

			file {"/etc/make.conf":
				ensure => file,
			}
			
			file_line {"bsdmakeconf_sendmail":
				ensure => present,
				path => "/etc/make.conf",	
				line => "SENDMAIL_MC=${sendmail_mc}i\t#created by puppet",
				match => "^SENDMAIL_MC.*=",
				require => File["/etc/make.conf"]
			}
			
			file_line {"bsdmakeconf_sendmail_submit":
				ensure => present,
				path => "/etc/make.conf",	
				line => "SENDMAIL_SUBMIT_MC=/etc/mail/submit.mc\t#created by puppet",
				match => "^SENDMAIL_SUBMIT_MC.*=",
				require => File["/etc/make.conf"]
			}
		}
		'Debian':{
		}
	}


}


class mailserver::sendmail(

	$myhostname = $trusted['hostname'],
	$myorigin = $myhostname,
	$mydestination = [$myhostname],

	$ldap = false,
	$sasl = false,
	$input_milters=[],

	$groups = [],
)
inherits mailserver::sendmail::params
{
	class {"mailserver::sendmail::install":
		ldap => $ldap,
		sasl => $sasl
	}

	service{ $service:
		ensure => running,
		require => [
			File[$sendmail_mc],
			File[$submit_mc],
			Anchor["sendmail_installed"],
		],
		subscribe => Anchor["sendmail_installed"],
	}

	$bindir_config = $::mailserver::sendmail::install::bindir_config
	
	file {$sendmail_mc:
		ensure => file,
		content => template("mailserver/sendmail/sendmail.mc.erb"),
	} ->
	exec {"make sendmail.cf":
		command => "${mailserver::sendmail::install::m4_cmd} $sendmail_mc > $sendmail_cf",
		refreshonly => true,
		subscribe => File[$sendmail_mc],
		notify => Service[$service],
	}

	file {$submit_mc:
		ensure => file,
		content => template("mailserver/sendmail/submit.mc.erb"),
	} ->
	exec {"make submit.cf":
		command => "${mailserver::sendmail::install::m4_cmd} $submit_mc > $submit_cf",
		refreshonly => true,
		subscribe => File[$submit_mc],
		notify => Service[$service],
	}

	file{$local_host_names:
		ensure => file,
		content => template("mailserver/sendmail/local-host-names.erb"),
		notify => Service[$service],
	}
	user {"$mail_uid":
		ensure => present,
		groups => $groups,
		require => Anchor["sendmail_installed"]
	}
}

class mailserver::sendmail::install(
	$ldap = false,
	$sasl = false,	
	$ensure = 'latest',
)
{
	$use_bsd_ports = $ldap 
	$use_bsd_package = $sasl
	$use_bsd_local = !($ldap or $sasl)
 
	case $::osfamily {
                'FreeBSD':{
			ensure_resource("file","/usr/local/etc/mail",{
				ensure => directory
			})


			$package = 'sendmail'
#			file {"/usr/local/etc/mail":
#				ensure => directory
#			}

			if $use_bsd_local {
				$m4_cmd = '/usr/bin/m4 -D_CF_DIR_=/usr/share/sendmail/cf/   /usr/share/sendmail/cf/m4/cf.m4'
				# use local
				package {"sendmail":
					ensure => absent,
					notify => Anchor["sendmail_installed"],
				} ->
				file {"sendmail_mailer_conf":
					path => "/usr/local/etc/mail/mailer.conf",
					ensure => absent,
				}->
				file_line {"bsdmakeconf_sendmail_cf":
					ensure => absent,
					path => "/etc/make.conf",	
					line => "SENDMAIL_CF_DIR=/usr/local/share/sendmail/cf\t#created by puppet",
					match => "^SENDMAIL_CF_DIR.*=",
					require => File["/etc/make.conf"]
				}->
				anchor {"sendmail_pkg_installed":}
			}
			else {
				$bindir_config = "define(`confEBINDIR', `/usr/local/libexec')dnl
define(`UUCP_MAILER_PATH', `/usr/local/bin/uux')dnl"
				$m4_cmd = '/usr/bin/m4 -D_CF_DIR_=/usr/local/share/sendmail/cf/   /usr/local/share/sendmail/cf/m4/cf.m4'
				if $use_bsd_ports {
					$package_settings  = {
						'LDAP' => $ldap,
						'SASL' => $sasl,
					}
					$package_provider = 'portsng'
				}
				else {
					$package_settings = undef
					$package_provider = undef
				}

				package {"sendmail":
					ensure => $ensure,
					provider => $package_provider,
					notify => Anchor["sendmail_installed"],
				} ->
				file {"sendmail_mailer_conf":
					path => "/usr/local/etc/mail/mailer.conf",
					ensure => file,
					content => template("mailserver/sendmail/mailer.conf.erb"),
					require => File["/usr/local/etc/mail"],
				}->
				file_line {"bsdmakeconf_sendmail_cf":
					ensure => present,
					path => "/etc/make.conf",	
					line => "SENDMAIL_CF_DIR=/usr/local/share/sendmail/cf\t#created by puppet",
					match => "^SENDMAIL_CF_DIR.*=",
					require => File["/etc/make.conf"]
				}->
				anchor {"sendmail_pkg_installed":}
	
				
			}

			anchor {"sendmail_installed":
				require => Anchor["sendmail_pkg_installed"],
			}

	
		}
		'Debian':{
			$m4_cmd = '/usr/bin/m4 -D_CF_DIR_=/usr/share/sendmail/cf/   /usr/share/sendmail/cf/m4/cf.m4'
			package {"sendmail":
				ensure => present,
				notify => Anchor["sendmail_installed"],
			} ->
			anchor {"sendmail_pkg_installed":
			} 

			anchor {"sendmail_installed":
				require => Anchor["sendmail_pkg_installed"],
			}
		}
	}


}



