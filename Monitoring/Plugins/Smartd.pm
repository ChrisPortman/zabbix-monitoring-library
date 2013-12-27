#!/usr/bin/false

package Monitoring::Plugins::Smartd;

use strict;
use warnings;

my ($smartctl) = `which smartctl`;
chomp($smartctl);

sub register {
    if ( -f $smartctl ) {
        chmod oct(4755), $smartctl;
    }
    else {
        return;
    }
    
    my @tests = (
        'smartd.dev.discover,monitoring.pl -m Smartd -a discover',
        'smartd.dev.health[*],monitoring.pl -m Smartd -a test --args $1'
    );
}

sub discover {
    my $return = { 'data' => [] };
    my $cmd  = "$smartctl --scan";
    my @smartdevs = `$cmd`;
    
    for my $dev ( grep { m|^(/dev/\w+)| } @smartdevs ) {
        chomp($dev);
        if ( $dev =~ m|^(/dev/\w+)| ) {
            my $name    = $1;
            
            push @{$return->{'data'}}, {
                '{#DEV}' => $name,
            };
        }
    }
    
    return wantarray ? %{$return} : $return;
}

sub test {
    my $self   = shift;
    my $device = shift;
    my $result = _smart($device);
    return $result;
}

sub _smart {
    my $device = shift or return '0';
    
    my @vals = `$smartctl -H $device`;
    my ($result) = map { /(\w+)$/; $1 } grep { /result:/ } @vals;
    return $result;
}

1;
