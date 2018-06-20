#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: secondary.pl
#
#        USAGE: ./secondary.pl  
#
#  DESCRIPTION: main secondary node program
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan
#       EMAIL : heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 06/18/18 20:19:07
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use FindBin qw|$Bin|;
use lib "$Bin/../lib";
use Pg::Failover::Config;

$SIG{'INT'}     = 'INT_handler';
$ENV{ITG_ROOT}  = "$Bin/../";
my $interval    = 1;
my $loop        = 1;
my $output;
my $conf = Pg::Failover::Config->new();

#-------------------------------------------------------------------------------
#  Initial check
#-------------------------------------------------------------------------------
my $nodeconf = $conf->get_config('node');
die "Exiting, not a secondary node\n" unless $$nodeconf{role} eq 'secondary';

#-------------------------------------------------------------------------------
#  handle query DB
#-------------------------------------------------------------------------------
my $db_threshold = 10;
my @db_container;
my $dbconf = $conf->get_config('db');
die "db configuration not complete\n" unless $conf->validate_db_config($dbconf);

open my $query, "$ENV{ITG_ROOT}/bin/select_query.pl |" or die "$!\n";

#-------------------------------------------------------------------------------
#  handle dns ping
#-------------------------------------------------------------------------------
my @dns_container;
my $netconf = $conf->get_config('network');
die "network configuration not complete\n" unless $conf->validate_network_config($netconf);

open my $dns_ping, ping_command($$netconf{dns_ip}) . '|' or die "$!\n";

#-------------------------------------------------------------------------------
#  handle gw ping
#-------------------------------------------------------------------------------
my @gw_container;
die "gw_ip must be configured\n" unless exists $$netconf{gw_ip};
die "gw_timeout must be configured\n" unless exists $$netconf{gw_timeout};

open my $gw_ping, ping_command($$netconf{gw_ip}) . '|' or die "$!\n";

while ($loop == 1)
{
    #-------------------------------------------------------------------------------
    #  SQL Query
    #-------------------------------------------------------------------------------
    $output = <$query>;
    unless (query_valid($output))
    {
        check_db_threshold();
    }   
    else
    {
        print "query db ok\n";
    }

    #-------------------------------------------------------------------------------
    #  DNS Ping
    #-------------------------------------------------------------------------------
    $output = <$dns_ping>;
    unless ($output =~ /^PING/)
    {
        unless (ping_valid($output))
        {
            check_dns_timeout();
        }
        else
        {
            print "ping DNS ok\n";
        }
    }

    #-------------------------------------------------------------------------------
    #  Gateway Ping
    #-------------------------------------------------------------------------------
    $output = <$gw_ping>;
    unless ($output =~ /^PING/)
    {
        unless (ping_valid($output))
        {
            check_gw_timeout();
        }
        else
        {
            print "ping Gateway ok\n";
        }
    }

    sleep $interval;
}

cleanup();

sub ping_valid
{
    my $line = shift;

    return 1 if $line =~ /^(\d+ bytes from)/;
    return 0;
}

sub ping_command
{
    my $ip = shift;

    die "ip not defined\n" unless $ip;

    if ($^O =~ /(linux|darwin)/)
    {
        return "ping $ip";
    }
    elsif ($^O eq 'solaris')
    {
        return "ping -s $ip";
    }
    else
    {
        die "unsupported platform: $^O\n";
    }
}

sub check_gw_timeout
{
    if ($#gw_container == $$netconf{gw_timeout} - 1)
    {
        stop_db_services();
        $loop = 0;
    }
    elsif ($#gw_container == -1)
    {
        print "first adding failed gw query\n";
        push @gw_container, time;
    }
    elsif ((time - $gw_container[0]) > $$netconf{gw_timeout})
    {
        reset_gw_container();
    }
    else
    {
        print "adding failed gw ping\n";
        push @gw_container, time;
    }
}

sub check_dns_timeout
{
    if ($#dns_container == $$netconf{dns_timeout} - 1)
    {
        stop_db_services();
        $loop = 0;
    }
    elsif ($#dns_container == -1)
    {
        print "first adding failed dns query\n";
        push @dns_container, time;
    }
    elsif ((time - $dns_container[0]) > $$netconf{dns_timeout})
    {
        reset_dns_container();
    }
    else
    {
        print "adding failed dns ping\n";
        push @dns_container, time;
    }
}

sub check_db_threshold
{
    if ($#db_container == $db_threshold - 1)
    {
        stop_db_services();
        $loop = 0;
    }
    elsif ($#db_container == -1)
    {
        print "first adding failed query\n";
        push @db_container, time;
    }
    elsif ((time - $db_container[0]) > $db_threshold)
    {
        reset_db_container();
    }
    else
    {
        print "adding failed query\n";
        push @db_container, time;
    }
}

sub stop_db_services
{
    print "removing vip\n";
    if (remove_vip())
    {
        print "vip removed\n";
    }
    else
    {
        print "Failed to remove virtual IP\n";
    }

    print "stop db failed\n" unless stop_db();
}

sub stop_db
{
    my $cmd = `$ENV{ITG_ROOT}/bin/stop_db.sh`;
    return 1 if $? == 0;
    return 0;
}

sub remove_vip
{
    my $cmd = `$ENV{ITG_ROOT}/bin/stop_vip.sh`;
    return 1 if $? == 0;
    return 0;
}

sub reset_db_container
{
    print "reseting db container\n";
    @db_container = ();
}

sub reset_dns_container
{
    print "reseting dns container\n";
    @dns_container = ();
}

sub reset_gw_container
{
    print "reseting gw container\n";
    @gw_container = ();
}

sub query_valid
{
    my $line = shift;

    return 1 if $line =~ /^ok/;
    return 0;
}

sub cleanup
{
    close $query;
    close $dns_ping;
    close $gw_ping;
}

sub INT_handler
{
    print "Interupted ...\n";
    cleanup();
    exit 0;
}
