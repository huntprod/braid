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
	my %replace = @_;

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

	my ($fh, $file) = tempfile("braid.test.XXXXXXX", DIR => $TEMPDIR);
	diag "test case $file:" if $ENV{KEEP};
	print $fh $request;
	close $fh;

	return qx(./msgtest < $file);
}

is minimal_request(),
	"GET /some/url HTTP/1.1\r\n".
	"Host: 127.0.0.1\r\n".
	"Accept: */*\r\n".
	"\r\n";

my ($min, $max) = (1, 19);
for (my $n = $min; $n <= $max; $n++) {
	my $uri = "/".("a" x ($n * 100))."/z";
	is minimal_request(URI => $uri),
		"GET $uri HTTP/1.1\r\n".
		"Host: 127.0.0.1\r\n".
		"Accept: */*\r\n".
		"\r\n",
		"request uri of ~${n}00 characters should parse";
}

for (my $n = $min; $n <= $max; $n++) {
	my $host = ("a" x ($n * 100)).".local";
	is minimal_request(HOST => $host),
		"GET /some/url HTTP/1.1\r\n".
		"Host: $host\r\n".
		"Accept: */*\r\n".
		"\r\n",
		"host header of ~${n}00 characters should parse";
}

for (my $n = $min; $n <= $max; $n++) {
	my $header = "X-".("A" x ($n * 100))."H";
	is minimal_request(HEADER => $header, VALUE => "ahh"),
		"GET /some/url HTTP/1.1\r\n".
		"Host: 127.0.0.1\r\n".
		"$header: ahh\r\n".
		"\r\n",
		"header name of ~${n}00 characters should parse";
}

for (my $n = $min; $n <= $max; $n++) {
	my $value = ("A" x ($n * 100))."H";
	is minimal_request(HEADER => "X-Screaming", VALUE => $value),
		"GET /some/url HTTP/1.1\r\n".
		"Host: 127.0.0.1\r\n".
		"X-Screaming: $value\r\n".
		"\r\n",
		"header value of ~${n}00 characters should parse";
}

done_testing;
