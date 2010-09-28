#!/usr/bin/perl
package database; 
use DBI;
use Data::Dumper;
use strict;
my $dbh;

dbConnect();

#print Dumper(getPersonFromCode("123456789"));
#print Dumper(getPersonList());

# Find the current state for a given barcode
# IN:  a barcode
# OUT: the state (either IN or OUT)
sub getState
{
  my ($barcode) = @_;
  my %person =  %{getPersonFromCode($barcode)};
  my %log = %{getLastLogFromPersonId($person{"id"})};

  return $log{"action"};
}


# Find the latest log for a given person
# IN:  A person ID
# OUT: hash contain a single log row
sub getLastLogFromPersonId
{
    my ($id) = @_;
    $id = $dbh->quote($id);
    my $query = "SELECT * FROM person_log WHERE person_id=$id ORDER BY timestamp LIMIT 1";
    return dbQuerySingleRow($query);
}

# Finds a single database row giving a persons details, given a barcode.
# IN:  a barcode
# OUT: hashref mapping a database fields to values for a single person row
sub getPersonFromCode
{
    my ($barcode) = @_;
    $barcode = $dbh->quote($barcode);
    my $query = "SELECT * FROM person WHERE barcode=$barcode LIMIT 1";   
    return dbQuerySingleRow($query);
}

# Finds the list of all hacklab members
# IN:  Nothing
# OUT: Hashref mapping barcodes to peoples names.
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

# Finds the current members that are in the lab
# IN:  Nothing
# OUT: Array ref storing a list of names.
sub getWhosInLab
{
  #TODO
}
 
# Logs out all currently logged in members
# IN:  Nothing
# OUT: Nothing
sub logAllOut
{
  #TODO
}
 
# Utility to connect to database. 
# Everything is hardcoded
# 
# Sets up global $dbh variable
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

# Utility function to return many database rows
# IN:  SQL query
# IN:  string representing the field to use as the hash key
# OUT: hashref mapping keys to database rows
sub dbQueryManyRows
{
    my ($query, $key) = @_;

    # prepare the query
    my $sth = $dbh->prepare($query);

    # execute the query
    $sth->execute();

    return $sth->fetchall_hashref($key);
}

# Utility funtion to return a single database row
# IN:  SQL query to execute
# OUT: hashref mapping fields to values for a single database row
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
