use database;
use Data::Dumper;

#print Dumper(database::getPersonList());

print "
<html>

<head>
<title>
Barcodes
</title>

</head>

<body>
To recreate, run the following on galahad. <p>
cd /home/hacklab/barcodescanner<p>
perl createbarcodeimages.pl >list.html<p>

<table>
";

my %barcodes = %{database::getPersonList()};

for my $barcode (keys(%barcodes))
{
$barcode =~ s/\s//g;
my $filename = "images/$barcode.png";

print "<tr><td><img src='$filename'/></td><td>$barcode - " .$barcodes{$barcode} ."</td></tr>  ";
if (! -e $filename)
{
`barcodegen  $barcode  --border=5 --height=60 --write $filename`;
}
else
{

}
}



print "</table></body></html>";

