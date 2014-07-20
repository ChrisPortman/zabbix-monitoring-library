#!/usr/bin/false

package Monitoring::Plugins::Crontest;

use strict;
use warnings;

my $testfile = '/var/tmp/crontest';

sub register {
  my @agents;
  if ( -f '/var/tmp/crontest' ) {
    push(@agents, 'services.cron.running,monitoring.pl -m Crontest -a test');
  }
  
  return @agents;
}

sub test {
  $diff = undef;
  
  if ( -f $testfile ) {
    my $mtime = (stat($testfile))[9] || 0;
    my $diff = abs(time - $mtime);
  }

  return $diff;
}
