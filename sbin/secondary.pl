#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: secondary.pl
#
#        USAGE: ./secondary.pl  
#
#  DESCRIPTION: main secondary program
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
die "Exiting, not a secondary node\n" unless $$nodeconf{role} eq 'secondary';
die "db configuration not complete\n" unless $conf->validate_db_config($dbconf);
die "network configuration not complete\n" unless $conf->validate_network_config($netconf);

#-------------------------------------------------------------------------------
#  handle query DB
#-------------------------------------------------------------------------------
my @db_container;

open my $query, "$ENV{ITG_ROOT}/bin/select_query.pl |" or die "$!\n";

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

    sleep $interval;
}

cleanup();

sub ping_valid
{
    my $line = shift;

    return 1 if $line =~ /^(\d+ bytes from)/;
    return 0;
}

sub ping_command_once
{
    my $ip = shift;

    die "ip not defined\n" unless $ip;

    if ($^O =~ /(linux|darwin)/)
    {
        return "ping -c 1 $ip";
    }
    elsif ($^O eq 'solaris')
    {
        return "ping -s $ip 64 1";
    }
    else
    {
        die "unsupported platform: $^O\n";
    }
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

sub check_db_timeout
{
    if ($#db_container == $$dbconf{query_timeout} - 1)
    {
        if (check_ping())
        {
            cleanup();

            if(promote_to_primary())
            {
                $loop = 0;
                last;
            }
            else
            {
                $log->info("failed promote to primary");
                reset_db_container();
            }
        }
        else
        {
            reset_db_container();
        }
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

sub check_ping
{
    my $cmd = ping_command_once($$netconf{vip});
    `$cmd`;
    if ($? == 0)
    {
        $log->info('cancel promote, vip is pingable');
        return 0;
    }

    my $stat = 0; # if ping dns and gw ok, return true
    $cmd = ping_command_once($$netconf{dns_ip});
    `$cmd`;
    if ($? == 0)
    {
        $log->info('ping dns ok');
        $stat += 1;
    }

    $cmd = ping_command_once($$netconf{gw_ip});
    `$cmd`;
    if ($? == 0)
    {
        $log->info('ping gw ok');
        $stat += 1;
    }

    return 1 if $stat == 2;
    return 0;
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

sub promote_to_primary
{
    my $cmd = `$ENV{ITG_ROOT}/bin/promote.sh`;
    return 1 if $? == 0;
    return 0;
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

sub query_valid
{
    my $line = shift;

    return 1 if $line =~ /^ok/;
    return 0;
}

sub cleanup
{
    close $query;
}

sub INT_handler
{
    $log->info("Interupted ...");
    cleanup();
    exit 0;
}
