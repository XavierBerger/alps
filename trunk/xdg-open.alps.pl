#!/usr/bin/perl
# xdg-open replacement by Xavier Berger
#
use warnings;
use strict;

my $XDGOPEN = "/usr/bin/xdg-open.dist";
#my $XTERM   = "/usr/bin/xterm -fa Monospace -fs 10 -bg white -fg black";
my $XTERM = "gnome-terminal";
my $VERSION = "1.0.0";  

# ----------------------------------------------------------------------
# Url processing
# ----------------------------------------------------------------------
package Url;

sub new 
{
  my $this = bless {}, shift;
  return $this;
}

sub parseUrl
{
  my $this = shift;
  $this->{'url'} = shift;
  
  $this->{'url'} or return;
  
  $_ = $this->{'url'} ;
  @$this{qw(protocol user host port path file query anchor)} = m!^([a-z]+)://([^@]+@)?([^:\/\s]+)(:\d+)?([\/\w+]*\/)?([\w\-\.]+)?([^#]+)?(#.*)?$!;

  $this->{'port'} and $this->{'port'} =~ s/://;
  
  $_ = $this->{'user'};
  $this->{'user'} and @$this{qw(user password)} = /(.+:)?(.+@)/;
  $this->{'user'} and $this->{'user'} =~ s/://;
  $this->{'password'} and $this->{'password'} =~ s/@//;
  $this->{'user'} or $this->{'user'} = $this->{'password'} and $this->{'password'} = "";

  $this->{'anchor'} and $this->{'anchor'} =~ s/#//;
  
  $this->{'query'} and $this->{'query'} =~ s/\?// and $this->{'query'} =~ s/&/ /g;
  
}

sub printUrl 
{
  my $this = shift;
  foreach my $data ( sort keys ( %$this) ) 
  { 
    $data and print "$data = "; 
    $this->{$data} and print $this->{$data};
    print "\n";
  }
}

1;


package Handler;

sub new 
{
  my $this = bless {}, shift;
  return $this;
}

sub rdp
{
  my $this = shift;
  my $url = shift;
  my $rdesktop = 'rdesktop '. $url->{'host'};
  $url->{'port'} and $rdesktop .= ":" . $url->{'port'};
	fork() and exit() or exec( "/usr/bin/rdesktop $rdesktop");
}

sub telnet
{
  my $this = shift;
  my $url = shift;

  print "TELNET: ";

  my $xterm = $XTERM;
  $url->{'anchor'} and $xterm .= " " . $url->{'anchor'};
  $xterm .= " -e";

  my $expect = "/usr/bin/expect -c";
  my $telnet = "spawn telnet " . $url->{'host'} . " " . $url->{'port'} . "; ";
  foreach my $val (split (' ', $url->{'query'}) ) 
  { 
    my @values = split ('=', $val);
    $telnet .= "expect ". $values[0] . " { send " . $values[1] . "\\r }; ";
  }
  $telnet .= " interact";

  fork() and exit() or exec("$xterm \"$expect \\\"$telnet\\\"\"");
}

sub ssh
{
  my $this = shift;
  my $url = shift;
  
  my $ssh = 'ssh -t -X ';
  $url->{'port'} and $ssh .= "-p " . $url->{'port'} . " ";
  $url->{'user'} and $ssh .= $url->{'user'}."@";
  $ssh .= $url->{'host'} . " ";
  $url->{'query'} and $url->{'query'} =~ s/=/ /;
  $url->{'query'} and $ssh .= $url->{'query'};
  
  if (!$url->{'anchor'} or $url->{'anchor'} ne 'noterm')
  {
    my $xterm = $XTERM;
    $url->{'anchor'} and $xterm .= " " . $url->{'anchor'};
    $ssh = $xterm . " -e \"" . $ssh . "\"";
  }
  fork() and exit() or exec( "$ssh ");
}

sub apt
{
  my $this = shift;
  my $url = shift;
  fork() and exit() or exec( "/usr/bin/apturl-gtk $url->{'url'}");
}

sub mount
{
  my $this = shift;
  my $url = shift;
  fork() and exit() or exec( "mount $url->{'path'} && nautilus $url->{'path'}");
}
1;

# ----------------------------------------------------------------------
# Execution part
# ----------------------------------------------------------------------
package main;

$| = 1;

sub Usage
{
  local $_ = $0;
  m/^.*\\(.*[.].*)$/;
  print "Name

$_ - xdg-open url additionnal handlers

Description

Additionnal url handlers to support the following protocols:
  - apt    : install package from apt://
  - mount  : mount directory from mount://127.0.0.1/directory and start 
             nautilus on this directory
  - rdp    : Open rdesktop rdp:// 
  - ssh    : Execute ssh command
             #noterm : Anchor specifiying to not start an xterm
             #-hold : Anchor specifying to not close the xterm windows 
             after connection . 
  - telnet : Telnet connection. The uri define expected output and 
             command to be sent (in order). This allow and automatic 
             connections.

$_ installation
  Copy $_ in /usr/bin/
  Change directory to /usr/bin/
  Move xdg-open to xdg-open.dist
  Create a symlink to xdg-open.alps.pl named xdg-open

Protocol handler installation

To install a new protocol handler for <HANDLER> for a protocol (listed upper), execute the following commands:
  gconftool-2 -s /desktop/gnome/url-handlers/<HANDLER>/command '/usr/bin/xdg-open %s' --type String
  gconftool-2 -s /desktop/gnome/url-handlers/<HANDLER>/enabled --type Boolean true
------------------------------------------------------------------------
";
}

while ($_ = shift) {
  /^-/ or last;
  /--version/ and print "$0 $VERSION\n";
  #/--help/  ## Nothing to add to the default help
  /--manual/ and Usage();
  exec ("$XDGOPEN $_") and die;
}

$_ or exec ("$XDGOPEN") and die;
my $param = $_;

my $url = Url->new;
$url->parseUrl($param);
#$url->printUrl();

my $handler = Handler->new;
my $function = $url->{'protocol'};
$handler->can($function) and $handler->$function($url) or exec ("$XDGOPEN '$param'");	





