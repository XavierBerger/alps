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
    "EditComponent"
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
  $sqlite->ExecuteQuery("DELETE FROM component WHERE idtab=$1");
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
  #$alps->PrintResponse( 'application/json', $json );
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
1;
