#!/usr/bin/env perl

use strict;
use warnings;
use JSON::XS;
use Getopt::Long;
use Monitoring::Plugins;
use Data::Dumper;

my $USERAGENTCONF   = '/etc/zabbix/zabbix_agentd.conf.d/useragents.conf';
my $ZABBIXAGENTINIT = '/etc/init.d/zabbix-agent';

#Process Command line opts
my $module;
my $action = 'null';
my @args;
my $help;

GetOptions (
    "module|m=s" => \$module,
    "action|a=s" => \$action,
    "args:s{,}"  => \@args,
    "help|h"     => \$help
) or print "Invalid options\n".help()."\n";

$help and help();

#Set up the modules object
my $modules = Monitoring::Plugins->new();

=head2 Discover

Arguments: Name of module whos discover method should be invoked (SCALAR)

=cut
sub discover {
    my $module = shift or return;
    return if ref $module;
    
    #Call the discovery method.
    my $result = $modules->discover($module);
    
    #print the JSON
    my $encoder = JSON::XS->new->ascii->pretty;
    print $encoder->encode($result)."\n";
}

=head2 Test

Arguments: Name of module whos test method should be invoked (SCALAR)
           Arbitrary number of arguments that will be passed to the method.

=cut
sub test {
    my $module = shift or return;
    my @args   = @_;
    
    #Call the modules test function passing any suplied arguments.
    my $result = $modules->test($module, @args);
    print "$result\n";
}

sub register {
    my @registrations = map { 
        unless (/^UserParameter/) { 
            "UserParameter=$_";
        }
        else {
            $_;
        } 
    } $modules->register();
    
    my $registrations =  join("\n", sort { $a cmp $b } @registrations);
    $registrations .= "\n";
    
    
    unless ( -d '/etc/zabbix/' ) {
        mkdir '/etc/zabbix/';
    }

    unless ( -d '/etc/zabbix/zabbix_agentd.conf.d' ) {
        mkdir '/etc/zabbix/zabbix_agentd.conf.d';
    }
    
    if ( open( my $rfh, '<', $USERAGENTCONF) ) {
        local $/;
        my $current = <$rfh>;
        close $rfh;
        
        if ($registrations eq $current) {
            return 1;
        }
    }

    open (my $wfh, '>', $USERAGENTCONF)
      or die "Could not open $USERAGENTCONF for writing: $!\n";
    
    print $wfh $registrations;
    
    if (-f $ZABBIXAGENTINIT) {
        system( "$ZABBIXAGENTINIT restart");
    }

    return 1;
}

sub help {
    my $help = <<'HELP';
Usage:
    monitoring.pl -h
    monitoring.pl -m <module> -a (discover|test)
    monitoring.pl -a discover
    monitoring.pl -a register

Options:
    --help | -h   : Display this text.
    --module | -m : Specifiy the module to load (required -a)
    --action | -a : Specify the 'discovery', 'test' or 'register method.

HELP

    print $help;
    exit 0;
}

my %actions = (
    'discover' => \&discover,
    'test'     => \&test,
    'register' => \&register,
);

if ( $actions{$action} ) {
    $actions{$action}->($module, @args);
}

exit 0;
