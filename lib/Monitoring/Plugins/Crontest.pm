#!/usr/bin/false

package Monitoring::Plugins::Crontest;

use strict;
use warnings;

my $testfile = '/var/tmp/crontest';

sub register {
  my @agents;
  if ( -f '/var/tmp/crontest' ) {
    push(@agents, 'cron.lasttest,monitoring.pl -m Crontest -a test');
  }
  
  return @agents;
}

sub test {
  my $diff = undef;
  
  if ( -f $testfile ) {
    my $mtime = (stat($testfile))[9] || 0;
    $diff = abs(time - $mtime);
  }

  return $diff;
}
