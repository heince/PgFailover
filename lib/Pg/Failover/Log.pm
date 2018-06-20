#
#===============================================================================
#
#         FILE: Log.pm
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
package Pg::Failover::Log;
use strict;
use warnings;

sub new 
{
    my $self = shift;
    return $self;
}

sub info
{
    my ($self, $msg) = @_;

    print time . ' | ' . "$msg\n";
}

1;
