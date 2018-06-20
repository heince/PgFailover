#
#===============================================================================
#
#         FILE: 00-platform.t
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

BEGIN { plan tests => 1 }

print "# testing supported OS must be darwin|linux|solaris\n";
ok "$^O", '/(darwin|linux|solaris)/';
