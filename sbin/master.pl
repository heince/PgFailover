#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: master.pl
#
#        USAGE: ./master.pl  
#
#  DESCRIPTION: main master program
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
use Pg::Failover::Log;

$SIG{'INT'}     = 'INT_handler';
$ENV{ITG_ROOT}  = "$Bin/../";
my $interval    = 1;
my $loop        = 1;
my $output;
my $conf = Pg::Failover::Config->new();
my $log  = Pg::Failover::Log->new();

#-------------------------------------------------------------------------------
#  Initial check
#-------------------------------------------------------------------------------
my $nodeconf = $conf->get_config('node');
my $dbconf  = $conf->get_config('db');
my $netconf = $conf->get_config('network');
die "Exiting, not a primary node\n" unless $$nodeconf{role} eq 'primary';
die "db configuration not complete\n" unless $conf->validate_db_config($dbconf);
die "network configuration not complete\n" unless $conf->validate_network_config($netconf);

#-------------------------------------------------------------------------------
#  Start Virtual IP
#-------------------------------------------------------------------------------
die "Starting Virtual IP failed\n" unless start_vip();

#-------------------------------------------------------------------------------
#  handle query DB
#-------------------------------------------------------------------------------
my @db_container;

open my $query, "$ENV{ITG_ROOT}/bin/select_query.pl |" or die "$!\n";

#-------------------------------------------------------------------------------
#  handle dns ping
#-------------------------------------------------------------------------------
my @dns_container;

#die "dns_ip must be configured\n" unless exists $$netconf{dns_ip};
#die "dns_timeout must be configured\n" unless exists $$netconf{dns_timeout};

open my $dns_ping, ping_command($$netconf{dns_ip}) . '|' or die "$!\n";

#-------------------------------------------------------------------------------
#  handle gw ping
#-------------------------------------------------------------------------------
my @gw_container;
#die "gw_ip must be configured\n" unless exists $$netconf{gw_ip};
#die "gw_timeout must be configured\n" unless exists $$netconf{gw_timeout};

open my $gw_ping, ping_command($$netconf{gw_ip}) . '|' or die "$!\n";

LOOP:
while ($loop == 1)
{
    #-------------------------------------------------------------------------------
    #  SQL Query
    #-------------------------------------------------------------------------------
    $output = <$query>;
    unless (query_valid($output))
    {
        check_db_timeout();
    }   
    else
    {
        $log->info("query db ok");
        reset_db_container();
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
            $log->info("ping DNS ok");
            reset_dns_container();
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
            $log->info("ping Gateway ok");
            reset_gw_container();
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
        last;
    }
    elsif ($#gw_container == -1)
    {
        $log->info("first adding failed gw query");
        push @gw_container, time;
    }
    else
    {
        $log->info("adding failed gw ping");
        push @gw_container, time;
    }
}

sub check_dns_timeout
{
    if ($#dns_container == $$netconf{dns_timeout} - 1)
    {
        stop_db_services();
        $loop = 0;
        last;
    }
    elsif ($#dns_container == -1)
    {
        $log->info("first adding failed dns query");
        push @dns_container, time;
    }
    else
    {
        $log->info("adding failed dns ping");
        push @dns_container, time;
    }
}

sub check_db_timeout
{
    if ($#db_container == $$dbconf{query_timeout} - 1)
    {
        stop_db_services();
        $loop = 0;
        last;
    }
    elsif ($#db_container == -1)
    {
        $log->info("first adding failed query");
        push @db_container, time;
    }
    else
    {
        $log->info("adding failed query");
        push @db_container, time;
    }
}

sub stop_db_services
{
    cleanup();

    $log->info("removing vip");
    if (remove_vip())
    {
        $log->info("vip removed");
    }
    else
    {
        $log->info("Failed to remove virtual IP");
    }

    return stop_db();
}

sub stop_db
{
    my $cmd = `$ENV{ITG_ROOT}/bin/stop_db.sh`;
    return 1 if $? == 0;
    return 0;
}

sub start_vip
{
    my $cmd = `$ENV{ITG_ROOT}/bin/start_vip.sh`;
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
    $log->info("reseting db container");
    @db_container = ();
}

sub reset_dns_container
{
    $log->info("reseting dns container");
    @dns_container = ();
}

sub reset_gw_container
{
    $log->info("reseting gw container");
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
    $log->info("Interupted ...");
    cleanup();
    exit 0;
}
