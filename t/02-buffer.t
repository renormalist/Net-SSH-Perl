# $Id: 02-buffer.t,v 1.7 2001/04/22 03:35:15 btrott Exp $

use strict;

use Test;
BEGIN { plan tests => 20 }

use vars qw( $loaded );
END { print "not ok 1\n" unless $loaded; }
use Net::SSH::Perl::Buffer qw( SSH1 );
$loaded++;
ok($loaded);

use Math::GMP;

my $buffer = Net::SSH::Perl::Buffer->new;
ok($buffer);
$buffer->put_str("foo");
ok($buffer->length, 7);
ok($buffer->get_str, "foo");
ok($buffer->offset, 7);

$buffer->put_str(0);
ok($buffer->get_str, 0);

$buffer->put_int32(999999999);
ok($buffer->get_int32, 999999999);

$buffer->put_int8(2);
ok($buffer->get_int8, 2);

$buffer->put_char('a');
ok($buffer->get_char, 'a');

my $gmp = Math::GMP->new("999999999999999999999999999999");
$buffer->put_mp_int($gmp);
my $tmp = $buffer->get_mp_int;
ok("$tmp", "$gmp");

$buffer->empty;
ok($buffer->offset, 0);
ok($buffer->length, 0);
ok($buffer->bytes, '');

$buffer->append("foobar");
ok($buffer->length, 6);
ok($buffer->bytes, "foobar");

$buffer->empty;
ok($buffer->length, 0);
ok($buffer->dump, '');

$buffer->put_int16(129);
ok($buffer->get_int16, 129);
ok($buffer->dump, '00 81');
ok($buffer->dump(1), '81');
