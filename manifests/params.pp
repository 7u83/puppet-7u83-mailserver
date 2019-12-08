#params

class mailserver::params {
        case $::osfamily {
                'FreeBSD':{
			$mta = 'sendmail'
			$saslauthd = 'cyrus::saslauthd'
			$imapd = 'uwimap'
		}
		'Debian': {
			$mta = 'postfix'
			$saslauthd = 'cyrus::saslauthd'
			$imapd = 'uwimapd'
		}
	}

}

