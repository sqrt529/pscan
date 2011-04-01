#!/usr/bin/perl
# pscan - A tiny portscanner, which is using the connect() scan method.
# 
# Copyright (C) 2010, 2011 Joachim "Joe" Stiegler <blablabla@trullowitsch.de>
#
# This program is free software; you can redistribute it and/or modify it under the terms
# of the GNU General Public License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program;
# if not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;
use IO::Socket;
use Getopt::Std;
use Net::Ping;
use File::Basename;

our ($opt_h, $opt_P, $opt_p, $opt_H, $opt_v, $opt_o, $service);

my $version = "0.9.1";

sub usage {
	die "Usage: ", basename($0), " <-H Host[,Host2,HostN]> [-p <Port[-Port]>] [-P [N]] [-o <outfile>] [-v]\n";
}

if ( (!getopts("hH:p:P:vo:")) or (defined($opt_h)) ) {
	usage();
}

if (defined($opt_v)) {
	print "Version: $version\n";
	exit(0);
}

if (defined($opt_o)) {
	open(STDOUT, '>', $opt_o) or die "Can't access ", $opt_o, ": $!\n";
}

my $port = $opt_p if (defined($opt_p));
my @host = split(/,/, $opt_H) if (defined($opt_H));

sub checkhost {
	if ( (!defined($opt_P)) || $opt_P ne "N" ) {
		my $chost = shift(@_);
		my $p = Net::Ping->new();

		if (!$p->ping($chost)) {
			print "$chost is not alive or blocks our ping probe. Try -PN\n";
			$p->close();
			return 0;
		}
		else {
			$p->close();
			return 1;
		}
	}
	return 1;
}

sub is_numeric {
	my $dport = shift(@_);
	if ($dport =~ /[^\d]/) {
		die "You can only use digits as portnumbers.\n";		
	}
	else {
		return 1;
	}
}

sub checkport {
	my $ckhost = shift(@_);
	my $checkport = shift(@_);

	my $result = 0;

	IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>$ckhost, PeerPort=>$checkport, Timeout=>5) or $result = 1;

	$service = getservbyport($checkport, "tcp");
	if (!defined($service)) {
		$service = "unknown";
	}
	return ($result);
}

sub check_single_port {
	my $ckhost = shift(@_);
	if (!checkhost($ckhost)) {
		return 1;
	}

	if ($port =~ /.-./) {
		(my $portvon, my $portbis) = split (/-/, $port);
		
		is_numeric($portvon); 
		is_numeric($portbis); 

		if ($portvon > $portbis) {
			for (my $i=$portvon; $i>=$portbis; $i--) {
				my $result = checkport($ckhost, $i);
				if ($result == 0) {
					print "$ckhost: Port $i is open ($service)\n";
				}
			}
		}
		else {
			for (my $i=$portvon; $i<=$portbis; $i++) {
				my $result = checkport($ckhost, $i);
				if ($result == 0) {
					print "$ckhost: Port $i is open ($service)\n";
				}
			}
		}
	}
	else {
		is_numeric($port);

		my $result = checkport($ckhost, $port);

		if ($result == 0) {
			print "$ckhost: Port $port is open ($service)\n";
		} 
		else {
			print "$ckhost: Port $port is closed ($service)\n";
		}
	}
}

sub check_all_ports {
	my $ckhost = shift(@_);
	if (!checkhost($ckhost)) {
		return 1;
	}

	for (my $i=1; $i<=65535; $i++) {
		my $result = checkport($ckhost, $i);	
		if ($result == 0) {
			print "$ckhost: Port $i is open ($service)\n";
		}
	 }
}

usage() if (!defined($opt_H));

foreach my $chkhost (@host) {
	if (defined($opt_p)) {
		check_single_port($chkhost);
	} else {
		check_all_ports($chkhost);
	}
}
