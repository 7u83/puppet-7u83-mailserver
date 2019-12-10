# Class: mailserver
# ===========================
#
# Install a mail server using Postfix, Dovecot, Clamav, Opendkim, 
# and extras like Sympa, Rspamd, Sieve and more 
#
# Parameters
# ----------
#
# Document parameters here.
#
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#"
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'mailserver':
#      services => [ 'imap', 'submission' ],
#    }
#
# Authors
# -------
#
# 7u83 <7u83@mail.ru>
#
# Copyright
# ---------
#
# Copyright 2018 7u83.
#
class mailserver (
	$mta = $::mailserver::params::mta,
	$mta_version = 'latest',

	$ldap = false,
	$sasl = false,

	$myhostname = $trusted['hostname'],
	$myorigin = $myhostname,
	$mydestination = [$myhostname],
	$mynetworks = ['127.0.0.1'],

	# 
	# DKIM params
	#
	$dkim_selector = undef,
	$dkim_domains = undef,
	$dkim_keyfile = undef,
	$dkim_keyfile_source = undef,
	$dkim_keyfile_content = undef,

	#
	# DMARC params
	#
	$dmarc_filter = true,

	#
	# SPAM
	#
	$spam_filter = true,
	$spam_reject_score = undef,
	$spam_greylist_score = undef,
	$spam_add_header_score = undef,


	$services = [
		'submission',
		'mx',
	]

) inherits ::mailserver::params {


	if $dkim_selector {
		class {"mailserver::opendkim":
			selector => $dkim_selector,
			domains => $dkim_domains,
			keyfile => $dkim_keyfile,
			keyfile_source => $dkim_keyfile_source,
			keyfile_content => $dkim_keyfile_content,
			mynetworks => $mynetworks,
		}
		$dkim_milter = [$mailserver::opendkim::milter_sock]
		$dkim_groups = [$mailserver::opendkim::gid]
	}
	else {
		$dkim_milter = []
		$dkim_groups = []
	}

	if $dmarc_filter {
		class {"mailserver::opendmarc":
		}
		$dmarc_milter = [$mailserver::opendmarc::milter_socket]
	}
	else {
		$dmarc_filter = []
	}


	if $spam_filter {
		class {"mailserver::rspamd":
			reject_score => $spam_reject_score,
			greylist_score => $spam_greylist_score,
			add_header_score => $spam_add_header_score,
		}
		$spam_milter = [$mailserver::rspamd::milter_socket]
	} 
	else {
		$spam_milter = []
	}
	

	class {"mailserver::clamav":
	}
	$av_milter = [$mailserver::clamav::params::milter_sock]


        $mta_class = "::mailserver::${mta}"
	class{ "$mta_class":
		myhostname => $myhostname,
		mydestination => $mydestination,
		ldap => $ldap,
		sasl => $sasl,
		input_milters => concat ([$dkim_milter],[],[]),
		groups => $dkim_groups,
	}

	if 'submission' in $services {
		class{ "${mta_class}::submission":
			input_milters => concat ($dkim_milter,[],[])
		}	
	}

	if 'smtp' in $services {
		class{ "${mta_class}::mx":
			input_milters => concat ($dkim_milter, $dmarc_milter,$spam_milter,$av_milter,[],[])
		}	
	}


#	$x = inline_template("<%= scope.lookupvar(\"mailserver::${mta}::local_host_names\") %>")
#	notify {"L: $x":}
}
	

