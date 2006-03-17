# $Id: Hosts.pm,v 1.8 2001/05/11 01:05:24 btrott Exp $

package Net::SSH::Perl::Util::Hosts;
use strict;

use Net::SSH::Perl::Constants qw( :hosts );

use Carp qw( croak );

sub _check_host_in_hostfile {
    my($host, $hostfile, $key) = @_;
    my $key_class = ref($key);
    local *FH;
    open FH, $hostfile or return HOST_NEW; # ssh returns HOST_NEW if
                                           # the host file can't be opened
    local($_, $/);
    $/ = "\n";
    my($status, $match, $hosts) = (HOST_NEW);
    while (<FH>) {
        chomp;
        my($hosts, $keyblob) = split /\s+/, $_, 2;
        next unless $hosts and $keyblob;
        my $fkey;
        ## Trap errors for unsupported key types (eg. if
        ## known_hosts has an entry for an ssh-rsa key, and
        ## we don't have Crypt::RSA installed).
        eval {
            $fkey = $key_class->extract_public($keyblob);
        };
        next if $@;
        for my $h (split /,/, $hosts) {
            if ($h eq $host) {
                if ($key->equal($fkey)) {
                    close FH;
                    return HOST_OK;
                }
                $status = HOST_CHANGED;
            }
        }
    }
    $status;
}

sub _add_host_to_hostfile {
    my($host, $hostfile, $key) = @_;
    unless (-e $hostfile) {
        require File::Basename;
        my $dir = File::Basename::dirname($hostfile);
        unless (-d $dir) {
            require File::Path;
            File::Path::mkpath([ $dir ])
                or die "Can't create directory $dir: $!";
        }
    }
    open FH, ">>" . $hostfile or croak "Can't write to $hostfile: $!";
    print FH join(' ', $host, $key->dump_public), "\n";
    close FH or croak "Can't close $hostfile: $!";
}

1;
