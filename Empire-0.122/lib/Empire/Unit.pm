package Empire::Unit;
# Empire Unit object

use strict;
use warnings;
use Carp;

our %ldumpfield = (own=>0,id=>0,type=>'cav',x=>0,y=>0,army=>'~',
		   eff=>10,mil=>0,fort=>0,mob=>0,food=>0,fuel=>0,
		   tech=>50,retr=>42,react=>0,xl=>0,nland=>0,land=>-1,
		   ship=>-1,shell=>0,gun=>0,petrol=>0,iron=>0,dust=>0,
		   bar=>0,oil=>0,lcm=>0,hcm=>0,rad=>0,att=>0,def=>0,
		   vul=>0,spd=>0,vis=>0,spy=>0,radius=>0,frg=>0,
		   acc=>0,dam=>0,amm=>0,aaf=>0);
sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {%ldumpfield};
    my $unitfield = shift;
    my $unitvalue = shift;

    for (@{$unitfield}) {
	$self->{$_} = shift @{$unitvalue};
    }
    bless $self,$class;
    return $self;
}
sub refresh {

    my $self = {};
    my $unitfield = shift;
    my $unitvalue = shift;

    for (@{$unitvalue}) {
	$self->{shift @{$unitfield}} = $_;
    }
}
sub own    {my $unit = shift;  return $unit->{own}};
sub id     {my $unit = shift;  return $unit->{id}};
sub unit   {my $unit = shift;  return $unit->id()};
sub type   {my $unit = shift;  return $unit->{type}};
sub xcoord {my $unit = shift;  return $unit->{x}};
sub ycoord {my $unit = shift;  return $unit->{y}};
sub army   {my $unit = shift;  return $unit->{army}};
sub eff    {my $unit = shift;  return $unit->{eff}};
sub mil    {my $unit = shift;  return $unit->{mil}};
sub fort   {my $unit = shift;  return $unit->{fort}};
sub mob    {my $unit = shift;  return $unit->{mob}};
sub food   {my $unit = shift;  return $unit->{food}};
sub fuel   {my $unit = shift;  return $unit->{fuel}};
sub tech   {my $unit = shift;  return $unit->{tech}};
sub retr   {my $unit = shift;  return $unit->{retr}};
sub react  {my $unit = shift;  return $unit->{react}};
sub xl     {my $unit = shift;  return $unit->{xl}};
sub nland   {my $unit = shift;  return $unit->{nland}};
sub land   {my $unit = shift;  return $unit->{land}};
sub ship   {my $unit = shift;  return $unit->{ship}};
sub shell  {my $unit = shift;  return $unit->{shell}};
sub gun    {my $unit = shift;  return $unit->{gun}};
sub petrol {my $unit = shift;  return $unit->{petrol}};
sub iron   {my $unit = shift;  return $unit->{iron}};
sub dust   {my $unit = shift;  return $unit->{dust}};
sub bar    {my $unit = shift;  return $unit->{bar}};
sub oil    {my $unit = shift;  return $unit->{oil}};
sub lcm    {my $unit = shift;  return $unit->{lcm}};
sub hcm    {my $unit = shift;  return $unit->{hcm}};
sub rad    {my $unit = shift;  return $unit->{rad}};
sub att    {my $unit = shift;  return $unit->{att}};
sub def    {my $unit = shift;  return $unit->{def}};
sub vul    {my $unit = shift;  return $unit->{vul}};
sub spd    {my $unit = shift;  return $unit->{spd}};
sub vis    {my $unit = shift;  return $unit->{vis}};
sub radius {my $unit = shift;  return $unit->{radius}};
sub frg    {my $unit = shift;  return $unit->{frg}};
sub acc    {my $unit = shift;  return $unit->{acc}};
sub dam    {my $unit = shift;  return $unit->{dam}};
sub amm    {my $unit = shift;  return $unit->{amm}};
sub aaf    {my $unit = shift;  return $unit->{aaf}};
sub tstamp {my $unit = shift;  return $unit->{timestamp}};
1;
