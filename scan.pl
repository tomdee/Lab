use Device::SerialPort qw( :PARAM :STAT 0.07 );
use strict;
use warnings;

initSerial();
open( PORT, "/dev/ttyUSB0" );

my $currentString = "";

while (1)
{
    my $char;
    read( PORT, $char, 1 );

    if ( $char =~ /\r/ )
    {
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

#Return hash of barcodes to person ID
sub getPeopleHash
{
    my %peopleHash = (
        '1001' => '1',
        '1002' => '2',
        '1003' => '3',
    );

    return \%peopleHash;
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

    my @test = ("Tom");
    for my $person (@test)
    {
        say $person;
    }
}

sub logAllOut
{

    # fetch all people who are currently IN
    my @test = ("Tom");
    for my $person (@test)
    {
        say("logged $person out");
    }

    #logout($person);
}

sub ignoreScan
{
#Do database lookup
return false;
}

sub handleBarcode
{
    my ($barcode)   = @_;
    my %peopleHash  = %{ getPeopleHash() };
    my %commandHash = %{ getCommandHash() };

    if ( $peopleHash{$barcode} )
    {

        # Found a person
        say("Found a person");

        if ignoreScan($barcode)
{   
say("Ignoring");
return;
}

my $state = getState($barcode);


    }
    elsif ( $commandHash{$barcode} )
    {
        &{ $commandHash{$barcode} };
        say("Found a command");
    }
    else
    {
        say("Unrecognized barcode $barcode");
    }
}

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

## Please see file perltidy.ERR
