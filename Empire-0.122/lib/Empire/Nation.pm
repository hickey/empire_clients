package Empire::Nation;
# Empire Nation object

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
sub cnum           { my ($nation) = shift; return $nation->{cnum};}
sub name           { my ($nation) = shift; return $nation->{name};}
sub btu            { my ($nation) = shift; return $nation->{btu};}
sub nstatus        { my ($nation) = shift; return $nation->{nstatus};}
sub capital        { my ($nation) = shift; return $nation->{capital};}
sub capitaleff     { my ($nation) = shift; return $nation->{capital}{eff};}
sub capitalcoord   { my ($nation) = shift; return $nation->{capital}{coord};}
sub capitalciv     { my ($nation) = shift; return $nation->{capital}{civ};}
sub capitalmil     { my ($nation) = shift; return $nation->{capital}{mil};}
sub treasury       { my ($nation) = shift; return $nation->{treasury};}
sub reserves       { my ($nation) = shift; return $nation->{reserves};}
sub education      { my ($nation) = shift; return $nation->{education};}
sub happiness      { my ($nation) = shift; return $nation->{happiness};}
sub technology     { my ($nation) = shift; return $nation->{technology};}
sub research       { my ($nation) = shift; return $nation->{research};}
sub techfactor     { my ($nation) = shift; return $nation->{techfactor};}
sub plagchance     { my ($nation) = shift; return $nation->{plagchance};}
sub maxpop         { my ($nation) = shift; return $nation->{maxpop};}
sub maxsafeciv     { my ($nation) = shift; return $nation->{maxsafeciv};}
sub maxsafeuw      { my ($nation) = shift; return $nation->{maxsafeuw};}
sub hapneeded      { my ($nation) = shift; return $nation->{hapneeded};}
sub sects {my ($nation) = shift; return $nation->{sects}}
sub eff   {my ($nation) = shift; return $nation->{eff}}
sub civ   {my ($nation) = shift; return $nation->{civ}}
sub mil   {my ($nation) = shift; return $nation->{mil}}
sub shell {my ($nation) = shift; return $nation->{shell}}
sub gun   {my ($nation) = shift; return $nation->{gun}}
sub pet   {my ($nation) = shift; return $nation->{pet}}
sub iron  {my ($nation) = shift; return $nation->{iron}}
sub dust  {my ($nation) = shift; return $nation->{dust}}
sub oil   {my ($nation) = shift; return $nation->{oil}}
sub food  {my ($nation) = shift; return $nation->{food}}
sub ship  {my ($nation) = shift; return $nation->{ship}}
sub pln   {my ($nation) = shift; return $nation->{pln}}
sub unit  {my ($nation) = shift; return $nation->{unit}}

sub relations {

    my ($nation,$enemy) = @_;

    if (defined $enemy) {
	return $nation->{relations}->[$enemy];
    }
    else {
	return $nation->{relations};
    }
}
1;

