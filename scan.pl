use Device::SerialPort qw( :PARAM :STAT 0.07 );
use strict;
use warnings;
use database;
use Data::Dumper;

# print Dumper( database::getPersonList() );


my $n = -1;

while ($n < 10) {
    $n++;

    print "Trying port..." . $n . "\n";
    initSerial($n);
    open( PORT, "/dev/ttyUSB" . $n) or next;
    print "Opened port..." . $n . "\n";
    last;
}

my $currentString = "";

# Main program loop. Reads data from barcode scanner character by character
while (1)
{
    my $char;
    read( PORT, $char, 1 );

    if ( $char =~ /\n/ )
    {
        # \n marks the end of a complete scan.
        chomp($currentString);
        print "BARCODE|$currentString|";
        handleBarcode($currentString);
        $currentString = "";

    }
    else
    {
        $currentString .= $char;
    }
}

close PORT;


my $gLastPersonScanned;
my $gLastCommandScanned = "";


# Return hash of barcodes to person ID
# 
sub getPeopleHash
{
    return database::getPersonList();
}

sub getCommandHash
{
    # Maps command barcodes onto routines
    my %commandHash = (
        '000000084062'  => \&sayHello,
        '9780719540158' => \&identifyPerson,
        '9780859340601' => \&removeLastEntry,
        '9780859344012' => \&whosInLab,
        '9780859341592' => \&logAllOut,

    );
    return \%commandHash;
}

sub sayHello
{
    say("Hello - you ve run a command");
}

sub identifyPerson
{
    say("Now scan person");
    $gLastCommandScanned = "identify"; 
    # TODO - probably maintain some nasty gloabl state for this command...
}

sub removeLastEntry
{
    my $lastEntry =  database::removeLastEntry();
    say("Entry for $lastEntry has been removed");
}

sub whosInLab
{

    # fetch all people who are currently IN
    say("The following people are in the lab");
    my @peoplePresent = @{database::getWhosInLab()};
    for my $person (@peoplePresent)
    {
        say($person);
    }
}

sub logAllOut
{
    # fetch all people who are currently IN
    # Say who's in the lab, then log them all out.
    whosInLab();
    database::logAllOut();
    say("Logging everyone out");
}

sub ignoreScan
{
    #Do database lookup
    
    return 0;
}


# The main barcode handling code
# Called each time a barcode is read
# There are two main categories of barcodes - people and command.
# IN:  a barcode to handle
# OUT: nothing
sub handleBarcode
{
    my ($barcode)   = @_;
    my %peopleHash  = %{ getPeopleHash() };
    my %commandHash = %{ getCommandHash() };

    if ( $peopleHash{$barcode} )
    {
        # Can't remeber what this is for...
        if ( ignoreScan($barcode) )
        {
            say("Ignoring");
            return;
        }

        my $state = database::getState($barcode);
	if ( $state eq 'IN' )
        {
		say( "Goodbye " . $peopleHash{$barcode} );
	}
	else
	{
		say( "Hello " . $peopleHash{$barcode} );
	}
        
        if ($gLastCommandScanned ne "identify")
        {
          database::flipState($barcode, $state);
        }

        # Finished dealing with a person, no longer care about the lastCommand
        $gLastCommandScanned = "";
    }
    elsif ( $commandHash{$barcode} )
    {   
        # Clear the last command run, as we're now running another command
        $gLastCommandScanned = "";

        &{ $commandHash{$barcode} };
        print("Found a command");
    }
    else
    {
        say("Unrecognized barcode $barcode");
    }
}

# Say some text
# IN:  the text to speak
# OUT: Nothing
sub say
{
    my ($barcode) = @_;

    print "Read barcode $barcode\n";
    system("espeak -v en-scottish '$barcode'");
}

sub initSerial
{
    my ($portNumber) = @_;

    my $PortName = "/dev/ttyUSB" . $n;
    my $PortObj  = Device::SerialPort->new($PortName)
      || return;

    # $PortObj->user_msg(ON);
    $PortObj->databits(8);
    $PortObj->baudrate(9600);
    $PortObj->parity("none");
    $PortObj->stopbits(1);
    $PortObj->handshake("rts");

    $PortObj->write_settings || undef $PortObj;
}

