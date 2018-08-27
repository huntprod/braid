#!perl

use Test::More;
use File::Temp qw(tempfile tempdir);

my $TEMPDIR = tempdir(CLEANUP => $ENV{KEEP} ? 0 : 1);

sub minimal_request {
	my %replace = @_;

	my $request = "{METHOD} {URI} {VERSION}\r\n".
	              "Host: {HOST}\r\n".
	              "Accept: {ACCEPT}\r\n".
	              "\r\n";

	$replace{METHOD}  ||= 'GET';
	$replace{URI}     ||= '/some/url';
	$replace{VERSION} ||= 'HTTP/1.1';
	$replace{HOST}    ||= '127.0.0.1';
	$replace{ACCEPT}  ||= '*/*';

	for my $find (keys %replace) {
		$request =~ s/{\Q$find\E}/$replace{$find}/g;
	}

	my ($fh, $file) = tempfile("braid.test.XXXXXXX", DIR => $TEMPDIR);
	print $fh $request;
	close $fh;

	return qx(./msgtest < $file);
}

is minimal_request(),
	"GET /some/url HTTP/1.1\r\n".
	"Host: 127.0.0.1\r\n".
	"Accept: */*\r\n".
	"\r\n";

for (my $n = 1; $n < 20; $n++) {
	my $uri = "/".("a" x ($n * 100))."/z";
	is minimal_request(URI => $uri, HOST => '127.0.0.2'),
		"GET $uri HTTP/1.1\r\n".
		"Host: 127.0.0.2\r\n".
		"Accept: */*\r\n".
		"\r\n",
		"request uri of ~${n}00 characters should parse";
}

done_testing;
