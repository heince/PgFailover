#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: select_query.pl
#
#        USAGE: ./select_query.pl  
#
#  DESCRIPTION: helper for select query
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan
#       EMAIL : heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 06/18/18 19:55:31
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use FindBin qw|$Bin|;
use lib "$Bin/../lib";
use Pg::Failover::Config;

$ENV{ITG_ROOT} = "$Bin/..";
my $interval = 1;
my $conf     = Pg::Failover::Config->new();
my $dbconf   = $conf->get_config('db');
my $netconf  = $conf->get_config('network');
my $dbport   = $$dbconf{dbport} // 5432;

while (1)
{
    my $query = `psql "connect_timeout=1 dbname=$$dbconf{dbname}" -U $$dbconf{dbuser} -h $$netconf{vip} -p $dbport -c "$$dbconf{query}"`;
    if ($? == 0)
    {
        print "ok\n";
    }    
    else
    {
        print "not ok\n";
    }
    sleep $interval;
}

