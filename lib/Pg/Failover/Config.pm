#
#===============================================================================
#
#         FILE: Config.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan (), heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 06/08/18 01:40:50
#     REVISION: ---
#===============================================================================
package Pg::Failover::Config;
use strict;
use warnings;

sub new 
{
    my $self = shift;
    return $self;
}

#-------------------------------------------------------------------------------
#  return hash config
#  valid type: db|network|node
#-------------------------------------------------------------------------------
sub get_config
{
    my ($self, $type) = @_;

    if($type eq 'db')
    {
        return $self->parse("$ENV{ITG_ROOT}/etc/db.conf");
    }
    elsif($type eq 'node')
    {
        return $self->parse("$ENV{ITG_ROOT}/etc/node.conf");
    }
    elsif($type eq 'network')
    {
        return $self->parse("$ENV{ITG_ROOT}/etc/network.conf");
    }
    else
    {
        die "config type not supported: $type\n";
    }
}

sub validate_db_config
{
    my ($self,$conf) = @_;

    return 0 unless defined $$conf{dbuser};
    return 0 unless defined $$conf{dbname};
    return 0 unless defined $$conf{query};
    return 0 unless defined $$conf{query_timeout};
    return 0 unless defined $$conf{connect_timeout};
    return 1;
}

sub validate_network_config
{
    my ($self,$conf) = @_;

    return 0 unless defined $$conf{vip};
    return 0 unless defined $$conf{dns_ip};
    return 0 unless defined $$conf{dns_timeout};
    return 0 unless defined $$conf{gw_ip};
    return 0 unless defined $$conf{gw_timeout};
    return 1;
}

sub parse
{
    my ($self, $file) = @_;

    my %result;
    open(my $fh, '<', $file) or die "$!\n";
    while(<$fh>)
    {
        chomp;
        next unless /^\w+/; # start with word
        next unless / \=\> /; # contain '=>' splitter

        my @tmp = split ' => ', $_;
        $tmp[0] =~ s/\s+//g if exists $tmp[0]; # remove space
        $tmp[1] =~ s/\s+$// if exists $tmp[1]; # remove space at the end of line
        $result{$tmp[0]} = $tmp[1]; 
    }

    close $fh;

    return \%result;
}

sub get_psql
{
    my ($self, $conf) = shift;

    my $psql = defined $$conf{psql_path} ? $$conf{psql_path} : 'psql';
    return $psql;
}

sub print_config
{
    my $self = shift;
    print "halo\n";
}

1;

