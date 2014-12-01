#!/usr/bin/perl -w

use Net::SNMP qw(:snmp);
use XML::Dumper;
use strict;

my %hosthash = (
	'usnyc2sbc01.us.wspgroup.com' => 'wspread',
		);

(my $session, my $error) = Net::SNMP->session(
                           -hostname      => 'usnyc2sbc01.us.wspgroup.com',
                           -port          => "161",
                           -version       => 2,
                           #-debug       => 0x10,
                           -community     => $hosthash{'usnyc2sbc01.us.wspgroup.com'},
                        );

die $error if $error;

my $ipGroupDescription                = '1.3.6.1.4.1.5003.9.10.3.1.1.23.21.1.6';
my $ipGroupSIPGroupName               = '1.3.6.1.4.1.5003.9.10.3.1.1.23.21.1.8';
my $acPMSIPIPGroupInviteDialogsTotal  = '1.3.6.1.4.1.5003.10.8.2.52.22.1.10';
my $acPMSIPIPGroupInInviteDialogsTotal  = '1.3.6.1.4.1.5003.10.8.2.52.32.1.10';
my $acPMSIPIPGroupOutInviteDialogsTotal  = '1.3.6.1.4.1.5003.10.8.2.52.35.1.10';

die $error if $error;

my $output = $session->get_table(-baseoid => $ipGroupDescription);

my @indexes = map ( /$ipGroupDescription\.(\d+)$/, keys $output);

foreach my $index (@indexes)
	{
	print "Index $index ";

	my $test = $session->get_request(-varbindlist => ["$ipGroupSIPGroupName.$index",
		"$acPMSIPIPGroupInviteDialogsTotal.$index.0",
		"$acPMSIPIPGroupInInviteDialogsTotal.$index.0",
		"$acPMSIPIPGroupOutInviteDialogsTotal.$index.0"]);

	die $error if $error;
	print pl2xml($test);
	}
