# $Id: Makefile.PL,v 1.26 2005/01/16 21:05:17 dbrobins Exp $

use ExtUtils::MakeMaker qw( prompt WriteMakefile );
use strict;

use 5.006;

my $is_sdk = 0;
for my $arg (@ARGV) {
    $is_sdk = 1, last if $arg eq '--sdk';
}

my %BASE_PREREQS = (
    1 => {
        'String::CRC32'     => '1.2',
        'Math::GMP'         => '1.04',
        'Digest::MD5'       => 0,
        'IO::Socket'        => 0,
	'Scalar::Util'      => 0,
    },

    2 => {
        'Digest::MD5'       => 0,
        'Digest::SHA1'      => 0,
        'Digest::HMAC_MD5'  => 0,
        'Digest::HMAC_SHA1' => 0,
        'Crypt::DSA'        => '0.11',
        'Crypt::DH'         => '0.01',
        'Math::Pari'        => '2.001804',
        'MIME::Base64'      => 0,
        'Convert::PEM'      => '0.05',
        'IO::Socket'        => 0,
    },
);

for my $i (1..2) {
    for my $mod (keys %{ $BASE_PREREQS{$i} }) {
        $BASE_PREREQS{3}{$mod} = $BASE_PREREQS{$i}{$mod};
    }
}

my %prereq;

my @cryptmod = (
    [ 'IDEA', 'Crypt::IDEA' ],
    [ 'DES', 'Crypt::DES' ],
    [ 'DES3', 'Crypt::DES' ],
    [ 'Blowfish', 'Crypt::Blowfish' ],
    [ 'RC4', '' ],
);

if ($is_sdk) {
    for my $mod (keys %{ $BASE_PREREQS{sdk} }) {
        $prereq{$mod} = $BASE_PREREQS{sdk}{$mod};
    }

    for my $list (\@cryptmod) {
        for my $ref (@$list) {
            if ($ref->[1]) {
                $prereq{$ref->[1]} = $ref->[2] ? $ref->[2] : 0;
            }
        }
    }
} else {
    print<<MSG;
This is Net::SSH::Perl.

MSG

    print<<MSG;
As of version 1.00, Net::SSH::Perl supports both the SSH1 and
SSH2 protocols natively. The two protocols have different
module prerequisitives, so you need to decide which protocol(s)
you plan to use. If you use one or the other, only those modules
for your chosen protocol will be installed; if you choose both,
all of the supporting modules will be installed. Please choose
the protocols you'd like to use from the following list ("Both"
is the default).

MSG

    for my $i (1..2) {
        printf "    [%d] SSH%d\n", $i, $i;
    }
    printf "    [3] Both SSH1 and SSH2\n";

    my $p = prompt("\nWhich protocol(s) do you plan to use?", 3);
    print "\n";

    for my $mod (keys %{ $BASE_PREREQS{$p} }) {
        $prereq{$mod} = $BASE_PREREQS{$p}{$mod};
    }

    print<<MSG;

Some of the Net::SSH::Perl ciphers depend on a Crypt:: module from
CPAN. You may already have the necessary modules installed, in which
case you don't need to bother with this step. Otherwise you'll need
to install at least one cipher to use Net::SSH::Perl. Please choose
at least one from the following list (Crypt::IDEA is the default).

MSG
    my $i = 1;
    for my $ciph (sort { $a->[0] <=> $b->[0] } @cryptmod) {
        printf "    [%d] %s\n", $i++, $ciph->[0];
    }
    my $c = prompt("\nEnter your choices, separated by spaces:", 1);
    print "\n";

    for my $id (split /\s+/, $c) {
        next unless $cryptmod[$id-1]->[1];
        $prereq{ $cryptmod[$id-1]->[1] } = '0';
    }

    print "\nChecking for required modules\n\n";
    my(%todo, $missing);
    while (my($k, $v) = each %prereq) {
        unless (check_module($k, $v, \$missing)) {
            $todo{$k} = $v;
        }
    }

    use Cwd;
    my $cwd = cwd();

    if (%todo) {
        print <<MSG;
Net::SSH::Perl depends on several external modules for functionality.
Some of these modules can not be found on your system; they can be
installed automatically for you. To do so will require loading the
CPAN shell, which may require you to be running as root. Answer 'n' to
each of the following questions if you'd rather not install any
needed modules right now; note, however, that you'll still need to
install them to use Net::SSH::Perl.

MSG

        while (my($k, $v) = each %todo) {
            if (prompt(sprintf("%s%s not installed/out of date. Install (y/n)?",
              $k, $v ? " (ver. $v)" : ""), "y") =~ /^y/) {
                require CPAN; CPAN::Shell->install($k);
                delete $prereq{$k};
                chdir $cwd or die "Can't chdir back to $cwd: $!";
            }
        }
    }

    print "\nChecking for optional modules\n\n";

    unless (check_module('Digest::BubbleBabble', 0.01, \$missing)) {
        print<<MSG, "\n";
Digest::BubbleBabble is required if you want to generate bubble babble
key fingerprints with pssh-keygen.
MSG
        if (read_yes_or_no("Would you like to install it now? (y/n)", "y")) {
            require CPAN; CPAN::Shell->install('Digest::BubbleBabble');
            chdir $cwd or die "Can't chdir back to $cwd: $!";
        }
        print "\n";
    }

    unless (check_module('Crypt::RSA', 1.37, \$missing)) {
        print<<MSG, "\n";
Crypt::RSA is required if you wish to use the ssh-rsa public
key algorithm (ssh-dss is used by default).
MSG
        if (read_yes_or_no("Would you like to install it now? (y/n)", "y")) {
            require CPAN; CPAN::Shell->install('Crypt::RSA');
            chdir $cwd or die "Can't chdir back to $cwd: $!";
        }
        print "\n";
    }

    print "\n";
}

WriteMakefile(
    NAME => 'Net::SSH::Perl',
    DISTNAME => 'Net-SSH-Perl',
    VERSION_FROM => 'lib/Net/SSH/Perl.pm',
    PREREQ_PM    => \%prereq,
    AUTHOR => 'Dave Rolsky <autarch@urth.org>',
    ABSTRACT => 'Perl client Interface to SSH',
);

sub read_yes_or_no {
    my($prompt, $def) = @_;
    my $ans = prompt($prompt, $def);
    $ans =~ /^y/i;
}

sub check_module {
    my($name, $ver, $missing) = @_;
    print substr("$name ............................", 0, 30);
    my $ok = have_mod($name, $ver);
    $$missing++ unless $ok;
    print $ok ? "ok\n" : "** FAILED **\n";
    $ok;
}

sub have_mod {
    my($name, $ver) = @_;
    eval("use $name" . ($ver ? " $ver;" : ";"));
    !$@;
}
