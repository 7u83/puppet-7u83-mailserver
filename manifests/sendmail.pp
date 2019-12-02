# sendmail

class mailserver::sendmail::params(){
        case $::osfamily {
                'FreeBSD':{
			$service = 'sendmail'
			$etc_mail = '/etc/mail'
			$m4_cmd = '/usr/bin/m4 -D_CF_DIR_=/usr/share/sendmail/cf/   /usr/share/sendmail/cf/m4/cf.m4'
		}
		'Debian':{
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

)
inherits mailserver::sendmail::params
{
	class {"mailserver::postfix":
		ensure => absent
	}

	service{ $service:
		ensure => running,
		require => [
			File[$sendmail_mc],
			File[$submit_mc],
		]
	}

	
	file {$sendmail_mc:
		ensure => file,
		content => template("mailserver/sendmail/sendmail.mc.erb"),
	} ->
	exec {"make sendmail.cf":
		command => "$m4_cmd $sendmail_mc > $sendmail_cf",
		refreshonly => true,
		subscribe => File[$sendmail_mc],
		notify => Service[$service],
	}

	file {$submit_mc:
		ensure => file,
		content => template("mailserver/sendmail/submit.mc.erb"),
	} ->
	exec {"make submit.cf":
		command => "$m4_cmd $submit_mc > $submit_cf",
		refreshonly => true,
		subscribe => File[$sendmail_mc],
		notify => Service[$service],
	}

	file{$local_host_names:
		ensure => file,
		content => template("mailserver/sendmail/local-host-names.erb"),
		notify => Service[$service],
	}

}



