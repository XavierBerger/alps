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
use Preprocessor;
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
  $path ~~ @{$this->{'paths'}} or $connection->send_error(404) and return;

  #The main page (/) is requested
  $path =~ /^\/$/ and $this->PrintPage() and return;

  #If the file exists we return it
  -e ".$path" and $this->SendFile($connection, ".$path") and return;

  #If the file is not existing it means we need to construct it
  if ( $path =~ /alps\.((css|js))$/ ) {
    my $preprocessor = $this->{'preprocessor'};
    my $content = $preprocessor->Print("$1/alps.pre.$1");
    $this->PrintResponse( 'text/'. ( $1=~/js/ ? "javascript" : "css"), $content ) and return;
  }

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
  $this->{'preprocessor'} = Preprocessor->new($this);
  $this->{'postAction'} = PostAction->new($this);

  # Create the server
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
  for (;;) {
    while ( $this->{'connection'} = $this->{'server'}->accept) {
      while (my $request = $this->{'connection'}->get_request) {
        my $method = "Do".$request->method();
        $this->$method($request);
      }
      $this->{'connection'}->close;
      undef($this->{'connection'});
    }
    $this->Debug(1,"400 Bad Request");
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
Usage: alps.pl [options]

Options:
  -h(elp)           show this help message and exit
  -p(ort) PORT      port used by alps' web server (default=8080)
  -a(ddr) ADDRESS   address used by alps' web server (default=0.0.0.0)
  -s(sl)            activate https
  -d(atabase)       define sqlite database to use
  -l(ogfile)        define log output (default=STDERR - not modifiable yet)
  -v([v]+)          debug level (default=0)

Official website: http://code.google.com/p/alps/

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
    /-d(atabase)?/ and $alps->{'database'} = shift and next;
    /-h(elp)?$/ and Usage();
    /^-([v]+)$/ and $verbose = length $1 and next;
  }

  #Set default values
  $alps->{'port'} ||= 8080;
  $alps->{'addr'} ||= '0.0.0.0';
  $alps->{'database'} ||= 'alps.sqlite';

  # Manage Ctrl+C
  $SIG{'INT'} = sub { $alps->Close() };

  $alps->Run;

}

alps_main(@ARGV) unless caller;
