package Empire::SectorType;
# Empire SectorType object

use strict;
use warnings;
use Carp;

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless $self,$class;
    return $self;
}
1;
