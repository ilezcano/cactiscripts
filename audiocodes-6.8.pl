#!/usr/bin/perl -w

use Net::SNMP qw(:snmp);
use XML::Dumper;
use strict;

my $host = $ARGV[0];
my $comm = $ARGV[1];
my $command = $ARGV[2];

(my $session, my $error) = Net::SNMP->session(
                           -hostname      => $host,
                           -port          => "161",
                           -version       => 2,
                           #-debug       => 0x10,
                           -community     => $comm,
                        );

die $error if $error;

my $ipGroupDescription                = '1.3.6.1.4.1.5003.9.10.3.1.1.23.21.1.6';
my $ipGroupSIPGroupName               = '1.3.6.1.4.1.5003.9.10.3.1.1.23.21.1.8';
my $acPMSIPIPGroupInDialogsTotal      = '1.3.6.1.4.1.5003.10.8.2.52.30.1.3';
my $acPMSIPIPGroupOutDialogsTotal     = '1.3.6.1.4.1.5003.10.8.2.52.31.1.3';

die $error if $error;

if ($command =~ /num_indexes|index/i)
	{
	my $output = $session->get_table(-baseoid => $ipGroupDescription);
	my @indexes = map ( /$ipGroupDescription\.(\d+)$/, keys $output);

	die $error if $error;

	if ($command eq 'num_indexes')
		{print scalar(@indexes)}

	elsif ($command eq 'index')
		{
		local $, = "\n";
		print @indexes;
		}

	}

elsif ($command eq "query")
	{
	local $, = ":";
	local $\ = "\n";

	if ($ARGV[3] eq 'description')
		{
		my $output = $session->get_table(-baseoid => $ipGroupDescription);
		die $error if $error;
		my @indexes = map ( /$ipGroupDescription\.(\d+)$/, keys $output);
		foreach my $index (@indexes)
			{
			print ($index, $$output{"$ipGroupDescription.$index"});
			}
		}

	elsif ($ARGV[3] eq 'name')
		{
		my $output = $session->get_table(-baseoid => $ipGroupSIPGroupName);
		die $error if $error;
		my @indexes = map ( /$ipGroupSIPGroupName\.(\d+)$/, keys $output);
		foreach my $index (@indexes)
			{
			local $, = ":";
			local $\ = "\n";
			print ($index, $$output{"$ipGroupSIPGroupName.$index"});
			}
		}
		
	elsif ($ARGV[3] eq 'indialog')
		{
		my $output = $session->get_table(-baseoid => $ipGroupDescription);
		die $error if $error;

		my @indexes = map ( /$ipGroupDescription\.(\d+)$/, keys $output);

		my @pollthese = map ( "$acPMSIPIPGroupInDialogsTotal.$_.0", @indexes);

		my $test = $session->get_request(-varbindlist => \@pollthese);
		die $error if $error;

		foreach (@indexes) {print ($_, $$test{ "$acPMSIPIPGroupInDialogsTotal.$_.0"})}
		}
		
	elsif ($ARGV[3] eq 'outdialog')
		{
		my $output = $session->get_table(-baseoid => $ipGroupDescription);
		die $error if $error;

		my @indexes = map ( /$ipGroupDescription\.(\d+)$/, keys $output);

		my @pollthese = map ( "$acPMSIPIPGroupOutDialogsTotal.$_.0", @indexes);

		my $test = $session->get_request(-varbindlist => \@pollthese);
		die $error if $error;

		foreach (@indexes) {print ($_, $$test{ "$acPMSIPIPGroupOutDialogsTotal.$_.0"})}
		}
	}

elsif ($command eq "get")
	{
	my $return = "U";
	my $providedindex = $ARGV[4];

	my @pollthese = ( "$ipGroupDescription.$providedindex", "$ipGroupSIPGroupName.$providedindex", "$acPMSIPIPGroupInDialogsTotal.$providedindex.0", "$acPMSIPIPGroupOutDialogsTotal.$providedindex.0");

	my $test = $session->get_request(-varbindlist => \@pollthese);
	die $error if $error;
	
	foreach my $oid (keys $test)
		{
		if (($ARGV[3] eq 'description') && (oid_base_match($ipGroupDescription, $oid))) {$return= $$test{$oid}}
		elsif (($ARGV[3] eq 'name') && (oid_base_match($ipGroupSIPGroupName, $oid))) {$return= $$test{$oid}}
		elsif (($ARGV[3] eq 'indialog') && (oid_base_match($acPMSIPIPGroupInDialogsTotal, $oid))) {$return= $$test{$oid}}
		elsif (($ARGV[3] eq 'outdialog') && (oid_base_match($acPMSIPIPGroupOutDialogsTotal, $oid))) {$return= $$test{$oid}}
		}
	print $return;
	}

$session->close;
