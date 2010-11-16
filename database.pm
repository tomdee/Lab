#!/usr/bin/perl
package database; 
use DBI;
use Data::Dumper;
use strict;
use warnings;
my $dbh;

dbConnect();

#print Dumper(getPersonFromCode("123456789"));
#print Dumper(getState("1000000000000"));
#flipState("5010123729981", 'IN');

# Find the current state for a given barcode
# IN:  a barcode
# OUT: the state (either IN or OUT)
sub getState
{
  my ($barcode) = @_;
  my %person = %{getPersonFromCode($barcode)};

  my $query = <<SQL;
select case when coalesce(o.timestamp, timestamp(0)) < i.timestamp then 'IN' else 'OUT' end as status
from person as p
join
(
	select max(i.timestamp) as timestamp
	from person_log as i
	where i.action = 'IN'
	and i.person_id = $person{"id"}
) as i on true
left join
(
	select max(o.timestamp) as timestamp
	from person_log as o
	where o.action = 'OUT'
	and o.person_id = $person{"id"}
) as o on true
where p.id = $person{"id"};
SQL
  my %result = %{dbQuerySingleRow($query)};
  return $result{"status"};
}

# Toggle a user's state
# IN:  the user barcode
# OUT: none
sub flipState
{
  my ($barcode, $state) = @_;
  $state = getState($barcode);

  my $query = <<SQL;
insert into person_log (person_id, action)
select p.id, case '$state' when 'IN' then 'OUT' else 'IN' end
from person as p
where p.barcode = '$barcode';
SQL
  $dbh->do($query);
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
    my $query = <<SQL;
select p.name
from person as p
join
(
	select i.person_id, max(i.timestamp) as timestamp
	from person_log as i
	where i.action = 'IN'
	group by i.person_id
) as i on i.person_id = p.id
left join
(
	select o.person_id, max(o.timestamp) as timestamp
	from person_log as o
	where o.action = 'OUT'
	group by o.person_id
) as o on o.person_id = p.id
where coalesce(o.timestamp, timestamp(0)) < i.timestamp;
SQL

    my @names;
    my $result = dbQueryManyRows($query, "name");
    print Dumper($result);
    my %resultHash = %{$result};
    for my $name (keys(%resultHash))
    {
      push(@names,$name);
    }  

    return \@names;
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
