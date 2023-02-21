#!/usr/bin/perl -w

use strict;
use warnings;

use Net::SNMP;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
#my @result=`snmpwalk -v 1 localhost -c public -On .1.3.6.1.4.1.2021.9.1`;
#exit 0;

# SNMP Datas
my $storage_table =	'.1.3.6.1.2.1.25.2.3.1';
my $index_table =	$storage_table.'.1';
my $storagetype_table =	$storage_table.'.2';
my $descr_table =	$storage_table.'.3';
my $alloc_units =	$storage_table.'.4';
my $size_table =	$storage_table.'.5';
my $used_table =	$storage_table.'.6';

my $oid_hostname = ".1.3.6.1.2.1.1.5.0";
my $oid_disks = ".1.3.6.1.4.1.2021.9.1";

my $LF = "\n";

my $host = "127.0.0.1";
my $community = "public";
my $gWarning = 101;
my $gCritical = 101;
my $fPerfdataForAll = 0;
my $perfMode = 'exact';
my $fDebug = 0;
my $fHelp = 0;
my @paths;
my $perfdata = "";

our $STATE_OK=0;
our $STR_OK="OK";
our $STATE_WARNING=1;
our $STR_WARNING="WARNING";
our $STATE_CRITICAL=2;
our $STR_CRITICAL="CRITICAL";
our $STATE_UNKNOWN=3;
our $STR_UNKNOWN="UNKNOWN";
my $finalState = $STR_UNKNOWN;
my $finalMsg = "";

sub display_help {
        print "check_disk.pl v1.0" . $LF;
        print "" . $LF;
        print "Usage: ${0} [OPTIONS]" . $LF;
        print "" . $LF;
        print "Options:" . $LF;
        print "  -H, --hostname=HOST" . $LF;
        print "          *host to check" . $LF;
        print "  -c, --community=COMMUNITY" . $LF;
        print "          community to use to connect" . $LF;
	print "  -p, --path=path,w,c" . $LF;
	print "          path to check with w as warning percent used and c as critical percent used" . $LF;
	print "  -a, --perfAll" . $LF;
	print "          generate perfdata for all available path" . $LF;
	print "  --perf [all|[exact]|minimal|none]" . $LF;
	print "          generate perfdata for all|[exact]|minimal|none available path (exact is the exact list of path)" . $LF;
	print "  --warning=WARNING" . $LF;
	print "          default global percent used warning value" . $LF;
	print "  --critical=CRITICAL" . $LF;
	print "          default global percent used critical value" . $LF;
        print "  -D, --debug" . $LF;
        print "          activate debug mode, could be very verbose" . $LF;
        print "  --help" . $LF;
        print "          display this help" . $LF;
        print "" . $LF;
        print "* indicates a mandatory option" . $LF;
        exit $STATE_UNKNOWN;
}

GetOptions(
	'H|hostname=s'	=> \$host,
	'c|community=s'	=> \$community,
	'p|path=s'	=> \@paths,
	'a|perfAll'	=> \$fPerfdataForAll,
	'perf=s'	=> \$perfMode,
	'warning=i'	=> \$gWarning,
	'critical=i'	=> \$gCritical,
	'D|debug'	=> \$fDebug,
	'help'		=> \$fHelp,
) or display_help();
$perfMode = "all" if ( 0 ne $fPerfdataForAll );

display_help() if $fHelp;

print Dumper(@paths) . $LF if $fDebug;

my ($snmp_ses, $error) = Net::SNMP->session(
	-hostname => $host,
	-community => $community,
);

if (!defined($snmp_ses)) {
	printf "ERROR: %s.\n", $error;
	exit $STATE_UNKNOWN;
}

#my $result = $snmp_ses->get_request($oid_hostname);
my $result = $snmp_ses->get_table($storage_table);
#my $result = $snmp_ses->get_table(".1");

if (!defined($result)) {
	printf("ERROR: %s.\n", $snmp_ses->error());
	$snmp_ses->close();
	exit $STATE_UNKNOWN;
}
$snmp_ses->close();

my %res = %{$result};
foreach my $oid ( sort keys %res ) {
	print $oid . " = " . $res{$oid} . "\n" . $LF if $fDebug;
}
print Dumper($result) . $LF if $fDebug;

my %montage;
foreach my $oid ( sort keys %res ) {
	if ( $oid =~ /${index_table}.([[:digit:]]*)/ ) {
		my $iDisk = $1;
		if ( not $res{"$storagetype_table.$iDisk"} eq ".1.3.6.1.2.1.25.2.1.4" ) {
			print "Disk index $iDisk is not a hard drive" . $LF if $fDebug;
		} else {
			my $descrDisk = $res{"$descr_table.$iDisk"};
			my $sizeTotal = $res{"$size_table.$iDisk"} * $res{"$alloc_units.$iDisk"};
			if ( not $descrDisk =~ /\/(run|sys|dev).*/ 
				and 0 lt $sizeTotal ) {
				print "Disk index $iDisk is a hard drive [$descrDisk]" . $LF if $fDebug;
				$montage{$iDisk}{'alloc_unit'} = $res{"$alloc_units.$iDisk"};
				$montage{$iDisk}{'mount'} = $descrDisk;
				$montage{$iDisk}{'size_total'} = $sizeTotal;
				$montage{$iDisk}{'size_used'} = $res{"$used_table.$iDisk"} * $montage{$iDisk}{'alloc_unit'};
				$montage{$iDisk}{'size_available'} = $montage{$iDisk}{'size_total'} - $montage{$iDisk}{'size_used'};
				print Dumper($montage{$iDisk}) . $LF if $fDebug;
				$montage{$iDisk}{'percent_used'} = int( 0.5 + 100 * $montage{$iDisk}{'size_used'} / $montage{$iDisk}{'size_total'});
			}
		}
	}
}

print Dumper(%montage) . $LF if $fDebug;

$finalState = $STATE_OK;
my %montagePath;
foreach my $path (@paths){
	(my $lookfor, my $warning, my $critical) = split(',',$path);
	continue if not defined $lookfor;
	$warning = $gWarning if not (defined $warning);
	$critical = $gCritical if not (defined $critical);
	print "lookfor=".$lookfor." warning=".$warning." critical=".$critical."\n" if $fDebug;
	my $lookkey=-1;
	my $lookmount="";
	my %mountWinner;
	foreach my $key ( sort keys %montage ) {
		my %mount = %{$montage{$key}};
		print "Found key = $key [$mount{'mount'}]\n" if $fDebug;
		if ( -1 lt index $lookfor, $mount{'mount'} )
		{
			print " lookfor in $mount{'mount'}\n" if $fDebug;
			if ( length $lookmount lt length $mount{'mount'}) {
				$lookkey=$key;
				$lookmount=$mount{'mount'};
				%mountWinner = %mount;
				print "=> matching at key " . $lookkey . "\n" if $fDebug;
			}
		}
	}
	$montage{$lookkey}{'warning'}=$warning if (not defined $montage{$lookkey}{'warning'}) or ($warning < $montage{$lookkey}{'warning'});
	$montage{$lookkey}{'critical'}=$critical if (not defined $montage{$lookkey}{'critical'}) or ($critical < $montage{$lookkey}{'critical'});
	if ($montage{$lookkey}{'warning'} <= $montage{$lookkey}{'percent_used'}) {
		$finalState = $STATE_WARNING if ($STATE_OK == $finalState);
		$finalState = $STATE_CRITICAL if ($montage{$lookkey}{'critical'} <= $montage{$lookkey}{'percent_used'});
		$finalMsg .= " - $lookfor";
	}
	foreach my $key (keys %{$montage{$lookkey}}) { $montagePath{$lookfor}{$key} = $montage{$lookkey}{$key}; }
	$montagePath{$lookfor}{'mount'} = $lookfor;
	#print Dumper(%montagePath) .$LF;
	print Dumper($montage{$lookkey}).$LF if $fDebug;
	print "mount=".$mountWinner{'mount'}."\n" if $fDebug; 
	print "Winner is [".$lookkey."|".$lookmount."]\n" if $fDebug;
	print "Free= ". (100 - $mountWinner{'percent_used'}) . "% | Free space= ". $mountWinner{'size_available'} ." kbytes\n" if $fDebug;
}

#Calcul du state final et du perfdata
print Dumper(%montage) .$LF if $fDebug;
if ( "exact" eq $perfMode ) {
	%montage = ();
	foreach my $ckey (keys %montagePath) { $montage{$ckey} = $montagePath{$ckey}; }
}
print Dumper(%montage) .$LF if $fDebug;
if ( "none" ne $perfMode ) {
	foreach my $key ( sort keys %montage ) {
		if ("all" eq $perfMode or defined $montage{$key}{'warning'}){
			my $perf_warning = 0;
			my $perf_critical = 0;
			$montage{$key}{'warning'} = $gWarning if ( "all" eq $perfMode and not defined $montage{$key}{'warning'} and defined $gWarning );
			$montage{$key}{'critical'} = $gCritical if ( "all" eq $perfMode and not defined $montage{$key}{'critical'} and defined $gCritical );
			$perf_warning = $montage{$key}{'size_total'} * $montage{$key}{'warning'} / 100 if (defined $montage{$key}{'warning'});
			$perf_critical = $montage{$key}{'size_total'} * $montage{$key}{'critical'} / 100 if (defined $montage{$key}{'critical'});
			$perfdata .= " $montage{$key}{'mount'}=$montage{$key}{'size_used'};$perf_warning;$perf_critical;0;$montage{$key}{'size_total'}";
		}
	}
}
$perfdata =~ s/^\s+|\s+$//g;

print "$STR_OK" if $finalState == $STATE_OK;
print "$STR_WARNING" if $finalState == $STATE_WARNING;
print "$STR_CRITICAL" if $finalState == $STATE_CRITICAL;
print "$STR_UNKNOWN" if $finalState == $STATE_UNKNOWN;
print "$finalMsg | $perfdata$LF";
exit $finalState;

