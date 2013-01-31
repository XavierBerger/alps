my $verbose=0;


package Preprocessor;

use strict;
use POSIX;
use CGI::Session;
use Sqlite;
use Page;


sub new
{
  my $this = bless {}, shift;
  $this->{'alps'} = shift;

  $verbose = $this->{'alps'}->{'verbose'};

  $this->Debug(3,"");

  return $this;
}

sub Debug
{
  my $this = shift;
  my $level = shift;

  $level <= $verbose or return;
  print STDERR "[", strftime("%Y/%m/%d-%H:%M:%S", localtime), "] ", " " x $level, (caller 1)[3], " @_\n";
}

sub AddDialog
{
  my $this=shift;
  my $dialogName = shift;
  $this->Debug(4,"");
  return "
        var \$$dialogName = \$( '#$dialogName' ).dialog({
            autoOpen: false,
            modal: true,
            buttons: {
              Add: function() {
                  $dialogName();
                  \$( this ).dialog( 'close' );
                },
                Cancel: function() {
                  \$( this ).dialog( 'close' );
                }
              },
              open: function() {
                \$( 'form', \$$dialogName )[0].focus();
              },
              close: function() {
                \$( 'form', \$$dialogName )[0].reset();
              }
            });

            \$( 'form', \$$dialogName ).submit(function() {
              $dialogName();
              \$$dialogName.dialog( 'close' );
              return false;
            });
      ";
}

sub EditDialog
{
  my $this=shift;
  my $dialogName = shift;
  $this->Debug(4,"");
  return "
        var \$$dialogName = \$( '#$dialogName' ).dialog({
            autoOpen: false,
            modal: true,
            width: 'auto',
            buttons: {
                Update: function() {
                  $dialogName();
                  \$( this ).dialog( 'close' );
                },
                Cancel: function() {
                  \$( this ).dialog( 'close' );
                }
              },
              open: function() {
                \$( 'form', \$$dialogName )[0].focus();
              },
              close: function() {
                \$( 'form', \$$dialogName )[0].reset();
              }
            });

            \$( 'form', \$$dialogName ).submit(function() {
              $dialogName();
              \$$dialogName.dialog( 'close' );
              return false;
            });
  ";
}

sub DeleteDialog
{
  my $this=shift;
  my $dialogName = shift;
  $this->Debug(4,"");
  return "
         var \$$dialogName = \$( '.$dialogName' ).live( 'click', function() {
          \$( '#$dialogName' ).dialog({
            resizable: false,
            height:140,
            modal: true,
            buttons: {
              Cancel: function() {
                \$( this ).dialog( 'close' );
              },
              'Delete': function() {
                $dialogName();
                \$( this ).dialog( 'close' );
              }
            }
          })
        });
  ";
}

sub Print {
  my $this = shift;
  my $filename = shift;
  $this->Debug(3,$filename);
  my $page = $this->{'alps'}->{'page'};
  my $content;

  #Calculate the next idsys
  my $query="SELECT MAX(idsys) FROM tab";
  my $response = $this->{'alps'}->{'sqlite'}->ExecuteQuery($query);
  my $id = ($response->[0]->[0])+1 || 0;

  my $componentWidth=310;
  my $componentHeight=150;
  my $componentButtonOffset=92;

  open (FILE, $filename);
  while (<FILE>) {
    if (/\[% (.*) %\]/ ){
      my $tag = eval ($1);
      s/\[% (.*) %\]/$tag/;
    }
    $content .= $_;
  }
  close (FILE);
  return $content;
}

1;
