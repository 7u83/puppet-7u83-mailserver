# Class: mailserver
# ===========================
#
# Full description of class mailserver here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
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
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2018 Your name here, unless otherwise noted.
#
class mailserver (
	$ldap = true,
	$ldap_auth_bind="no",
	$ldap_base="",
	$ldap_pass_filter="(&(objectClass=posixAccount)(uid=%u))",
	$ldap_user_filter="(&(objectClass=posixAccount)(uid=%u))",
	$ldap_login_maps_query=undef,
	$ldap_login_maps_result_attribute=undef,
	$ldap_hosts = [],
	$ldap_dn = undef,
	$ldap_pass = undef,


	$mail_location = "mbox",

	$myhostname ,
	$mydestination = [],
	$myorigin = undef,
	$mynetworks = ["127.0.0.1/32"],


	$clamav_infected_action = "Reject",
	$solr = false,
	$lucene=false,

	$dovecot_protocols = "",
	$dovecot_listen = "*",
	
	$imap = true,
	$pop3 = true,
	$impas = true,
	$smtp = true,
	
	$disable_plaintext_auth = true,


	$auth_system = true,

	$smtpd_hostname = undef,
	$smtpd_sslcert = undef,
	$smtpd_sslkey = undef,

	$imap_hostname = undef,
	$imap_sslcert = undef,
	$imap_sslkey = undef,



	$sslcert_src = "puppet:///ssl",	


	$dkim_selector = undef,
	$dkim_domains = undef,
	$dkim_source = "puppet:///dkim",

	$mailman = false,
	$mailman_remove_dkim = false,


	$mailbox_size_limit = 0,

) inherits mailserver::params {

	$pfmydestination = join($mydestination," ")
	$pfmynetworks = join($mynetworks," ")

	if $mailman == true {
		ensure_resource ("class","mailserver::install_postfix",{
			ldap  => $ldap
		})
		Class["mailserver::install_mailman3"] -> Class["mailserver::mailman_service"] 

		class {"mailserver::install_mailman3":
			remove_dkim => $mailman_remove_dkim
		}
		class {"mailserver::mailman_service":}
		$mailman_local_maps = "hash:$mailman_vardir/data/postfix_lmtp"
	}
	

	$_myorigin = $myorigin ? {
		undef => $myhostname,
		default => $myorigin,
	}

	if $dkim_selector != undef {
		ensure_resource ("class","mailserver::install_postfix",{
			ldap  => $ldap
		})
		if $dkim_domains == undef {
			$_dkim_domains = $myorigin
		}
		else {
			$_dkim_domains = $dkim_domains
		}

		class {"mailserver::install_opendkim":
			selector => $dkim_selector,
			domains => $_dkim_domains,

			dkim_source => $dkim_source,
			mynetworks => $mynetworks
		}
		service {"$opendkim_service":
			ensure => "running",
			subscribe => Class["mailserver::install_opendkim"]
		}

	}



	$_imap_hostname = $imap_hostname ? {
		undef => $myhostname,
		default => $imap_hostname,
	}

	if $imap_sslcert == undef {
		$_imap_sslcert  = "$ssldir/$_imap_hostname/fullchain.pem"
		$imap_sslcert_src = $sslcert_src
	}
	else {
		$_imap_sslcert  = $imap_sslcert
		$imap_sslcert_src = undef
	}
	
	if $imap_sslkey == undef {
		$_imap_sslkey  = "$ssldir/$_imap_hostname/privkey.pem"
		$imap_sslkey_src = $sslcert_src
	}
	else {
		$_imap_sslcert  = $imap_sslcert
		$imap_sslkey_src = undef
	}
	
	if $imap_sslcert_src != undef {
		ensure_resource ("mailserver::copyfile","fullchain.pem",{
			path => "$ssldir/$_imap_hostname",
			source => "$imap_sslcert_src/$_imap_hostname",
		})
	}
	if $imap_sslkey_src != undef {
		ensure_resource ("mailserver::copyfile","privkey.pem",{
			path => "$ssldir/$_imap_hostname",
			source => "$imap_sslcert_src/$_imap_hostname",
		})
	}




	$_smtpd_hostname = $smtpd_hostname ? {
		undef => $myhostname,
		default => $smtpd_hostname,
	}

	if $smtpd_sslcert == undef {
		$_smtpd_sslcert  = "$ssldir/$_smtpd_hostname/fullchain.pem"
		$smtpd_sslcert_src = $sslcert_src
	}
	else {
		$_smtpd_sslcert  = $smtpd_sslcert
		$smtpd_sslcert_src = undef
	}
	
	if $smtpd_sslkey == undef {
		$_smtpd_sslkey  = "$ssldir/$_smtpd_hostname/privkey.pem"
		$smtpd_sslkey_src = $sslcert_src
	}
	else {
		$_smtpd_sslcert  = $smtpd_sslcert
		$smtpd_sslkey_src = undef
	}
	
	if $smtpd_sslcert_src != undef {
		ensure_resource("mailserver::copyfile","fullchain.pem",{
			path => "$ssldir/$_smtpd_hostname",
			source => "$smtpd_sslcert_src/$_smtpd_hostname",
		})
	}
	if $smtpd_sslkey_src != undef {
		ensure_resource ("mailserver::copyfile", "privkey.pem",{
			path => "$ssldir/$_smtpd_hostname",
			source => "$smtpd_sslcert_src/$_smtpd_hostname",
		})
	}


#	notify {"$_smtpd_sslkey":}












	if $mail_location == "mbox" {
		$dovecot_mail_location = "mbox:~/mail:LAYOUT=maildir++:INBOX=/var/mail/%u:INDEX=~/mail/index:CONTROL=~/mail/control"
	}elsif $mail_location == "maildir" {
		$dovecot_mail_location = "maildir:~/Mail"
	}else {
		$dovecot_mail_location = $mail_location
	}

	$non_smtpd_milters = join([
		$clamav_milter_sock,
		$opendkim_milter_sock,
	]," ")


		
#	class {"mailserver::install_postfix":
#		ldap => $ldap
#	}
	ensure_resource ("class","mailserver::install_postfix",{
		ldap  => $ldap
	})

	class {"mailserver::install_clamav":
		ldap => $ldap
	}


	class {"mailserver::install_dovecot":
		ldap=>$ldap,
		ldap_base => $ldap_base,
		ldap_pass_filter => $ldap_pass_filter,
		ldap_user_filter => $ldap_user_filter,
		ldap_auth_bind => $ldap_auth_bind,
		ldap_dn => $ldap_dn,
		ldap_pass => $ldap_pass,
		ldap_hosts => $ldap_hosts,

		solr=>$solr,
		lucene => $lucene,
		protocols => $dovecot_protocols,
		listen => $dovecot_listen, 
		mail_location => $dovecot_mail_location,
		disable_plaintext_auth => $disable_plaintext_auth,

		auth_system => $auth_system,

		imap_sslcert => $_imap_sslcert,
		imap_sslkey => $_imap_sslkey,


	}

	file { "$clamav_milter_conf":
		ensure => present,
		content => template("mailserver/clamav-milter.conf.erb"),
		require => Class["mailserver::install_clamav"]
	}

	exec {"$clamav_freshclam":
		creates => "$clamav_freshclam_file",
		timeout => 600,
	}
	
	service {"$clamav_clamd_service":
		ensure => running,
		require => [
			Class["mailserver::install_clamav"],
			Exec["$clamav_freshclam"],
		]
	}

	service {"$clamav_freshclam_service":
		ensure => running,
		require => [
			Service["$clamav_clamd_service"]
		], 
	}


	service {"$clamav_milter_service":
		ensure => running,
		require => [
			Service["$clamav_clamd_service"]
		],
		subscribe => File["$clamav_milter_conf"],
	}


	file { "$postfix_main_cf":
		ensure => present,
		content => template("mailserver/postfix-main.conf.erb"),
		require => [
			Class["mailserver::install_postfix"]
		]
	}

	service { "$postfix_service":
		ensure => running,
		require => Concat["$postfix_master_cf"],
		subscribe => [Concat["$postfix_master_cf"], File["$postfix_main_cf"]]
		
	}

	concat { "$postfix_master_cf": 
		ensure => present,
		require => [
			Class["mailserver::install_postfix"],
			Class["mailserver::install_clamav"]
		]
	}

	concat::fragment { "$postfix_master_cf header":
		target => "$postfix_master_cf",
		order => '00',
		content => template('mailserver/postfix-master-header.conf.erb'),
	}

	mailserver::postfix_ldapmap{ "ldap_login_maps.cf":
		query_filter => $ldap_login_maps_query,
		result_attribute => $ldap_login_maps_result_attribute
			
	}


	service {"$dovecot_service":
		ensure => running,
		require => Class["mailserver::install_dovecot"],
		subscribe => Class["mailserver::install_dovecot"],

	}

#	mailserver::install_sslcert {"$myhostname":
#		owner => postfix
#	}

	


}	

define mailserver::copyfile(
	$source,
	$path ,
	
)
{
	exec { "mkdir $path for $title":
		command => "/bin/mkdir -p $path",
		creates => "$path"
	}

	file { "$path/$title":
		ensure => file,
		source => "$source/$title",
		require => Exec["mkdir $path for $title"],
	} 
}

define mailserver::install_sslcert (
	$source=undef,
	$owner,
) 
{
	$etcdir = $::mailserver::params::etcdir

	if $source == undef {
		$chainsource = "puppet:///ssl/$title/fullchain.pem"
		$keysource = "puppet:///ssl/$title/privkey.pem"
	}
	else {
		$chainsource = "$source/$title/fullchain.pem"
		$keysource = "$source/$title/privkey.pem"
	}


	file  {"$etcdir/ssl":
		ensure => directory
	}

	file {"$etcdir/ssl/$title":
		ensure => directory,
		require => File["$etcdir/ssl"]
	}

	file {"$etcdir/ssl/$title/fullchain.pem":
		ensure => present,
		source => $chainsource,
		require => File["$etcdir/ssl/$title"],
	}

	file {"$etcdir/ssl/$title/privkey.pem":
		ensure => present,
		source => $keysource,
		require => File["$etcdir/ssl/$title"],
	}

}



define mailserver::service(
	$service,
	$type = 'inet',
	$private = 'n',
	$unpriv = '-',
	$chroot = 'n',
	$wakeup = '-',
	$maxproc = '-',
	$command, 
	$args = [],
){
	concat::fragment  { "$title":
		target => "$::mailserver::params::postfix_master_cf",
		content => template("mailserver/postfix-master-service.conf.erb");
	}	
}


define mailserver::postfix_ldapmap(
	$query_filter,
	$result_attribute
){
	$xldap_hosts = join($mailserver::ldap_hosts," ")
	file {"$::mailserver::params::postfix_dir/$title":
		ensure => present,
		content => "bind=yes
bind_dn=$::mailserver::ldap_dn
bind_pw=$::mailserver::ldap_pass
search_base_pw=$::mailserver::ldap_base
server_host=$xldap_hosts
version=3
query_filter=$query_filter
result_attribute=$result_attribute
"
	}
}


class mailserver::mx(
	$hostname,
	$rbls = [],

	$client_restrictions = [
		"permit_mynetworks",
		"reject_unknown_reverse_client_hostname",
		"reject_unauth_pipelining"
	],
	$recipient_restrictions = [
		"permit_mynetworks",
		"reject_unauth_destination"
	],
	$helo_restrictions = [
		"permit_mynetworks",
		"reject_invalid_hostname",
		"reject_unknown_hostname",
		"reject_non_fqdn_hostname",
	],
	$relay_restrictions = [
		"permit_mynetworks",
		"defer_unauth_destination"
	],

	$milters = [],

	$mynetworks = [],

	$postscreen = false


)inherits mailserver::params{

	$pfrbls = join ( $rbls.map|$elem|{ "reject_rbl_client $elem"} , " ") 

	$pfclient_restrictions = join($client_restrictions," ")
	$pfrecipient_restrictions = join($recipient_restrictions," ")
	$pfhelo_restrictions = join($helo_restrictions, " ")
	$pfrelay_restrictions =  join($relay_restrictions, " ")

	$pflmilters = join([
		$clamav_milter_sock,
		$opendkim_milter_sock,
	]," ")

	$pfmilters = join($milters," ")
	$pfmynetworks = join($mynetworks," ")


	if $postscreen {
		mailserver::service{ "Postscrren server for $hostname":
			service => 'smtp',
			command => 'postscreen',
			maxproc => 1,
			args => [],
		}

		$chroot = '-'
		$private = '-'
		$service = 'smtpd'
		$type = 'pass'

	}
	else {
		$chroot = 'n'
		$private = 'n'
		$service = 'smtp'
		$type = 'inet'
	}
	

	mailserver::service{ "MX server for $hostname":
		service => $service,
		command => 'smtpd',
		type => $type,
		private => $private,
		chroot => $chroot,
		args => [
			"{ -o smtpd_recipient_restrictions = $pfrecipient_restrictions $pfrbls }",
			"{ -o smtpd_client_restrictions = $pfclient_restrictions }",
			"{ -o smtpd_helo_restrictions = $pfhelo_restrictions }",
			"{ -o smtpd_relay_restrictions = $pfrelay_restrictions }",
			"{ -o smtpd_milters = $pflmilters $pfmilters}",
			"{ -o smtpd_sasl_auth_enable = no }",
		]

	}


}





class mailserver::submission(
	$hostname,
	$rbls = [],

	$client_restrictions = [
		"permit_sasl_authenticated",
		"reject"
	],
	$recipient_restrictions = [
		"reject_unknown_recipient_domain",
		"permit_sasl_authenticated",
		"reject",
	],
	$helo_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$relay_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$sender_restrictions = [
		"reject_authenticated_sender_login_mismatch",
		"permit_sasl_authenticated",
		"reject",
	],


	$milters = [],

	$mynetworks = [],

	$ldap_login_map =[],

	$tls_security = 'encrypt',

	$verify_recipient = false


)inherits mailserver::params{

	$pfclient_restrictions = join($client_restrictions," ")

	if $verify_recipient {
		$_reject_unverified_recipient = "reject_unverified_recipient"
	}
	
	$pfrecipient_restrictions = join(
			concat($recipient_restrictions,$_reject_unverified_recipient),
			" ")



	$pfhelo_restrictions = join($helo_restrictions, " ")
	$pfrelay_restrictions =  join($relay_restrictions, " ")
	$pfsender_restrictions = join($sender_restrictions, " ")

	$pflmilters = join([
		$clamav_milter_sock,
		$opendkim_milter_sock,
	]," ")

	$pfmilters = join($milters," ")
#	$pfmynetworks = join($mynetworks," ")

	$kf = $::mailserver::_smtpd_sslkey

	$ssl_options ="{ -o smtpd_tls_security_level = $tls_security }
	{ -o smtp_tls_note_starttls_offer = yes }
	{ -o smtpd_tls_key_file = $kf }
	{ -o smtpd_tls_cert_file = $::mailserver::_smtpd_sslcert }
	{ -o smtpd_tls_loglevel = 1 }
	{ -o smtpd_tls_received_header = yes }
	{ -o smtpd_tls_session_cache_timeout = 3600s }"

	mailserver::service{ "Subimission server for $hostname":
		service => 'submission',
		command => 'smtpd',
		args => [
			"{ -o smtpd_sender_restrictions = $pfsender_restrictions $kf }",
			"{ -o smtpd_recipient_restrictions = $pfrecipient_restrictions }",
			"{ -o smtpd_client_restrictions = $pfclient_restrictions }",
			"{ -o smtpd_helo_restrictions = $pfhelo_restrictions }",
			"{ -o smtpd_relay_restrictions = $pfrelay_restrictions }",
			"{ -o smtpd_milters = $pflmilters $pfmilters}",
			"{ -o smtpd_sasl_auth_enable = yes }",
			"{ -o smtpd_sasl_type = dovecot }",
			"{ -o smtpd_sasl_path = /var/spool/postfix/private/auth }",
			"$ssl_options",
		]
	}
}
