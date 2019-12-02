#params

class mailserver::params {
        case $::osfamily {
                'FreeBSD':{
			$mailserver = 'postfix'
		}
		default: {
			$mailserver = 'postfix'
		}
	}

}

