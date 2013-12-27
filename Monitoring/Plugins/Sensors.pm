#!/usr/bin/false

package Monitoring::Plugins::Sensors;

use strict;
use warnings;
use Log::Any qw ( $log );

sub register {
    my @tests = (
        'sensors.discover,monitoring.pl -m Sensors -a discover',
        'sensors.sensor[*],monitoring.pl -m Sensors -a test --args $1'
    );
}

sub discover {
    my $return = { 'data' => [] };
    
    my @sensors = `sensors`;
    for my $sensor ( grep { /\d+\.\d+/ } @sensors ) {
        chomp($sensor);
        if ( $sensor =~ /(.+):.+?(\d+\.\d+).+?(\d+\.\d+).+?(\d+\.\d+)/ ) {
            my $name    = $1;
            my $current = $2;
            my $high    = $3;
            my $crit    = $4;
            
            push @{$return->{'data'}}, {
                '{#SENSOR}' => $name,
                '{#HIGH}'   => $high,
                '{#CRIT}'   => $crit,
            };
        }
    }
    
    return wantarray ? %{$return} : $return;
}

sub test {
    my $self   = shift;
    my $sensor = shift;
    my $result = _sensor($sensor);
    return $result;
}

sub _sensor {
    my $sensor = shift or return '0';
    
    my @vals = `sensors`;
    my ($result) = map { /(\d+\.\d+)/; $1 } grep { /$sensor/ } @vals;
    return $result;
}

1;
