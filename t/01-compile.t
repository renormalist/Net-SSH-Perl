# $Id: 01-compile.t,v 1.3 2001/02/22 00:12:55 btrott Exp $

my $loaded;
BEGIN { print "1..1\n" }
use Net::SSH::Perl;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
