# $Id: Hosts.pm,v 1.9 2008/10/02 20:46:17 turnstep Exp $

package Net::SSH::Perl::Util::Hosts;
use strict;

use Net::SSH::Perl::Constants qw( :hosts );

use Carp qw( croak );

sub _check_host_in_hostfile {
    my($host, $hostfile, $key) = @_;
    my $key_class = ref($key);

	# ssh returns HOST_NEW if the host file can't be opened
    open my $fh, '<', $hostfile or return HOST_NEW;
    local($_, $/);
    $/ = "\n";
    my($status, $match, $hosts) = (HOST_NEW);
    while (<$fh>) {
        chomp;
        my($hosts, $keyblob) = split /\s+/, $_, 2;
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
                    close $fh or warn qq{Could not close "$hostfile": $!\n};
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
    open my $fh, '>>', $hostfile or croak "Can't write to $hostfile: $!";
    print $fh join(' ', $host, $key->dump_public), "\n";
    close $fh or croak "Can't close $hostfile: $!";
}

1;
