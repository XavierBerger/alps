#!/usr/bin/perl
# Script inspired by http://www.perlmonks.org/?node_id=644413
use strict;
use File::ChangeNotify;
use File::ChangeNotify::Event;

sub startProcess
{
  print STDERR "\n==================================================\n";
  my $pid;
  if($pid = fork) {
      print STDERR "parent pid=$$ child pid=$pid\n";
  }elsif (defined $pid) {
      print STDERR "child pid=$$ pid=$pid\n";
      # Must do setpgrp as child for nohup and job control stuff...
      setpgrp(0, $$);
      exec "./alps.pl -vvvv" || die "Bad exec $!";
  }
  return $pid;
}

my $pid = startProcess();

$SIG{'INT'} = sub {  kill 'INT', $pid; die "\n"; };

my $watcher =
    File::ChangeNotify->instantiate_watcher
        ( directories => [ '.', './js/', './css/' ],
          filter      => qr/\.(?:pm|pl|css|js)$/,
        );

while ( my @events = $watcher->wait_for_events() ) {
  print "Modification detected. Stopping child $pid.\n";
  kill 'INT', $pid;
  $pid = startProcess();
}
