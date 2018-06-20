#
#===============================================================================
#
#         FILE: 03-config-network.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan (), heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 06/08/18 01:08:15
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Test;
use FindBin qw|$Bin|;
use lib "$Bin/../lib";
use Pg::Failover::Config;
use Data::Dumper;

BEGIN { plan tests => 2 }

# set ENV
$ENV{ITG_ROOT} = "$Bin/..";

print "# Testing if file exist on $ENV{ITG_ROOT}/etc/network.conf\n";
ok(-f "$ENV{ITG_ROOT}/etc/network.conf");

print "# Testing if option 'dns_check' exist and has a value\n";
my $conf    = Pg::Failover::Config->new();
my $parsed  = $conf->get_config('network');
print Dumper $parsed;
ok($$parsed{dns_check}, '/(1|0)$/');

