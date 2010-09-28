use Device::SerialPort qw( :PARAM :STAT 0.07 );
use strict;
use warnings;
use database;
use Data::Dumper;

print Dumper( database::getPersonList() );

initSerial();

open( PORT, "/dev/ttyUSB0" );

my $currentString = "";

# Main program loop. Reads data from barcode scanner character by character
while (1)
{
    my $char;
    read( PORT, $char, 1 );

    if ( $char =~ /\r/ )
    {
        # \r marks the end of a complete scan.
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
my $gLastCommandScanned;


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

    # TODO - probably maintain some nasty gloabl state for this command...
}

sub removeLastEntry
{

    # Find last entry
    # Remove the entry
    say("Entry blah has been removed");
}

sub whosInLab
{

    # fetch all people who are currently IN
    say("The following people are in the lab");
    my @peoplePresent = database::getWhosInLab();
    for my $person (@peoplePresent)
    {
        say $person;
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

sub handleBarcode
{
    my ($barcode)   = @_;
    my %peopleHash  = %{ getPeopleHash() };
    my %commandHash = %{ getCommandHash() };

    if ( $peopleHash{$barcode} )
    {

        # Found a person
        say( "Hello " . $peopleHash{$barcode} );

        if ( ignoreScan($barcode) )
        {
            say("Ignoring");
            return;
        }

        my $state = database::getState($barcode);
        say("State $state");

    }
    elsif ( $commandHash{$barcode} )
    {
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
sub say
{
    my ($barcode) = @_;

    print "Read barcode $barcode\n";
    system("espeak -v en-scottish '$barcode'");
}

sub initSerial
{
    my $PortName = "/dev/ttyUSB0";
    my $PortObj  = Device::SerialPort->new($PortName)
      || die "Can't open $PortName: $!\n";

    # $PortObj->user_msg(ON);
    $PortObj->databits(8);
    $PortObj->baudrate(9600);
    $PortObj->parity("none");
    $PortObj->stopbits(1);
    $PortObj->handshake("rts");

    $PortObj->write_settings || undef $PortObj;
}

