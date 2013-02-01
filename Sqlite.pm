package Sqlite;

my $verbose=0;

use strict;
use File::Basename;
use DBI;
use DBI qw(:sql_types);
use DateTime::Format::SQLite;
use POSIX;

sub new
{
  my $this = bless {}, shift;
  $this->{'alps'} = shift;
  $verbose = $this->{'alps'}->{'verbose'};

  $this->Debug(3,"");

  #Open the database
  $this->{'dsn'} = "dbi:SQLite:dbname=$this->{'alps'}->{'database'}";
  $this->Debug(1,"Using database $this->{'alps'}->{'database'}");

  my $user = '';
  my $password = '';
  my %attr = ( RaiseError => 1, AutoCommit => 0 );

  $this->{'dbh'} = DBI->connect($this->{'dsn'}, $user, $password, \%attr)
     or $this->Debug( 0, "Can't connect to database: $DBI::errstr" ) and die;
  $this->{'dbh'}->do("PRAGMA foreign_keys = ON");

  #Check if database is existing
  my $response = $this->ExecuteQuery("SELECT count(*) FROM sqlite_master");
  if ($response->[0]->[0] == 0){
    $this->Debug(1,"Creating database");
    $this->ExecuteQuery ( "CREATE TABLE tab ( idsys INTEGER PRIMARY KEY,
                                              name TEXT,
                                              ord NUMERIC
                                              );");
    $this->ExecuteQuery ( "CREATE TABLE component ( idsys INTEGER PRIMARY KEY,
                                                    name TEXT,
                                                    ord NUMERIC,
                                                    idtab NUMERIC,
                                                    comment TEXT,
                                                    FOREIGN KEY(idtab) REFERENCES tab(idsys) ON DELETE CASCADE
                                                    );");
    $this->ExecuteQuery ( "CREATE TABLE shortcut (idsys INTEGER PRIMARY KEY,
                                                  name TEXT,
                                                  idcomponent NUMERIC,
                                                  command TEXT,
                                                  ord NUMERIC,
                                                  FOREIGN KEY(idcomponent) REFERENCES component(idsys) ON DELETE CASCADE
                                                  );");
    $this->ExecuteQuery ( "CREATE TABLE configuration ( idsys INTEGER PRIMARY KEY,
                                                        name TEXT,
                                                        width NUMERIC,
                                                        height NUMERIC,
                                                        background TEXT);");
    $this->ExecuteQuery ( "INSERT INTO configuration VALUES (1, 'default', 310, 150, '/css/background.jpg');");
  }

  return $this;
}

sub Debug
{
  my $this = shift;
  my $level = shift;

  $level <= $verbose or return;
  print STDERR "[", strftime("%Y/%m/%d-%H:%M:%S", localtime), "] ", " " x $level, (caller 1)[3], " @_\n";
}

sub ExecuteQuery {
  my $this = shift;
  my $query = shift;

  $this->Debug(3,"");

  my $dbh = $this->{'dbh'};

  $this->Debug(4,$query);
  my $isInsert = $query =~ /INSERT INTO (\S+)/;
  my $result;

  my $sth = $dbh->prepare( $query );
  $sth->execute();
  $dbh->commit();
  if ( $isInsert ) {
    my $rowid = $dbh->sqlite_last_insert_rowid();
    $sth = $dbh->prepare( "SELECT * FROM $1 WHERE rowid=$rowid" );
    $sth->execute()
  }
  $result = $sth->fetchall_arrayref();
  foreach my $row ( @{$result} ) {
    $this->Debug(5,"=> @$row");
  }
  $sth->finish();
  return $result;
}

1;
