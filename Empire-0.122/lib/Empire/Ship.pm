package Empire::Ship;
# Empire Ship object

use strict;
use warnings;
use Carp;

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my $shipfield = shift;
    my $shipvalue = shift;

    for (@{$shipfield}) {
	$self->{$_} = shift @{$shipvalue};
	if ($_ eq 'x' && $self->{$_} !~ /\d/) {
	    $self->{$_} = shift @{$shipvalue};
	}
    }
    bless $self,$class;
    return $self;
}
sub refresh {

    my $self = shift;
    my $shipfield = shift;
    my $shipvalue = shift;

    for (@{$shipfield}) {
	$self->{$_} = shift @{$shipvalue};
	if ($_ eq 'x' && $self->{$_} !~ /\d/) {
	    $self->{$_} = shift @{$shipvalue};
	}
    }
}
sub own    {my $ship = shift;  return $ship->{own}};
sub id     {my $ship = shift;  return $ship->{id}};
sub ship   {my $ship = shift;  return $ship->id()};
sub type   {my $ship = shift;  return $ship->{type}};
sub xcoord {my $ship = shift;  return $ship->{x}};
sub ycoord {my $ship = shift;  return $ship->{y}};
sub flt    {my $ship = shift;  return $ship->{flt}};
sub eff    {my $ship = shift;  return $ship->{eff}};
sub civ    {my $ship = shift;  return $ship->{civ}};
sub mil    {my $ship = shift;  return $ship->{mil}};
sub uw     {my $ship = shift;  return $ship->{uw}};
sub food   {my $ship = shift;  return $ship->{food}};
sub pln    {my $ship = shift;  return $ship->{pln}};
sub he     {my $ship = shift;  return $ship->{he}};
sub xl     {my $ship = shift;  return $ship->{xl}};
sub land   {my $ship = shift;  return $ship->{land}};
sub mob    {my $ship = shift;  return $ship->{mob}};
sub fuel   {my $ship = shift;  return $ship->{fuel}};
sub tech   {my $ship = shift;  return $ship->{tech}};
sub shell  {my $ship = shift;  return $ship->{shell}};
sub gun    {my $ship = shift;  return $ship->{gun}};
sub petrol {my $ship = shift;  return $ship->{petrol}};
sub iron   {my $ship = shift;  return $ship->{iron}};
sub dust   {my $ship = shift;  return $ship->{dust}};
sub bar    {my $ship = shift;  return $ship->{bar}};
sub oil    {my $ship = shift;  return $ship->{oil}};
sub lcm    {my $ship = shift;  return $ship->{lcm}};
sub hcm    {my $ship = shift;  return $ship->{hcm}};
sub rad    {my $ship = shift;  return $ship->{rad}};
sub def    {my $ship = shift;  return $ship->{def}};
sub spd    {my $ship = shift;  return $ship->{spd}};
sub vis    {my $ship = shift;  return $ship->{vis}};
sub rng    {my $ship = shift;  return $ship->{rng}};
sub fir    {my $ship = shift;  return $ship->{fir}};
sub origx  {my $ship = shift;  return $ship->{origx}};
sub origy  {my $ship = shift;  return $ship->{origy}};
sub name   {my $ship = shift;  return $ship->{name}};
sub tstamp {my $ship = shift;  return $ship->{timestamp}};
1;
