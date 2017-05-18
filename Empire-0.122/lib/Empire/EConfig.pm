package EConfig;

# Empire Econfig file object

use strict;
use warnings;
use Carp;

our @OPTION = qw(ALL_BLEED BLITZ BRIDGETOWERS DEMANDUPDATE EASY_BRIDGES FALLOUT GODNEWS INTERDICT_ATT LANDSPIES LOANS NEUTRON NEW_STARVE NEW_WORK NEWPOWER NO_PLAGUE NOFOOD NOMOBCOST NUKEFAILDETONATE ORBIT PINPOINTMISSILE PLANENAMES SAIL SHIPNAMES SHOWPLANE TREATIES UPDATESCHED BIG_CITY DEFENSE_INFRA DRNUKE FUEL GO_RENEW GRAB_THINGS HIDDEN LOSE_CONTACT MARKET MOB_ACCESS NO_FORT_FIRE NO_HCMS NO_LCMS NO_OIL NONUKES RES_POP ROLLOVER_AVAIL SHIP_DECAY SLOW_WAR SNEAK_ATTACK SUPER_BARS TECH_POP TRADESHIPS);
our @FIELD = qw(data info port privname privlog WORLD_X WORLD_Y update_policy etu_per_update s_p_etu adj_update update_window update_times hourslop blitz_time update_demandpolicy update_wantmin update_missed update_demandtimes game_days game_hours btu_build_rate m_m_p_d max_btus max_idle players_at_00 at_least_one_100 powe_cost war_cost easy_tech hard_tech start_tech start_happy start_research start_edu level_age_rate tech_log_base ally_factor edu_avg hap_avg edu_cons hap_cons startmob sect_mob_scale sect_mob_max buil_bh buil_bc buil_bt buil_tower_bh buil_tower_bc buil_tower_bt land_mob_scale land_grow_scale land_mob_max money_land morale_base plane_mob_scale plane_grow_scale plane_mob_max money_plane ship_mob_scale ship_grow_scale ship_mob_max money_ship torpedo_damage fort_max_interdiction_range land_max_interdiction_range ship_max_interdiction_range flakscale combat_mob people_damage unit_damage collateral_dam assault_penalty fire_range_factor sect_mob_neg_factor mission_mob_cost uwbrate money_civ money_mil money_res money_uw babyeat bankint eatrate fcrate fgrate obrate decay_per_etu fallout_spread drnuke_const MARK_DELAY TRADE_DELAY maxmult minmult buytax tradetax trade_1_dist trade_2_dist trade_3_dist trade_1 trade_2 trade_3 trade_ally_bonus trade_ally_cut fuel_mult lost_items_timeout last_demand_update);

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my $file = shift;

    bless $self,$class;
    if (!open (EC,$file)) {
	carp "Couldn't open econfig file $file. Empty object created\n";
    }
    my $comment;
    while (<EC>) {
	if (/^\#/) {
	    $comment = $_;
	}
	elsif (/^\S/) {
	    chomp;
	    my($field,$value) = split(/\s+/);
	    if ($field eq 'option') {
		$self->{options}->{comment} = $comment;
		$self->{options}->{$value} = 1;
	    }
	    elsif ($field eq 'nooption') {
		$self->{options}->{comment} = $comment;
		$self->{options}->{$value} = 0;
	    }
	    else {
		$self->{$field}->{comment} = $comment;
		$self->{$field}->{value} = $value;
	    }
	}
    }
    close EC;
    return $self;
}
sub write {

    my $self = shift;
    my $file = shift;

    if (!open(EC,">$file")) {
	croak("Couldn't write file $file\n");
	return;
    }
    for my $field (@FIELD) {
	print EC $self->{$field}->{comment};
	print EC $field . ' ' . $self->$field();
	print EC "\n\n";
    }
    print EC "$self->{options}->{comment}\n";
    for my $option (@OPTION) {
	if ($self->option($option) == 1) {
	    print EC "option $option\n";
	}
	else {
	    print EC "nooption $option\n";
	}
    }
    close EC;
}

sub data {

    my $self = shift;
    my $value = shift;

    $self->{data}->{value} = $value if defined $value;
    return $self->{data}->{value}
}
sub info {

    my $self = shift;
    my $value = shift;

    $self->{info}->{value} = $value if defined $value;
    return $self->{info}->{value}
}
sub port {

    my $self = shift;
    my $value = shift;

    $self->{port}->{value} = $value if defined $value;
    return $self->{port}->{value}
}
sub privname {

    my $self = shift;
    my $value = shift;

    $self->{privname}->{value} = $value if defined $value;
    return $self->{privname}->{value}
}
sub privlog {

    my $self = shift;
    my $value = shift;

    $self->{privlog}->{value} = $value if defined $value;
    return $self->{privlog}->{value}
}
sub WORLD_X {

    my $self = shift;
    my $value = shift;

    $self->{WORLD_X}->{value} = $value if defined $value;
    return $self->{WORLD_X}->{value}
}
sub WORLD_Y {

    my $self = shift;
    my $value = shift;

    $self->{WORLD_Y}->{value} = $value if defined $value;
    return $self->{WORLD_Y}->{value}
}
sub update_policy {

    my $self = shift;
    my $value = shift;

    $self->{update_policy}->{value} = $value if defined $value;
    return $self->{update_policy}->{value}
}
sub etu_per_update {

    my $self = shift;
    my $value = shift;

    $self->{etu_per_update}->{value} = $value if defined $value;
    return $self->{etu_per_update}->{value}
}
sub s_p_etu {

    my $self = shift;
    my $value = shift;

    $self->{s_p_etu}->{value} = $value if defined $value;
    return $self->{s_p_etu}->{value}
}
sub adj_update {

    my $self = shift;
    my $value = shift;

    $self->{adj_update}->{value} = $value if defined $value;
    return $self->{adj_update}->{value}
}
sub update_window {

    my $self = shift;
    my $value = shift;

    $self->{update_window}->{value} = $value if defined $value;
    return $self->{update_window}->{value}
}
sub update_times {

    my $self = shift;
    my $value = shift;

    $self->{update_times}->{value} = $value if defined $value;
    return $self->{update_times}->{value}
}
sub hourslop {

    my $self = shift;
    my $value = shift;

    $self->{hourslop}->{value} = $value if defined $value;
    return $self->{hourslop}->{value}
}
sub blitz_time {

    my $self = shift;
    my $value = shift;

    $self->{blitz_time}->{value} = $value if defined $value;
    return $self->{blitz_time}->{value}
}
sub update_demandpolicy {

    my $self = shift;
    my $value = shift;

    $self->{update_demandpolicy}->{value} = $value if defined $value;
    return $self->{update_demandpolicy}->{value}
}
sub update_wantmin {

    my $self = shift;
    my $value = shift;

    $self->{update_wantmin}->{value} = $value if defined $value;
    return $self->{update_wantmin}->{value}
}
sub update_missed {

    my $self = shift;
    my $value = shift;

    $self->{update_missed}->{value} = $value if defined $value;
    return $self->{update_missed}->{value}
}
sub update_demandtimes {

    my $self = shift;
    my $value = shift;

    $self->{update_demandtimes}->{value} = $value if defined $value;
    return $self->{update_demandtimes}->{value}
}
sub game_days {

    my $self = shift;
    my $value = shift;

    $self->{game_days}->{value} = $value if defined $value;
    return $self->{game_days}->{value}
}
sub game_hours {

    my $self = shift;
    my $value = shift;

    $self->{game_hours}->{value} = $value if defined $value;
    return $self->{game_hours}->{value}
}
sub btu_build_rate {

    my $self = shift;
    my $value = shift;

    $self->{btu_build_rate}->{value} = $value if defined $value;
    return $self->{btu_build_rate}->{value}
}
sub m_m_p_d {

    my $self = shift;
    my $value = shift;

    $self->{m_m_p_d}->{value} = $value if defined $value;
    return $self->{m_m_p_d}->{value}
}
sub max_btus {

    my $self = shift;
    my $value = shift;

    $self->{max_btus}->{value} = $value if defined $value;
    return $self->{max_btus}->{value}
}
sub max_idle {

    my $self = shift;
    my $value = shift;

    $self->{max_idle}->{value} = $value if defined $value;
    return $self->{max_idle}->{value}
}
sub players_at_00 {

    my $self = shift;
    my $value = shift;

    $self->{players_at_00}->{value} = $value if defined $value;
    return $self->{players_at_00}->{value}
}
sub at_least_one_100 {

    my $self = shift;
    my $value = shift;

    $self->{at_least_one_100}->{value} = $value if defined $value;
    return $self->{at_least_one_100}->{value}
}
sub powe_cost {

    my $self = shift;
    my $value = shift;

    $self->{powe_cost}->{value} = $value if defined $value;
    return $self->{powe_cost}->{value}
}
sub war_cost {

    my $self = shift;
    my $value = shift;

    $self->{war_cost}->{value} = $value if defined $value;
    return $self->{war_cost}->{value}
}
sub easy_tech {

    my $self = shift;
    my $value = shift;

    $self->{easy_tech}->{value} = $value if defined $value;
    return $self->{easy_tech}->{value}
}
sub hard_tech {

    my $self = shift;
    my $value = shift;

    $self->{hard_tech}->{value} = $value if defined $value;
    return $self->{hard_tech}->{value}
}
sub start_tech {

    my $self = shift;
    my $value = shift;

    $self->{start_tech}->{value} = $value if defined $value;
    return $self->{start_tech}->{value}
}
sub start_happy {

    my $self = shift;
    my $value = shift;

    $self->{start_happy}->{value} = $value if defined $value;
    return $self->{start_happy}->{value}
}
sub start_research {

    my $self = shift;
    my $value = shift;

    $self->{start_research}->{value} = $value if defined $value;
    return $self->{start_research}->{value}
}
sub start_edu {

    my $self = shift;
    my $value = shift;

    $self->{start_edu}->{value} = $value if defined $value;
    return $self->{start_edu}->{value}
}
sub level_age_rate {

    my $self = shift;
    my $value = shift;

    $self->{level_age_rate}->{value} = $value if defined $value;
    return $self->{level_age_rate}->{value}
}
sub tech_log_base {

    my $self = shift;
    my $value = shift;

    $self->{tech_log_base}->{value} = $value if defined $value;
    return $self->{tech_log_base}->{value}
}
sub ally_factor {

    my $self = shift;
    my $value = shift;

    $self->{ally_factor}->{value} = $value if defined $value;
    return $self->{ally_factor}->{value}
}
sub edu_avg {

    my $self = shift;
    my $value = shift;

    $self->{edu_avg}->{value} = $value if defined $value;
    return $self->{edu_avg}->{value}
}
sub hap_avg {

    my $self = shift;
    my $value = shift;

    $self->{hap_avg}->{value} = $value if defined $value;
    return $self->{hap_avg}->{value}
}
sub edu_cons {

    my $self = shift;
    my $value = shift;

    $self->{edu_cons}->{value} = $value if defined $value;
    return $self->{edu_cons}->{value}
}
sub hap_cons {

    my $self = shift;
    my $value = shift;

    $self->{hap_cons}->{value} = $value if defined $value;
    return $self->{hap_cons}->{value}
}
sub startmob {

    my $self = shift;
    my $value = shift;

    $self->{startmob}->{value} = $value if defined $value;
    return $self->{startmob}->{value}
}
sub sect_mob_scale {

    my $self = shift;
    my $value = shift;

    $self->{sect_mob_scale}->{value} = $value if defined $value;
    return $self->{sect_mob_scale}->{value}
}
sub sect_mob_max {

    my $self = shift;
    my $value = shift;

    $self->{sect_mob_max}->{value} = $value if defined $value;
    return $self->{sect_mob_max}->{value}
}
sub buil_bh {

    my $self = shift;
    my $value = shift;

    $self->{buil_bh}->{value} = $value if defined $value;
    return $self->{buil_bh}->{value}
}
sub buil_bc {

    my $self = shift;
    my $value = shift;

    $self->{buil_bc}->{value} = $value if defined $value;
    return $self->{buil_bc}->{value}
}
sub buil_bt {

    my $self = shift;
    my $value = shift;

    $self->{buil_bt}->{value} = $value if defined $value;
    return $self->{buil_bt}->{value}
}
sub buil_tower_bh {

    my $self = shift;
    my $value = shift;

    $self->{buil_tower_bh}->{value} = $value if defined $value;
    return $self->{buil_tower_bh}->{value}
}
sub buil_tower_bc {

    my $self = shift;
    my $value = shift;

    $self->{buil_tower_bc}->{value} = $value if defined $value;
    return $self->{buil_tower_bc}->{value}
}
sub buil_tower_bt {

    my $self = shift;
    my $value = shift;

    $self->{buil_tower_bt}->{value} = $value if defined $value;
    return $self->{buil_tower_bt}->{value}
}
sub land_mob_scale {

    my $self = shift;
    my $value = shift;

    $self->{land_mob_scale}->{value} = $value if defined $value;
    return $self->{land_mob_scale}->{value}
}
sub land_grow_scale {

    my $self = shift;
    my $value = shift;

    $self->{land_grow_scale}->{value} = $value if defined $value;
    return $self->{land_grow_scale}->{value}
}
sub land_mob_max {

    my $self = shift;
    my $value = shift;

    $self->{land_mob_max}->{value} = $value if defined $value;
    return $self->{land_mob_max}->{value}
}
sub money_land {

    my $self = shift;
    my $value = shift;

    $self->{money_land}->{value} = $value if defined $value;
    return $self->{money_land}->{value}
}
sub morale_base {

    my $self = shift;
    my $value = shift;

    $self->{morale_base}->{value} = $value if defined $value;
    return $self->{morale_base}->{value}
}
sub plane_mob_scale {

    my $self = shift;
    my $value = shift;

    $self->{plane_mob_scale}->{value} = $value if defined $value;
    return $self->{plane_mob_scale}->{value}
}
sub plane_grow_scale {

    my $self = shift;
    my $value = shift;

    $self->{plane_grow_scale}->{value} = $value if defined $value;
    return $self->{plane_grow_scale}->{value}
}
sub plane_mob_max {

    my $self = shift;
    my $value = shift;

    $self->{plane_mob_max}->{value} = $value if defined $value;
    return $self->{plane_mob_max}->{value}
}
sub money_plane {

    my $self = shift;
    my $value = shift;

    $self->{money_plane}->{value} = $value if defined $value;
    return $self->{money_plane}->{value}
}
sub ship_mob_scale {

    my $self = shift;
    my $value = shift;

    $self->{ship_mob_scale}->{value} = $value if defined $value;
    return $self->{ship_mob_scale}->{value}
}
sub ship_grow_scale {

    my $self = shift;
    my $value = shift;

    $self->{ship_grow_scale}->{value} = $value if defined $value;
    return $self->{ship_grow_scale}->{value}
}
sub ship_mob_max {

    my $self = shift;
    my $value = shift;

    $self->{ship_mob_max}->{value} = $value if defined $value;
    return $self->{ship_mob_max}->{value}
}
sub money_ship {

    my $self = shift;
    my $value = shift;

    $self->{money_ship}->{value} = $value if defined $value;
    return $self->{money_ship}->{value}
}
sub torpedo_damage {

    my $self = shift;
    my $value = shift;

    $self->{torpedo_damage}->{value} = $value if defined $value;
    return $self->{torpedo_damage}->{value}
}
sub fort_max_interdiction_range {

    my $self = shift;
    my $value = shift;

    $self->{fort_max_interdiction_range}->{value} = $value if defined $value;
    return $self->{fort_max_interdiction_range}->{value}
}
sub land_max_interdiction_range {

    my $self = shift;
    my $value = shift;

    $self->{land_max_interdiction_range}->{value} = $value if defined $value;
    return $self->{land_max_interdiction_range}->{value}
}
sub ship_max_interdiction_range {

    my $self = shift;
    my $value = shift;

    $self->{ship_max_interdiction_range}->{value} = $value if defined $value;
    return $self->{ship_max_interdiction_range}->{value}
}
sub flakscale {

    my $self = shift;
    my $value = shift;

    $self->{flakscale}->{value} = $value if defined $value;
    return $self->{flakscale}->{value}
}
sub combat_mob {

    my $self = shift;
    my $value = shift;

    $self->{combat_mob}->{value} = $value if defined $value;
    return $self->{combat_mob}->{value}
}
sub people_damage {

    my $self = shift;
    my $value = shift;

    $self->{people_damage}->{value} = $value if defined $value;
    return $self->{people_damage}->{value}
}
sub unit_damage {

    my $self = shift;
    my $value = shift;

    $self->{unit_damage}->{value} = $value if defined $value;
    return $self->{unit_damage}->{value}
}
sub collateral_dam {

    my $self = shift;
    my $value = shift;

    $self->{collateral_dam}->{value} = $value if defined $value;
    return $self->{collateral_dam}->{value}
}
sub assault_penalty {

    my $self = shift;
    my $value = shift;

    $self->{assault_penalty}->{value} = $value if defined $value;
    return $self->{assault_penalty}->{value}
}
sub fire_range_factor {

    my $self = shift;
    my $value = shift;

    $self->{fire_range_factor}->{value} = $value if defined $value;
    return $self->{fire_range_factor}->{value}
}
sub sect_mob_neg_factor {

    my $self = shift;
    my $value = shift;

    $self->{sect_mob_neg_factor}->{value} = $value if defined $value;
    return $self->{sect_mob_neg_factor}->{value}
}
sub mission_mob_cost {

    my $self = shift;
    my $value = shift;

    $self->{mission_mob_cost}->{value} = $value if defined $value;
    return $self->{mission_mob_cost}->{value}
}
sub uwbrate {

    my $self = shift;
    my $value = shift;

    $self->{uwbrate}->{value} = $value if defined $value;
    return $self->{uwbrate}->{value}
}
sub money_civ {

    my $self = shift;
    my $value = shift;

    $self->{money_civ}->{value} = $value if defined $value;
    return $self->{money_civ}->{value}
}
sub money_mil {

    my $self = shift;
    my $value = shift;

    $self->{money_mil}->{value} = $value if defined $value;
    return $self->{money_mil}->{value}
}
sub money_res {

    my $self = shift;
    my $value = shift;

    $self->{money_res}->{value} = $value if defined $value;
    return $self->{money_res}->{value}
}
sub money_uw {

    my $self = shift;
    my $value = shift;

    $self->{money_uw}->{value} = $value if defined $value;
    return $self->{money_uw}->{value}
}
sub babyeat {

    my $self = shift;
    my $value = shift;

    $self->{babyeat}->{value} = $value if defined $value;
    return $self->{babyeat}->{value}
}
sub bankint {

    my $self = shift;
    my $value = shift;

    $self->{bankint}->{value} = $value if defined $value;
    return $self->{bankint}->{value}
}
sub eatrate {

    my $self = shift;
    my $value = shift;

    $self->{eatrate}->{value} = $value if defined $value;
    return $self->{eatrate}->{value}
}
sub fcrate {

    my $self = shift;
    my $value = shift;

    $self->{fcrate}->{value} = $value if defined $value;
    return $self->{fcrate}->{value}
}
sub fgrate {

    my $self = shift;
    my $value = shift;

    $self->{fgrate}->{value} = $value if defined $value;
    return $self->{fgrate}->{value}
}
sub obrate {

    my $self = shift;
    my $value = shift;

    $self->{obrate}->{value} = $value if defined $value;
    return $self->{obrate}->{value}
}
sub decay_per_etu {

    my $self = shift;
    my $value = shift;

    $self->{decay_per_etu}->{value} = $value if defined $value;
    return $self->{decay_per_etu}->{value}
}
sub fallout_spread {

    my $self = shift;
    my $value = shift;

    $self->{fallout_spread}->{value} = $value if defined $value;
    return $self->{fallout_spread}->{value}
}
sub drnuke_const {

    my $self = shift;
    my $value = shift;

    $self->{drnuke_const}->{value} = $value if defined $value;
    return $self->{drnuke_const}->{value}
}
sub MARK_DELAY {

    my $self = shift;
    my $value = shift;

    $self->{MARK_DELAY}->{value} = $value if defined $value;
    return $self->{MARK_DELAY}->{value}
}
sub TRADE_DELAY {

    my $self = shift;
    my $value = shift;

    $self->{TRADE_DELAY}->{value} = $value if defined $value;
    return $self->{TRADE_DELAY}->{value}
}
sub maxmult {

    my $self = shift;
    my $value = shift;

    $self->{maxmult}->{value} = $value if defined $value;
    return $self->{maxmult}->{value}
}
sub minmult {

    my $self = shift;
    my $value = shift;

    $self->{minmult}->{value} = $value if defined $value;
    return $self->{minmult}->{value}
}
sub buytax {

    my $self = shift;
    my $value = shift;

    $self->{buytax}->{value} = $value if defined $value;
    return $self->{buytax}->{value}
}
sub tradetax {

    my $self = shift;
    my $value = shift;

    $self->{tradetax}->{value} = $value if defined $value;
    return $self->{tradetax}->{value}
}
sub trade_1_dist {

    my $self = shift;
    my $value = shift;

    $self->{trade_1_dist}->{value} = $value if defined $value;
    return $self->{trade_1_dist}->{value}
}
sub trade_2_dist {

    my $self = shift;
    my $value = shift;

    $self->{trade_2_dist}->{value} = $value if defined $value;
    return $self->{trade_2_dist}->{value}
}
sub trade_3_dist {

    my $self = shift;
    my $value = shift;

    $self->{trade_3_dist}->{value} = $value if defined $value;
    return $self->{trade_3_dist}->{value}
}
sub trade_1 {

    my $self = shift;
    my $value = shift;

    $self->{trade_1}->{value} = $value if defined $value;
    return $self->{trade_1}->{value}
}
sub trade_2 {

    my $self = shift;
    my $value = shift;

    $self->{trade_2}->{value} = $value if defined $value;
    return $self->{trade_2}->{value}
}
sub trade_3 {

    my $self = shift;
    my $value = shift;

    $self->{trade_3}->{value} = $value if defined $value;
    return $self->{trade_3}->{value}
}
sub trade_ally_bonus {

    my $self = shift;
    my $value = shift;

    $self->{trade_ally_bonus}->{value} = $value if defined $value;
    return $self->{trade_ally_bonus}->{value}
}
sub trade_ally_cut {

    my $self = shift;
    my $value = shift;

    $self->{trade_ally_cut}->{value} = $value if defined $value;
    return $self->{trade_ally_cut}->{value}
}
sub fuel_mult {

    my $self = shift;
    my $value = shift;

    $self->{fuel_mult}->{value} = $value if defined $value;
    return $self->{fuel_mult}->{value}
}
sub lost_items_timeout {

    my $self = shift;
    my $value = shift;

    $self->{lost_items_timeout}->{value} = $value if defined $value;
    return $self->{lost_items_timeout}->{value}
}
sub last_demand_update {

    my $self = shift;
    my $value = shift;

    $self->{last_demand_update}->{value} = $value if defined $value;
    return $self->{last_demand_update}->{value}
}
sub option {

    my $self = shift;
    my $option = shift;
    my $value = shift;

    $self->{options}->{$option} = $value if defined $value;
    return $self->{options}->{$option};
}
1;
