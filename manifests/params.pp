#params

class mailserver::params {
        case $::osfamily {
                'FreeBSD':{
			$mta = 'sendmail'
		}
		'Debian': {
			$mta = 'postfix'
		}
	}

}

