package PostAction;

my $verbose=0;

use strict;
use POSIX;
use CGI;
use Sqlite;
use URI::Escape;
use JSON;

sub new
{
  my $this = bless {}, shift;
  $this->{'alps'} = shift;

  $verbose = $this->{'alps'}->{'verbose'};

  $this->Debug(3,"");

  my @functions = (
    "MoveTab",
    "AddTab",
    "DeleteTab",
    "EditTab",
    "MoveComponent",
    "AddComponent",
    "DeleteComponent",
    "EditComponent",
    "AddShortcut",
    "MoveShortcut",
    "DeleteShortcut",
    "EditShortcut"
  );

  $this->{'function'} = \@functions;

  return $this;
}

sub Debug
{
  my $this = shift;
  my $level = shift;

  $level <= $verbose or return;
  print STDERR "[", strftime("%Y/%m/%d-%H:%M:%S", localtime), "] ", " " x $level, (caller 1)[3], " @_\n";
}

sub MoveTab
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};

  /order=(.*)/;
  my @order = split (',', $1);
  my $order=1;
  foreach my $idsys ( @order ) {
    $sqlite->ExecuteQuery("UPDATE tab SET ord=$order WHERE idsys=$idsys");
    $order++;
  }
  $alps->PrintResponse( 'text/html', '' );
  return 1;
}

sub AddTab
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  s/\+/ /g;
  /title=(.*)/;
  $this->Debug(3,"$1");
  my $response = $sqlite->ExecuteQuery("INSERT INTO tab (name, ord) VALUES ( '$1', 9999 )");
  my ($idsys, $name, $order) = @{$response->[0]};
  my $json = to_json( { 'idsys'=>$idsys,
                        'name'=>$name } );
  $this->Debug(3,"Response : $json");
  $alps->PrintResponse( 'application/json', $json );
  return 1;
}

sub DeleteTab
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  /tabid=(.*)/;
  $sqlite->ExecuteQuery("DELETE FROM tab WHERE idsys=$1");
  $alps->PrintResponse( 'text/html', '' );
  return 1;
}

sub EditTab
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  my ($idsys, $title) = /idsys=(\d+)&newtitle=(.*)/;
  $title =~ s/\+/ /g;
  $sqlite->ExecuteQuery("UPDATE tab SET name='$title' WHERE idsys=$idsys");
  my $json = to_json( { 'newtitle'=>$title } );
  $alps->PrintResponse( 'application/json', $json );
  return 1;
}

sub AddComponent
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  my ($tabid, $name, $comment) = /tabid=(\d+)&name=(.*)&comment=(.*)/;
  $name =~ s/\+/ /g;
  my $response = $sqlite->ExecuteQuery("SELECT idsys FROM tab ORDER BY ord LIMIT 1 OFFSET $tabid");
  my $idtab = $response->[0]->[0];
  if ( $name eq 'Component' ){
    $response = $sqlite->ExecuteQuery("SELECT MAX(idsys) from component");
    my $idsys = $response->[0]->[0];
    $name .= ( $idsys ? " ".($idsys+1) : " 1" );
  }
  $response = $sqlite->ExecuteQuery("INSERT INTO component (idtab, name, comment, ord) VALUES ($idtab,'$name','$comment',9999)");
  my ($idsys, $name, $order, $idtab, $comment) = @{$response->[0]};
  my $json = to_json( { 'idsys'   => $idsys,
                        'name'    => $name,
                        'idtab'   => $idtab,
                        'comment' => $comment,
                        'order'   => $order } );
  $this->Debug(3,"$json");
  $alps->PrintResponse( 'text/html', $json );
  return 1;

}

sub DeleteComponent
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  /idsys=(.*)/;
  $sqlite->ExecuteQuery("DELETE FROM component WHERE idsys=$1");
  $alps->PrintResponse( 'text/html', '' );
  return 1;
}

sub EditComponent
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  my ($idsys, $name) = /idsys=(\d+)&newname=(.*)/;
  $name =~ s/\+/ /g;
  $sqlite->ExecuteQuery("UPDATE component SET name='$name' WHERE idsys=$idsys");
  my $json = to_json( { 'newname'=>$name } );
  $alps->PrintResponse( 'application/json', $json );
  return 1;
}

sub MoveComponent
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  s/componentPanel\[\]=//g;
  s/&/,/g;
  /order=(.*)/;
  my @order = split (',', $1);
  my $order=1;
  foreach my $idsys ( @order ) {
    $sqlite->ExecuteQuery("UPDATE component SET ord=$order WHERE idsys=$idsys");
    $order++;
  }
  $alps->PrintResponse( 'text/html', '' );
  return 1;
}

sub MoveShortcut
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};

  s/shortcut\[\]=//g;
  s/&/,/g;
  /order=(.*)/;
  my @order = split (',', $1);
  my $order=1;
  foreach my $idsys ( @order ) {
    $sqlite->ExecuteQuery("UPDATE shortcut SET ord=$order WHERE idsys=$idsys");
    $order++;
  }
  $alps->PrintResponse( 'text/html', '' );
  return 1;
}

sub AddShortcut
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  my ($idcomponent, $name, $command) = /idcomponent=(\d+)&name=(.*)&command=(.*)/;
  $name =~ s/\+/ /g;
  my $response = $sqlite->ExecuteQuery("INSERT INTO shortcut (idcomponent, name, command, ord) VALUES ($idcomponent,'$name','$command',9999)");
  my ($ord, $idsys, $name, $idcomponent, $command, ) = @{$response->[0]};
  my $json = to_json( { 'idsys'       => $idsys,
                        'name'        => $name,
                        'idcomponent' => $idcomponent,
                        'command'     => $command } );
  $alps->PrintResponse( 'text/html', $json );
  return 1;
}

sub DeleteShortcut
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  /shortcutId=(.*)/;
  $sqlite->ExecuteQuery("DELETE FROM shortcut WHERE idsys=$1");
  $alps->PrintResponse( 'text/html', '' );
  return 1;
}

sub EditShortcut
{
  my $this = shift;
  $_ = uri_unescape( shift );
  $this->Debug(3,"$_");

  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $alps = $this->{'alps'};
  my ($idsys, $name, $command) = /shortcutId=(\d+)&newname=(.*)&newcommand=(.*)/;
  $name =~ s/\+/ /g;
  $command =~ s/\+/ /g;
  $sqlite->ExecuteQuery("UPDATE shortcut SET name='$name', command='$command' WHERE idsys=$idsys");
  my $json = to_json( { 'name'=>$name,
                        'command'=>$command
   } );
  $alps->PrintResponse( 'application/json', $json );
  return 1;
}

1;
