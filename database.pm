#!/usr/bin/perl
package database; 
use DBI;
use Data::Dumper;
use strict;
my $dbh;

dbConnect();

print Dumper(getPersonFromCode("123456789"));
print Dumper(getPersonList());

sub getState
{
  my ($barcode) = @_;
  my %person =  %{getPersonFromCode($barcode)};
  my %log = %{getLastLogFromPersonId($person{"id"})};

  return $log{"action"};
}

sub getLastLogFromPersonId
{
    my ($id) = @_;
    $id = $dbh->quote($id);
    my $query = "SELECT * FROM person_log WHERE person_id=$id ORDER BY timestamp LIMIT 1";
    return dbQuerySingleRow($query);
}


sub getPersonFromCode
{
    my ($barcode) = @_;
    $barcode = $dbh->quote($barcode);
    my $query = "SELECT * FROM person WHERE barcode=$barcode LIMIT 1";   
return dbQuerySingleRow($query);
}

sub getPersonList
{
    my $query = "SELECT * FROM person";   
    my %idToPerson = %{dbQueryManyRows($query, "id")};
    
    my %barcodeToPerson;

    for my $key (keys(%idToPerson))
    { 
      $barcodeToPerson{$idToPerson{$key}{"barcode"}} = $idToPerson{$key}{"name"};
    }
return \%barcodeToPerson;
}
  

sub dbConnect
{
    my $dsn = 'dbi:mysql:bigbrother:localhost:3306';    # DB DSN

    # set the user and password
    my $user = 'hacklab';
    my $pass = 'hacklab';

    # now connect and get a database handle
    $dbh = DBI->connect( $dsn, $user, $pass )
      or die "Can’t connect to the DB: $DBI::errstr\n";
}

sub dbQueryManyRows
{
    my ($query, $key) = @_;

    # prepare the query
    my $sth = $dbh->prepare($query);

    # execute the query
    $sth->execute();

    return $sth->fetchall_hashref($key);
}

sub dbQuerySingleRow
{
    my ($query) = @_;

    # prepare the query
    my $sth = $dbh->prepare($query);

    # execute the query
    $sth->execute();

    return $sth->fetchrow_hashref();
}


1;
