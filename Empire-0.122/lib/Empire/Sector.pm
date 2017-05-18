package Empire::Sector;
# Empire Sector object

use strict;
use warnings;
use Carp;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%dumpfield);
our %dumpfield = (own=>0,x=>0,y=>0,des=>'.',bdes=>'.',sdes=>'_',
		  eff=>0,mob=>0,oldown=>0,off=>'.',
		  min=>0,gold=>0,fert=>0,ocontent=>0,uran=>0,
		  work=>0,avail=>0,terr=>0,
		  civ=>0,mil=>0,uw=>0,food=>0,
		  shell=>0,gun=>0,pet=>0,iron=>0,dust=>0,
		  bar=>0,oil=>0,lcm=>0,hcm=>0,rad=>0,
		  u_del=>'.',f_del=>'.',s_del=>'.',g_del=>'.',p_del=>'.',
		  i_del=>'.',d_del=>'.',b_del=>'.',o_del=>'.',l_del=>'.',
		  h_del=>'.',r_del=>'.',
		  u_cut=>0,f_cut=>0,s_cut=>0,g_cut=>0,p_cut=>0,i_cut=>0,
		  d_cut=>0,b_cut=>0,o_cut=>0,l_cut=>0,h_cut=>0,r_cut=>0,
		  dist_x=>0,dist_y=>0,
		  c_dist=>0,m_dist=>0,u_dist=>0,f_dist=>0,
		  s_dist=>0,g_dist=>0,p_dist=>0,i_dist=>0,d_dist=>0,
		  b_dist=>0,o_dist=>0,l_dist=>0,h_dist=>0,r_dist=>0,
		  road=>0,rail=>0,defense=>0,fallout=>0,coast=>1,
		  c_del=>'.', m_del=>'.',c_cut=>0,m_cut=>0,
		  terr1=>0,terr2=>0,terr3=>0,timestamp=>1);
sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {%dumpfield};
    my $sectorfield = shift;
    my $sectorvalue = shift;

    for (@{$sectorvalue}) {
	$self->{shift @{$sectorfield}} = $_;
    }
    bless $self,$class;
    if (defined $self->{sdes} && $self->sdes() eq '_') {
	$self->{sdes} = $self->des();
    }
    return $self;
}
sub refresh {

    my $self = {};
    my $sectorfield = shift;
    my $sectorvalue = shift;

    for (@{$sectorvalue}) {
	$self->{shift @{$sectorfield}} = $_;
    }
}
sub sect     {my $sector = shift; return "$sector->{x},$sector->{y}"};
sub own      {my $sector = shift; return $sector->{own}};
sub timestamp{my $sector = shift; return $sector->{timestamp}};
sub xcoord   {my $sector = shift; return $sector->{x}};
sub ycoord   {my $sector = shift; return $sector->{y}};
sub des      {my $sector = shift; return $sector->{des} || $sector->{bdes}};
sub bdes     {my $sector = shift; return $sector->{bdes}};
sub sdes     {my $sector = shift; return $sector->{sdes}};
sub eff      {my $sector = shift; return $sector->{eff}};
sub mob      {my $sector = shift; return $sector->{mob}};
sub oldown   {my $sector = shift; return $sector->{'*'}};
sub off      {my $sector = shift; return $sector->{off}};
sub min      {my $sector = shift; return $sector->{min}};
sub gold     {my $sector = shift; return $sector->{gold}};
sub fert     {my $sector = shift; return $sector->{fert}};
sub ocontent {my $sector = shift; return $sector->{ocontent}};
sub uran     {my $sector = shift; return $sector->{uran}};
sub work     {my $sector = shift; return $sector->{work}};
sub avail    {my $sector = shift; return $sector->{avail}};
sub terr     {my $sector = shift; return $sector->{terr}};
sub civ      {my $sector = shift; return $sector->{civ}};
sub mil      {my $sector = shift; return $sector->{mil}};
sub uw       {my $sector = shift; return $sector->{uw}};
sub food     {my $sector = shift; return $sector->{food}};
sub shell    {my $sector = shift; return $sector->{shell}};
sub gun      {my $sector = shift; return $sector->{gun}};
sub pet      {my $sector = shift; return $sector->{pet}};
sub iron     {my $sector = shift; return $sector->{iron}};
sub dust     {my $sector = shift; return $sector->{dust}};
sub bar      {my $sector = shift; return $sector->{bar}};
sub oil      {my $sector = shift; return $sector->{oil}};
sub lcm      {my $sector = shift; return $sector->{lcm}};
sub hcm      {my $sector = shift; return $sector->{hcm}};
sub rad      {my $sector = shift; return $sector->{rad}};
sub u_del    {my $sector = shift; return $sector->{u_del}};
sub f_del    {my $sector = shift; return $sector->{f_del}};
sub s_del    {my $sector = shift; return $sector->{s_del}};
sub g_del    {my $sector = shift; return $sector->{g_del}};
sub p_del    {my $sector = shift; return $sector->{p_del}};
sub i_del    {my $sector = shift; return $sector->{i_del}};
sub d_del    {my $sector = shift; return $sector->{d_del}};
sub b_del    {my $sector = shift; return $sector->{b_del}};
sub o_del    {my $sector = shift; return $sector->{o_del}};
sub l_del    {my $sector = shift; return $sector->{l_del}};
sub h_del    {my $sector = shift; return $sector->{h_del}};
sub r_del    {my $sector = shift; return $sector->{r_del}};
sub u_cut    {my $sector = shift; return $sector->{u_cut}};
sub f_cut    {my $sector = shift; return $sector->{f_cut}};
sub s_cut    {my $sector = shift; return $sector->{s_cut}};
sub g_cut    {my $sector = shift; return $sector->{g_cut}};
sub p_cut    {my $sector = shift; return $sector->{p_cut}};
sub i_cut    {my $sector = shift; return $sector->{i_cut}};
sub d_cut    {my $sector = shift; return $sector->{d_cut}};
sub b_cut    {my $sector = shift; return $sector->{b_cut}};
sub o_cut    {my $sector = shift; return $sector->{o_cut}};
sub l_cut    {my $sector = shift; return $sector->{l_cut}};
sub h_cut    {my $sector = shift; return $sector->{h_cut}};
sub r_cut    {my $sector = shift; return $sector->{r_cut}};
sub distx    {my $sector = shift; return $sector->{dist_x}};
sub disty    {my $sector = shift; return $sector->{dist_y}};
sub c_dist   {my $sector = shift; return $sector->{c_dist}};
sub m_dist   {my $sector = shift; return $sector->{m_dist}};
sub u_dist   {my $sector = shift; return $sector->{u_dist}};
sub f_dist   {my $sector = shift; return $sector->{f_dist}};
sub s_dist   {my $sector = shift; return $sector->{s_dist}};
sub g_dist   {my $sector = shift; return $sector->{g_dist}};
sub p_dist   {my $sector = shift; return $sector->{p_dist}};
sub i_dist   {my $sector = shift; return $sector->{i_dist}};
sub d_dist   {my $sector = shift; return $sector->{d_dist}};
sub b_dist   {my $sector = shift; return $sector->{b_dist}};
sub o_dist   {my $sector = shift; return $sector->{o_dist}};
sub l_dist   {my $sector = shift; return $sector->{l_dist}};
sub h_dist   {my $sector = shift; return $sector->{h_dist}};
sub r_dist   {my $sector = shift; return $sector->{r_dist}};
sub road     {my $sector = shift; return $sector->{road}};
sub rail     {my $sector = shift; return $sector->{rail}};
sub defense  {my $sector = shift; return $sector->{defense}};
sub fallout  {my $sector = shift; return $sector->{fallout}};
sub coast    {my $sector = shift; return $sector->{coast}};
sub c_del    {my $sector = shift; return $sector->{c_del}};
sub m_del    {my $sector = shift; return $sector->{m_del}};
sub c_cut    {my $sector = shift; return $sector->{c_cut}};
sub m_cut    {my $sector = shift; return $sector->{m_cut}};
sub terr1    {my $sector = shift; return $sector->{terr1}};
sub terr2    {my $sector = shift; return $sector->{terr2}};
sub terr3    {my $sector = shift; return $sector->{terr3}};
sub dumpfd   {my $sector = shift; my @df = keys %dumpfield; return @df};
1;
