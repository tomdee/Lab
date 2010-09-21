use Device::SerialPort qw( :PARAM :STAT 0.07 );
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

open( PORT, "/dev/ttyUSB0" );

$currentString = "";

while (1)
{
    read( PORT, $char, 1 );

    if ( $char =~ /\r/ )
    {
        chomp($currentString);

        printBarcode($currentString);
        $currentString = "";

    }
    else
    {
        $currentString .= $char;
    }
}

close PORT;

sub printBarcode
{
    my ($barcode) = @_;
    print "Read barcode $barcode\n";
}

