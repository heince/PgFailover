#
#===============================================================================
#
#         FILE: 02-config-node.t
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

print "# Testing if file exist on etc/node.conf\n";
ok(-f "$ENV{ITG_ROOT}/etc/node.conf");

print "# Testing if option 'role' exist and has a value\n";
my $conf    = Pg::Failover::Config->new();
my $parsed  = $conf->get_config('node');
#print Dumper $parsed;
ok($$parsed{role}, '/(primary|secondary)$/');
