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
	$localhost = "127.0.0.1",

	$ldap = false,
	$ldap_auth_bind="no",
	$ldap_base="",

	$ldap_pass_filter="(&(objectClass=posixAccount)(uid=%u))",
	$ldap_user_filter="(&(objectClass=posixAccount)(uid=%u))",


	$ldap_lmtp_user_filter=undef,
	$ldap_login_maps_query=undef,
	$ldap_login_maps_result_attribute=undef,
	$ldap_hosts = [],
	$ldap_dn = undef,
	$ldap_pass = undef,

	$ldap_uid_attrib = "uid",
	$ldap_homedir_attrib = "homeDirectory",


	$vmail_user="vmail", 
	$vmail_group="vmail",


	$mail_location = "mbox",

	$myhostname ,
	$mydestination = undef,
	$myorigin = undef,
	$mynetworks = ["127.0.0.1/32"],


	$clamav_infected_action = "Reject",
	$solr = false,
	$lucene=false,

	$dovecot_listen = "*",
	
	$imap = true,
	$pop3 = true,
	$impas = true,
	$smtp = true,
	

	$auth_system = true,

	#
	# SSL 
	#
	$smtp_hostname = undef,
	$smtp_sslcert = undef,
	$smtp_sslkey = undef,

	$submission_hostname = undef,
	$submission_sslcert = undef,
	$submission_sslkey = undef,

	$imap_hostname = undef,
	$imap_sslcert = undef,
	$imap_sslkey = undef,

	$sslcert_src = "puppet:///ssl",	

	# 
	# DKIM params
	#
	$dkim_selector = undef,
	$dkim_domains = undef,
	$dkim_source = "puppet:///dkim",



	#
	# Sympa parameters
	#
	$sympa_db_host = false,
	$sympa_db_name = "sympa",
	$sympa_db_user = "sympa",
	$sympa_db_passwd = "sympa",
	$sympa_fcgi_addr = false,
	$sympa_fcgi_port = "9000",
	$sympa_web_location = "/sympa",
	$sympa_static_web_location = "/static-sympa",

	$lists_listmaster = undef,
	$lists_url = undef,
	$lists_dmarc_protection_mode = "reject",


	$mailbox_size_limit = 0,



	$virtual_mailbox_domains = [],
	$virtual_mailbox_base = "/",
	

	$services = ["smtp"],

	$tls_security = "encrypt",



	#
	# SMTP parameters + defaults
	#
	$submission_verify_recipient = false,
	$smtp_rbls = [],
	$smtp_client_restrictions = [
		"permit_mynetworks",
		"reject_unknown_reverse_client_hostname",
		"reject_unauth_pipelining"
	],
	$smtp_recipient_restrictions = [
		"permit_mynetworks",
		"reject_unlisted_recipient",
		"reject_unauth_destination",
		"reject_unknown_recipient_domain",
	],
	$smtp_helo_restrictions = [
		"permit_mynetworks",
		"reject_invalid_hostname",
		"reject_unknown_hostname",
		"reject_non_fqdn_hostname",
	],
	$smtp_relay_restrictions = [
		"permit_mynetworks",
		"defer_unauth_destination"
	],
	$smtp_milters = [],
	$smtp_postscreen = false,
	$smtp_postscreen_rbls = undef,



	#
	# Submission parameters + defaults
	#

	$submission_rbls = [],
	$submission_client_restrictions = [
		"permit_sasl_authenticated",
		"reject"
	],
	$submission_recipient_restrictions = [
		"reject_unknown_recipient_domain",
		"permit_sasl_authenticated",
		"reject",
	],
	$submission_helo_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$submission_relay_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$submission_sender_restrictions = [
		"reject_authenticated_sender_login_mismatch",
		"permit_sasl_authenticated",
		"reject",
	],

	$submission_milters = [],
	$submission_mynetworks = [],




) inherits mailserver::params {


	# ----------------------------------------------------------------
	# Basic setup
	#

	$_myorigin = $myorigin ? {
		undef => $myhostname,
		default => $myorigin,
	}

	$_mydestination = $mydestination ? {
		undef => $_myorigin,
		default => join($mydestination," ")
	}

	$_imap_hostname = $imap_hostname ? {
		undef => $myhostname,
		default => $imap_hostname,
	}

	$_smtp_hostname = $smtp_hostname ? {
		undef => $myhostname,
		default => $smtp_hostname,
	}

	$_submission_hostname = $submission_hostname ? {
		undef => $myhostname,
		default => $submission_hostname,
	}


	$_mynetworks = join($mynetworks," ")


	$dovecot_services = concat ( intersection (["imap","pop3","imaps","pop3s","managesieve"],$services), "lmtp" )


	if $smtp_postscreen { 
		if $smtp_postscreen_rbls == undef {
			$_postscreen_rbls = join ( $smtp_rbls , " ") 
		}
		else {
			$_postscreen_rbls = $smtp_postscreen_rbls
		}
	}
	else{
		$_postscreen_rbls = undef
	}
	


	# ----------------------------------------------------------------
	# Virtual setup
	#

	
	$_virtual_mailbox_domains = join($virtual_mailbox_domains," ")

	if $virtual_mailbox_domains != [] {
		user {"$vmail_user":
			ensure => present,
			uid => "400",
		}

		group {"$vmail_group":
			ensure => present,
			gid => "400",
		}
	}





	# ----------------------------------------------------------------
	# SSL setup
	#
	
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

	if $smtpd_sslcert == undef {
		$_smtpd_sslcert  = "$ssldir/$_smtp_hostname/fullchain.pem"
		$smtpd_sslcert_src = $sslcert_src
	}
	else {
		$_smtpd_sslcert  = $smtpd_sslcert
		$smtpd_sslcert_src = undef
	}
	
	if $smtpd_sslkey == undef {
		$_smtpd_sslkey  = "$ssldir/$_smtp_hostname/privkey.pem"
		$smtpd_sslkey_src = $sslcert_src
	}
	else {
		$_smtpd_sslcert  = $smtpd_sslcert
		$smtpd_sslkey_src = undef
	}
	
	if $smtpd_sslcert_src != undef {
		ensure_resource("mailserver::copyfile","fullchain.pem",{
			path => "$ssldir/$_smtp_hostname",
			source => "$smtpd_sslcert_src/$_smtp_hostname",
		})
	}
	if $smtpd_sslkey_src != undef {
		ensure_resource ("mailserver::copyfile", "privkey.pem",{
			path => "$ssldir/$_smtp_hostname",
			source => "$smtpd_sslcert_src/$_smtp_hostname",
		})
	}



	# ----------------------------------------------------------------
	# DKIM Setup
	#

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
			subscribe => Class["mailserver::install_opendkim"],
			require => Class["mailserver::install_postfix"],
		}

	}


	# ----------------------------------------------------------------
	# SMTP Server
	#



	if $ldap_lmtp_user_filter != undef {
		$_ldap_lmtp_user_filter = $ldap_lmtp_user_filter
	}
	else{
		$_ldap_lmtp_user_filter = $ldap_user_filter
	}






	if $ldap {
		$_virtual_mailbox_maps = "ldap:$postfix_dir/ldap_login_maps.cf"
	}






	# ----------------------------------------------------------------
	# SMTP Server
	#

	if "smtp" in $services {
		ensure_resource ("class","mailserver::install_postfix",{
			ldap  => $ldap
		})

		class {"mailserver::mx":
			rbls => $smtp_rbls,
			client_restrictions => $smtp_client_restrictions,
			recipient_restrictions => $smtp_recipient_restrictions,
			helo_restrictions =>  $smtp_helo_restrictions ,
			relay_restrictions => 	$smtp_relay_restrictions,
			milters => $smtp_milters,
			postscreen => $smtp_postscreen,
		}
	}


	# ----------------------------------------------------------------
	# Suubmission Server
	#
	if "submission" in $services {	
		ensure_resource ("class","mailserver::install_postfix",{
			ldap  => $ldap
		})
		if $ldap {
			$sender_login_maps = [
				"ldap:$postfix_dir/ldap_login_maps.cf"
			]
		}
		class {"mailserver::submission":
			sender_login_maps => $sender_login_maps,
			verify_recipient => $submission_verify_recipient,
			rbls => $submission_rbls,
			client_restrictions => $submission_client_restrictions,
			recipient_restrictions => $submission_recipient_restrictions,
			helo_restrictions => $submission_helo_restrictions,
			relay_restrictions => $submission_relay_restrictions,
			sender_restrictions => $submission_sender_restrictions,
			milters => $submission_milter,
		}
	}





	# ----------------------------------------------------------------
	# Sympa 
	#

	if "sympa" in $services {
		$sympa = true

		if $sympa_db_host == false {
			$_sympa_db_host = "$localhost"
			include '::mysql::server'
#			class { '::mysql::server': }
			mysql::db { "$sympa_db_name":
				user     => "$sympa_db_user",
				password => "$sympa_db_passwd",
				host     => "$localhost",
				grant    => ['ALL'],
			}
		} 
		else {
			$_sympa_db_host = $sympa_db_host
		}

		class {"mailserver::install_sympa":}


		$sympa_domain = $_myorigin
		$sympa_url = $lists_url
		$sympa_dmarc_protection_mode = $lists_dmarc_protection_mode ? {
			"reject" => "dmarc_reject",
			default => "dmarc_accept",
		}

		$sympa_listmaster = $lists_listmaster

		file {"$sympa_conf":
			ensure => file,
			content => template("mailserver/sympa.conf.erb"),
			require => Class["mailserver::install_sympa"],
			owner => "sympa",
		}
		
		file {"$sympa_dir":
			ensure => directory,
			owner => "sympa",
			require => Class["mailserver::install_sympa"]
		}

		file {"$sympa_aliases":
			ensure => file,
			content => template("mailserver/sympa_aliases.erb"),
			require => Class["mailserver::install_sympa"]
		}
		file {"$sympa_sendmail_aliases":
			ensure => file,
			owner => "sympa",
			group => "sympa",
			require => Class["mailserver::install_sympa"]
		}

		service {"$sympa_service":
			ensure => "running",
			require => [Class["mailserver::install_sympa"],File["$sympa_conf"]],
			subscribe => [Class["mailserver::install_sympa"],File["$sympa_conf"]],
		}	

		exec {"$postalias_cmd $sympa_sendmail_aliases":
			refreshonly => true,
			subscribe => File["$sympa_conf"],
			require => [File[$sympa_conf],File[$sympa_sendmail_aliases]]
		}	
		exec {"$postalias_cmd $sympa_aliases":
			refreshonly => true,
			subscribe => File["$sympa_conf"],
			require => [File[$sympa_conf],File[$sympa_aliases]]
		}	


		if $sympa_db_host == false {
			exec {"$sympa_health_check":
				refreshonly => true,
				subscribe => File["$sympa_conf"],
				require => Mysql::Db[$sympa_db_name],
			}
		}
		else {
			exec {"$sympa_health_check":
				refreshonly => true,
				subscribe => File["$sympa_conf"],
			}
		}

		if $sympa_fcgi_addr == false {
			$_sympa_fcgi_addr = "127.0.0.1"
			class {"nginx":
			}

			nginx::resource::server {"sympa_web":
				listen_port => 80,
				ensure => present
			}
			nginx::resource::location {"sympa_web_location":
				ensure => present,	
				server => "sympa_web",
				location => "$sympa_web_location",
				fastcgi=>"unix:$sympa_fcgi_socket",
				location_cfg_append => {
					fastcgi_split_path_info => '^(/sympa)(.*)$',
				},
				fastcgi_param => {
					'SCRIPT_FILENAME' => "$sympa_fcgi_program",
					'PATH_INFO' => '$fastcgi_path_info',
				}
			}

			nginx::resource::location {"sympa_static_location":
				ensure => present,	
				server => "sympa_web",
				location => "$sympa_static_web_location",
				location_cfg_append => {
					alias => "$sympa_static_dir",
				}
			}
		}
		else{
			$_sympa_fcgi_addr = $sympa_fcgi_addr
		}

		class {"mailserver::install_spawn_fcgi":
			username => "sympa",
			groupname => "sympa",
			app => "$perl",		
			app_args => "$sympa_fcgi_program",
			bindsocket => "$sympa_fcgi_socket",
			bindsocket_mode => "0600 -U www",
			bindaddr => $_sympa_fcgi_addr,
			bindport => $sympa_fcgi_port,

		}

		service {"$spawn_fcgi_service":
			ensure => "running",
			require => Class["mailserver::install_spawn_fcgi"],
			subscribe => [Class["mailserver::install_spawn_fcgi"],File[$sympa_conf]],
		}


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
		ldap_lmtp_user_filter => $_ldap_lmtp_user_filter, 
		ldap_auth_bind => $ldap_auth_bind,
		ldap_dn => $ldap_dn,
		ldap_pass => $ldap_pass,
		ldap_hosts => $ldap_hosts,

		solr=>$solr,
		lucene => $lucene,
		listen => $dovecot_listen, 
		mail_location => $dovecot_mail_location,
		disable_plaintext_auth => $tls_security == "encrypt", #$disable_plaintext_auth,

		auth_system => $auth_system,

		imap_sslcert => $_imap_sslcert,
		imap_sslkey => $_imap_sslkey,

		virtual_mailbox_base => $virtual_mailbox_base,
		ldap_login_maps_result_attribute => $ldap_login_maps_result_attribute,

#		vmail_user => $vmail_user,
#		vmail_group = $vmail_group,

		protocols => join($dovecot_services," "),
		managesieve => 'managesieve' in $services,
		sieve => 'sieve' in $services, 
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
		subscribe => [Concat["$postfix_master_cf"], File["$postfix_main_cf"], File["$postfix_dir/ldap_login_maps.cf"]]
		
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
		subscribe => Class["mailserver::install_dovecot"],
		require => [Class["mailserver::install_dovecot"],File["$ssldir/$_imap_hostname/fullchain.pem"],File["$ssldir/$_imap_hostname/privkey.pem"]]
#
#
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
	$_ldap_hosts = join($mailserver::ldap_hosts," ")
	file {"$::mailserver::params::postfix_dir/$title":
		ensure => present,
		content => "bind=yes
bind_dn=$::mailserver::ldap_dn
bind_pw=$::mailserver::ldap_pass
search_base=$::mailserver::ldap_base
server_host=$_ldap_hosts
version=3
query_filter=$query_filter
result_attribute=$result_attribute
"
	}
}


class mailserver::mx(
	$rbls = [],

	$client_restrictions = [
		"permit_mynetworks",
		"reject_unknown_reverse_client_hostname",
		"reject_unauth_pipelining"
	],
	$recipient_restrictions = [
		"permit_mynetworks",
		"reject_unverified_recipient",
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
		mailserver::service{ "Postscreen":
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
	

	mailserver::service{ "Postfix SMTP Server":
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

#	mailserver::service{ "Dovecot for $hostname":
#		service => dovecot,
#		type => "unix",
#		private =>'-',
#		unpriv => 'n',
#		chroot => 'n',
#		wakeup => '-',	
#		maxproc => '-',
#		command => "pipe",
#		args => [
#			"flags=DRhu user=vmail:vmail argv=$dovecot_lda -f \${sender} -d \${recipient}",
#		]
#
#	}


}





class mailserver::submission(
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

	$tls_security = 'encrypt',

	$milters = [],

	$mynetworks = [],

	$ldap_login_map =[],


	$verify_recipient = false,

	$sender_login_maps = [],



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

	
	$_sender_login_maps = join($sender_login_maps, " ")

	$pflmilters = join([
		$clamav_milter_sock,
		$opendkim_milter_sock,
	]," ")

	$pfmilters = join($milters," ")
#	$pfmynetworks = join($mynetworks," ")

	$kf = $::mailserver::_smtpd_sslkey

	if $tls_security != false {
		$ssl_options ="{ -o smtpd_tls_security_level = $tls_security }
	{ -o smtp_tls_note_starttls_offer = yes }
	{ -o smtpd_tls_key_file = $kf }
	{ -o smtpd_tls_cert_file = $::mailserver::_smtpd_sslcert }
	{ -o smtpd_tls_loglevel = 1 }
	{ -o smtpd_tls_received_header = yes }
	{ -o smtpd_tls_session_cache_timeout = 3600s }"
	}
	else{
		$ssl_options = ""
	}

	mailserver::service{ "Postfix Subimission":
		service => 'submission',
		command => 'smtpd',
		args => [
			"{ -o smtpd_sender_restrictions = $pfsender_restrictions }",
			"{ -o smtpd_recipient_restrictions = $pfrecipient_restrictions }",
			"{ -o smtpd_client_restrictions = $pfclient_restrictions }",
			"{ -o smtpd_helo_restrictions = $pfhelo_restrictions }",
			"{ -o smtpd_relay_restrictions = $pfrelay_restrictions }",
			"{ -o smtpd_milters = $pflmilters $pfmilters}",
			"{ -o smtpd_sasl_auth_enable = yes }",
			"{ -o smtpd_sasl_type = dovecot }",
			"{ -o smtpd_sasl_path = /var/spool/postfix/private/auth }",
			"{ -o smtpd_sender_login_maps = $_sender_login_maps }",
			"$ssl_options",
		]
	}
}














#	if $mailman3 == true {
#		ensure_resource ("class","mailserver::install_postfix",{
#			ldap  => $ldap
#		})
#		Class["mailserver::install_mailman3"] -> Class["mailserver::mailman_service"] 
#
#		class {"mailserver::install_mailman3":
#			remove_dkim => $mailman_remove_dkim
#		}
#		class {"mailserver::mailman_service":}
#		$mailman_local_maps = "hash:$mailman_vardir/data/postfix_lmtp"
#	}
	


