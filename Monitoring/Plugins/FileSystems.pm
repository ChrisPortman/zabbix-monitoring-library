#!/usr/bin/false

package Monitoring::Plugins::FileSystems;

use strict;
use warnings;
use Log::Any qw ( $log );

sub register {
    my @tests = (
        'filesystems.discover,monitoring.pl -m FileSystems -a discover',
        'filesystems.mounted[*],monitoring.pl -m FileSystems -a test --args mounted $1'
    );
}

sub discover {
    my $return = { 'data' => [] };
    
    my @mounts = `cat /proc/mounts`;
    for my $mount ( @mounts ) {
        my ($dev, $point, $type, $opts) = split(/\s+/, $mount);
        push @{$return->{'data'}}, {
            '{#FSDEV}'   => $dev,
            '{#FSMOUNT}' => $point,
            '{#FSTYPE}'  => $type,
            '{#FSOPTS}'  => $opts,
        };
    }
    
    return wantarray ? %{$return} : $return;
}

sub test {
    my $self   = shift;
    my $test   = shift;
    my @args   = @_;
    
    #Map tests to subroutines
    my %tests = (
        'mounted' => \&_ismounted,
    );

    my $result = '';
    if ( $tests{$test} ) {
        $result = $tests{$test}->(@args);
    }

    return $result;
}

sub _ismounted {
    my $mount = shift;
    
    my $result = `cat /proc/mounts | grep -c '$mount'`;
    chomp($result);
    
    return $result;
}

1;
