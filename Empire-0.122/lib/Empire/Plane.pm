package Empire::Plane;
# Empire Plane object

use strict;
use warnings;
use Carp;

our %pdumpfield = (own=>0,id=>0,type=>'f1',x=>0,y=>0,wing=>'~',
		   eff=>10,mob=>0,tech=>100,att=>0,def=>0,acc=>0,
		   react=>0,range=>0,load=>1,fuel=>1,hard=>0,ship=>-1,
		   land=>-1,laun=>'N',orb=>'N',nuke=>'N/A',grd=>'G');
sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {%pdumpfield};
    my $planefield = shift;
    my $planevalue = shift;

    for (@{$planefield}) {
	$self->{$_} = shift @{$planevalue};
    }
    bless $self,$class;
    return $self;
}
sub refresh {

    my $self = {};
    my $planefield = shift;
    my $planevalue = shift;

    for (@{$planevalue}) {
	$self->{shift @{$planefield}} = $_;
    }
}
sub own    {my $plane = shift;  return $plane->{own}};
sub id     {my $plane = shift;  return $plane->{id}};
sub plane  {my $plane = shift;  return $plane->id()};
sub type   {my $plane = shift;  return $plane->{type}};
sub xcoord {my $plane = shift;  return $plane->{x}};
sub ycoord {my $plane = shift;  return $plane->{y}};
sub wing   {my $plane = shift;  return $plane->{wing}};
sub eff    {my $plane = shift;  return $plane->{eff}};
sub mob    {my $plane = shift;  return $plane->{mob}};
sub tech   {my $plane = shift;  return $plane->{tech}};
sub att    {my $plane = shift;  return $plane->{att}};
sub def    {my $plane = shift;  return $plane->{def}};
sub fuel   {my $plane = shift;  return $plane->{fuel}};
sub acc    {my $plane = shift;  return $plane->{acc}};
sub react  {my $plane = shift;  return $plane->{react}};
sub range  {my $plane = shift;  return $plane->{range}};
sub load   {my $plane = shift;  return $plane->{load}};
sub hard   {my $plane = shift;  return $plane->{hard}};
sub ship   {my $plane = shift;  return $plane->{ship}};
sub land   {my $plane = shift;  return $plane->{land}};
sub laun   {my $plane = shift;  return $plane->{laun}};
sub orb    {my $plane = shift;  return $plane->{orb}};
sub nuke   {my $plane = shift;  return $plane->{nuke}};
sub grd    {my $plane = shift;  return $plane->{grd}};
sub name   {my $plane = shift;  return $plane->{name}};
sub tstamp {my $plane = shift;  return $plane->{timestamp}};
1;
