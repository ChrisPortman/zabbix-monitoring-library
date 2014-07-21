#!/usr/bin/false

package Monitoring::Plugins::Processes;

use strict;
use warnings;
use IO::Dir;
use IO::File;

sub register {
    [
      'proc.running.discover,monitoring.pl -m Processes -a discover',
      'proc.running.process[*],monitoring.pl -m Processes -a test --args $1',
    ]
}

sub discover {
    my $return = { 'data' => [] };
    
    if ( -f '/etc/zabbix/plugin_data/processes.list' ) {
        open( my $fh, '<', '/etc/zabbix/plugin_data/processes.list' )
          or die "Could not open /etc/zabbix/plugin_data/processes.list: $!\n";
        
        my @processes;
        { local $/; @processes = split("\n", <$fh>); }
        
        for my $proc ( @processes ) {
            push @{$return->{'data'}}, {
                '{#PROCESS}' => $proc,
            };
        }
    }
}

sub test {
    my $process   = lc(shift);
    my $processes = _get_procs();

    return $processes->{'names'}->{$process} || 0;
}

sub _get_procs {
    my %processes = (
      names  => {},
      by_pid => {},
    );

    my $proc = IO::Dir->new( "/proc" );
    
    while ( my $pid = $proc->read() ) {
        next unless $pid =~ /^\d+$/;
        my $statusfile = IO::File->new("< /proc/$pid/status");
        next unless defined $statusfile;
        
        $processes{'by_pid'}->{$pid} = {};
        while ( $statusfile->read() ) {
            my($key, $value) = split(/\s*:\s*/, $_, 2);
            $processes{'by_pid'}->{$pid}->{$key} = $value;
        }
        
        if ( my $proc_name = lc($processes{'by_pid'}->{$pid}->{'name'}) ) {
            if ($processes{'names'}->{$proc_name}) {
                $processes{'names'}->{$proc_name} ++;
            }
            else {
                $processes{'names'}->{$proc_name} = 1;
            }
        }
    }
    
    return wantarray ? %processes : \%processes;
}
