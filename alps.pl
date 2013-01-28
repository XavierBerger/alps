#!/usr/bin/perl

my $verbose=0;

package Alps;

use strict;
use POSIX;
use IO::Handle;
use HTTP::Daemon;
use HTTP::Daemon::SSL;
use HTTP::Status;
use CGI;
use CGI::Session;
use Css;
use Javascript;
use PostAction;

sub new
{
  my $this = bless {}, shift;
  $this->Debug(2,"");

  my @paths = (
    "/",
    "/alps.pl",
    "/favicon.ico",
    "/js/jquery-1.7.1.min.js",
    "/js/jquery-ui-1.8.17.custom.min.js",
    "/js/jquery.cookie.js",
    "/js/alps.js",
    "/css/smoothness/jquery-ui-1.8.17.custom.css",
    "/css/smoothness/images/ui-icons_454545_256x240.png",
    "/css/smoothness/images/ui-bg_glass_75_dadada_1x400.png",
    "/css/smoothness/images/ui-icons_222222_256x240.png",
    "/css/smoothness/images/ui-bg_glass_55_fbf9ee_1x400.png",
    "/css/smoothness/images/ui-bg_flat_0_aaaaaa_40x100.png",
    "/css/smoothness/images/ui-icons_2e83ff_256x240.png",
    "/css/smoothness/images/ui-bg_flat_75_ffffff_40x100.png",
    "/css/smoothness/images/ui-bg_highlight-soft_75_cccccc_1x100.png",
    "/css/smoothness/images/ui-icons_888888_256x240.png",
    "/css/smoothness/images/ui-bg_glass_65_ffffff_1x400.png",
    "/css/smoothness/images/ui-bg_glass_75_e6e6e6_1x400.png",
    "/css/smoothness/images/ui-bg_glass_95_fef1ec_1x400.png",
    "/css/smoothness/images/ui-icons_cd0a0a_256x240.png",
    "/css/alps.css",
    "/css/background.jpg"
  );

  $this->{'paths'} = \@paths;


  $this->{'cgi'} = new CGI;

  my $sid = $this->{'cgi'}->cookie("CGISESSID") || undef;
  $this->{'session'} =  new CGI::Session(undef, $sid, { Directory=>"/tmp" } );

  return $this;
}

sub Debug
{
  my $this = shift;
  my $level = shift;

  $level <= $verbose or return;
  print STDERR "[", strftime("%Y/%m/%d-%H:%M:%S", localtime), "] ", " " x $level, (caller 1)[3], " @_\n";
}

sub PrintResponse {
  my $this=shift;
  my $contentType = shift;
  $this->Debug(2,"");

  my $connection = $this->{'connection'};
  my $response = HTTP::Response->new(
      RC_OK, OK => [ 'Content-Type' => $contentType ], shift
  );
  $connection->send_response($response);
  $connection->close();
}

sub PrintJavascript
{
  my $this = shift;
  my $connection = shift;
  $this->Debug(2,"");

  my $javascript = $this->{'javascript'};
  $this->PrintResponse( 'text/javascript', $javascript->Print() );
  return 1;
}

sub PrintCss
{
  my $this = shift;
  $this->Debug(2,"");

  my $css = $this->{'css'};
  $this->PrintResponse( 'text/css', $css->Print() );
  return 1;
}

sub SendFile
{
  my $this = shift;
  my $connection = shift;
  my $file = shift;
  $this->Debug(2,$file);

  $connection->send_file_response($file);
  $connection->close();
  return 1;
}

sub PrintPage
{
  my $this = shift;
  my $connection = shift;
  $this->Debug(2,"");

  $this->PrintResponse( 'text/html', $this->{'page'}->Print() );
  return 1;
}

sub DoGET
{
  my $this = shift;
  my $request = shift;
  $this->Debug(2,"");

  my $connection = $this->{'connection'};
  my $path = $request->url->path;
  $path =~ s/\.\.\//\//g;
  $this->Debug(1,$path);

  #The file need to be known or we return an error
  $path ~~ @{$this->{'paths'}} or $connection->send_error() and return;

  #The main page (/) is requested
  $path =~ /^\/$/ and $this->PrintPage($connection) and return;

  #If the file exists we return it
  -e ".$path" and $this->SendFile($connection, ".$path") and return;

  #If the file is not existing it means we need to construct it
  $path =~ /alps\.css$/ and $this->PrintCss($connection) and return;
  $path =~ /alps\.js$/ and $this->PrintJavascript($connection) and return;

  #Finally send error
  $connection->send_error();

}

sub DoPOST
{
  my $this = shift;
  my $request = shift;
  $this->Debug(2,"");

  my $connection = $this->{'connection'};
  my $path = $request->url->path;
  $path =~ s/^\///;
  $this->Debug(1,$path);

  my $postAction = $this->{'postAction'};

  $path ~~ @{$postAction->{'function'}} or $connection->send_error(500,"Function Unknown: $path") and return;



  $postAction->$path($request->content) and return;

  $connection->send_error(500,"NOTHING DONE!");
  $this->Debug(1,"NOTHING DONE!");

}

sub Run
{
  my $this = shift;
  $this->Debug(2,"");

  $this->{'verbose'} = $verbose;

  # Create objects used to construct page
  $this->{'sqlite'} = Sqlite->new($this);
  $this->{'page'} = Page->new($this);
  $this->{'css'} = Css->new($this);
  $this->{'javascript'} = Javascript->new($this);
  $this->{'postAction'} = PostAction->new($this);

  #Create the server
  if ( $this->{'ssl'} ) {
    $this->{'server'} = new HTTP::Daemon::SSL( ReuseAddr => 1,
                                               LocalAddr => $this->{'addr'},
                                               LocalPort => $this->{'port'}) or die $!;
  }
  else {
    $this->{'server'} = new HTTP::Daemon     ( ReuseAddr => 1,
                                               LocalAddr => $this->{'addr'},
                                               LocalPort => $this->{'port'}) or die $!;
  }

  $this->Debug(1,"< URL:", $this->{'server'}->url, ">");

  #Process requests
  while ( $this->{'connection'} = $this->{'server'}->accept) {
    while (my $request = $this->{'connection'}->get_request) {
      my $method = "Do".$request->method();
      $this->$method($request);
    }
    $this->{'connection'}->close;
    undef($this->{'connection'});
  }
}

sub Close
{
  my $this = shift;
  $this->Debug(1, "Closing server.");
  $this->{'server'}->close;
  die;
}
1;

package main;

sub Usage
{
  die <<EOF
  Help to be written
EOF
}

sub alps_main {
  my $alps = Alps->new;

  #Get information from command line
  while($_ = shift)
  {
    /^-/ or last;
    /-p(ort)?/ and $alps->{'port'} = shift and next;
    /-a(ddr)?/ and $alps->{'addr'} = shift and next;
    /-s(sl)?/ and $alps->{'ssl'} = 1 and next;
    /-l(ogfile)?/ and $verbose ||= 1 and $alps->{'log'} = shift and next;
    /-h(elp)?$/ and Usage();
    /^-([v]+)$/ and $verbose = length $1 and next;
  }

  #Set default values
  $alps->{'port'} ||= 8080;
  $alps->{'addr'} ||= '127.0.0.1';

  # Manage Ctrl+C
  $SIG{'INT'} = sub { $alps->Close() };

  $alps->Run;

}

alps_main(@ARGV) unless caller;
