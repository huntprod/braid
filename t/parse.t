#!perl

use Test::More;
use File::Temp qw(tempfile tempdir);

my $TEMPDIR = "t/test-data";
if ($ENV{KEEP}) {
	`rm -rf t/test-data; mkdir t/test-data`;
} else {
	$TEMPDIR = tempdir(CLEANUP => 1);
}

sub minimal_request {
	my ($f, %replace) = @_;

	my $request = "{METHOD} {URI} {VERSION}\r\n".
	              "Host: {HOST}\r\n".
	              "{HEADER}: {VALUE}\r\n".
	              "\r\n";

	$replace{METHOD}  ||= 'GET';
	$replace{URI}     ||= '/some/url';
	$replace{VERSION} ||= 'HTTP/1.1';
	$replace{HOST}    ||= '127.0.0.1';
	$replace{HEADER}  ||= 'Accept';
	$replace{VALUE}   ||= '*/*';

	for my $find (keys %replace) {
		$request =~ s/{\Q$find\E}/$replace{$find}/g;
	}

	my ($fh, $file) = tempfile("braid.test.$f.XXXXXXX", DIR => $TEMPDIR);
	diag "test case $file:" if $ENV{KEEP};
	print $fh $request;
	close $fh;

	return qx(./msgtest < $file);
}

is minimal_request("simple"),
	"GET /some/url HTTP/1.1\r\n".
	"Host: 127.0.0.1\r\n".
	"Accept: */*\r\n".
	"\r\n";

my $min = ($ENV{ONLY} ||    1)+0;
my $max = ($ENV{ONLY} || 2000)+0;
for (my $n = $min; $n <= $max; $n++) {
	my $uri = "/".("a" x ($n * 10))."/z";
	is minimal_request("uri-$n", URI => $uri),
		"GET $uri HTTP/1.1\r\n".
		"Host: 127.0.0.1\r\n".
		"Accept: */*\r\n".
		"\r\n",
		"request uri of ~${n}0 characters should parse";
}

for (my $n = $min; $n <= $max; $n++) {
	my $host = ("a" x ($n * 10)).".local";
	is minimal_request("host-$n", HOST => $host),
		"GET /some/url HTTP/1.1\r\n".
		"Host: $host\r\n".
		"Accept: */*\r\n".
		"\r\n",
		"host header of ~${n}0 characters should parse";
}

for (my $n = $min; $n <= $max; $n++) {
	my $header = "X-".("A" x ($n * 10))."H";
	is minimal_request("header-$n", HEADER => $header, VALUE => "ahh"),
		"GET /some/url HTTP/1.1\r\n".
		"Host: 127.0.0.1\r\n".
		"$header: ahh\r\n".
		"\r\n",
		"header name of ~${n}0 characters should parse";
}

for (my $n = $min; $n <= $max; $n++) {
	my $value = ("A" x ($n * 10))."H";
	is minimal_request("value-$n", HEADER => "X-Screaming", VALUE => $value),
		"GET /some/url HTTP/1.1\r\n".
		"Host: 127.0.0.1\r\n".
		"X-Screaming: $value\r\n".
		"\r\n",
		"header value of ~${n}0 characters should parse";
}

done_testing;
