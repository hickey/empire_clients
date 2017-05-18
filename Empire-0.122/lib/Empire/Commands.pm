package Empire::Commands;

require 5.006;

use strict;
no strict 'refs';
use warnings;
use Carp;
use Exporter;
use Time::ParseDate;

our @ISA = qw(Exporter);
our %REL = ('At War'=>-6,
	    'Hostile'=>-3,
	    'Neutral'=>0,
	    'Friendly'=>3,
	    'Allied'=>6,
	    'Mobilizing'=>-4,
	    'Sitzkrieg'=>-5);

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless $self,$class;
    return $self;
}
sub version {

    my $emp = shift;
    my $cmd = 'version';
    my $version;

    $emp->empcmd($cmd);
    $version = $emp->empreadline($cmd);
    $emp->{VERSION} = $version;
    return $version;
}
sub update {

    my $emp = shift;
    my $cmd = 'update';
    my $update;

    $emp->empcmd($cmd);
    $update = $emp->empreadline($cmd);
    $emp->{UPDATE} = $update;
    return $update;
}
sub show {

    my $emp = shift;
    my $cmd = 'show';
    my @arg = @_;
    my $show;
    my $showwhat = join '_',map(uc,$cmd,@arg);

    $cmd = join ' ',$cmd,@arg;
    $emp->empcmd($cmd);
    $show = $emp->empreadline($cmd);
    $emp->{$showwhat} = $show;
    return $show;
}
sub nation {

    my $emp = shift;
    my $cmd = 'nation';
    my $nation;

    $emp->empcmd($cmd);
    $nation = $emp->empreadline($cmd);
    $emp->{NATION} = $nation;
    return $nation;
}
sub map {

    my $emp = shift;
    my $area = shift;

    unless (defined $area) {
	$area = '*';
    }
    my $cmd = "map $area";
    my $map;

    $emp->empcmd($cmd);
    $map = $emp->empreadline($cmd);
    $emp->{RAWMAP} = $map;
    return $map;
}
sub bmap {

    my $emp = shift;
    my $area = shift;

    unless (defined $area) {
	$area = '*';
    }
    my $cmd = "bmap $area";
    my $bmap;

    $emp->empcmd($cmd);
    $bmap = $emp->empreadline($cmd);
    $emp->{RAWBMAP} = $bmap;
    return $bmap;
}
sub dump {

    my $emp = shift;
    my $area = shift;

    unless (defined $area) {
        $area = '*';
    }
    my $cmd = "dump $area";
    my $dump;

    $emp->empcmd($cmd);
    $dump = $emp->empreadline($cmd);
    return $dump;
}
sub break {

    my $emp = shift;
    my $cmd = 'break';

    $emp->empcmd($cmd);
    my $break = $emp->empreadline($cmd);
    return $break;
}
sub census {

    my $emp = shift;
    my $area = shift;
    unless (defined $area) {
	$area = '*';
    }
    my $cmd = "census $area";
    my $cen;

    $emp->empcmd($cmd);
    $cen = $emp->empreadline($cmd);
    return $cen;
}
sub relations {

    my $emp = shift;
    my $ascoun = shift;
    unless (defined $ascoun) {
	$ascoun = $emp->nnum();
    }
    my $cmd = "relations $ascoun";
    my $rel;

    $emp->empcmd($cmd);
    $rel = $emp->empreadline($cmd);
    $emp->{RELATIONS} = $rel;
    $emp->{RELATIONSAS} = $ascoun;
    return $rel;
}
sub power {

    my $emp = shift;
    my @arg = @_;

    if ($#arg == -1) {
	@arg = ('');
    }
    my $cmd = join ' ','power',@arg;
    my $power;

    $emp->empcmd($cmd);
    $power = $emp->empreadline($cmd);
    $emp->{POWER} = $power;
    if ($arg[0] eq 'c') {
	($emp->{POWERAS}) = ($arg[1] =~ /^(\d+)/);
    }
    else {
	$emp->{POWERAS} = 0;
    }
    return $power;
}
sub sdump {
    
    my $emp = shift;
    my $fleet = shift;

    unless (defined $fleet) {
        $fleet = '*';
    }
    my $cmd = "sdump $fleet";
    my $sdump;

    $emp->empcmd($cmd);
    $sdump = $emp->empreadline($cmd);
    return $sdump;
}
sub pdump {
    
    my $emp = shift;
    my $wing = shift;

    unless (defined $wing) {
        $wing = '*';
    }
    my $cmd = "pdump $wing";
    my $pdump;

    $emp->empcmd($cmd);
    $pdump = $emp->empreadline($cmd);
    return $pdump;
}
sub ldump {
    
    my $emp = shift;
    my $army = shift;

    unless (defined $army) {
        $army = '*';
    }
    my $cmd = "ldump $army";
    my $ldump;

    $emp->empcmd($cmd);
    $ldump = $emp->empreadline($cmd);
    return $ldump;
}
sub report {

    my $emp = shift;
    my $nation = shift;

    unless (defined $nation) {
	$nation = '*';
    }
    my $cmd = "report $nation";
    my $report;

    $emp->empcmd($cmd);
    $report = $emp->empreadline($cmd);
    return $report;
}
sub edit {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','edit',@arg;
    $emp->empcmd($cmd);
    my $edit = $emp->empreadline($cmd);
    return $edit;
}
sub give {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','give',@arg;
    $emp->empcmd($cmd);
    my $give = $emp->empreadline($cmd);
    return $give;
}
sub add {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','add',@arg;
    $emp->empcmd($cmd);
    my $add = $emp->empreadline($cmd);
    return $add;
}
sub designate {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','designate',@arg;
    $emp->empcmd($cmd);
    my $designate = $emp->empreadline($cmd);
    return $designate;
}
sub bdes {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','bdes',@arg;
    $emp->empcmd($cmd);
    my $bdes = $emp->empreadline($cmd);
    return $bdes;
}
sub deliver {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','deliver',@arg;
    $emp->empcmd($cmd);
    my $deliver = $emp->empreadline($cmd);
    return $deliver;
}
sub threshold {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','threshold',@arg;
    $emp->empcmd($cmd);
    my $threshold = $emp->empreadline($cmd);
    return $threshold;
}
sub distribute {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','distribute',@arg;
    $emp->empcmd($cmd);
    my $distribute = $emp->empreadline($cmd);
    return $distribute;
}
sub stop {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','stop',@arg;
    $emp->empcmd($cmd);
    my $stop = $emp->empreadline($cmd);
    return $stop;
}
sub start {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','start',@arg;
    $emp->empcmd($cmd);
    my $start = $emp->empreadline($cmd);
    return $start;
}
sub build {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','build',@arg;
    $emp->empcmd($cmd);
    my $build = $emp->empreadline($cmd);
    return $build;
}
sub declare {

    my $emp = shift;
    my @arg = @_;

    my $cmd = join ' ','declare',@arg;
    $emp->empcmd($cmd);
    my $declare = $emp->empreadline($cmd);
    return $declare;
}
sub cou {

    my $emp = shift;
    my @arg = @_;
    my $cmd = join ' ','coun',@arg;
    $emp->empcmd($cmd);
    my $coun = $emp->empreadline($cmd);
    return $coun;

}
sub realm {

    my $emp = shift;
    my @arg = @_;
    my $cmd;
    if ($#arg != -1) {
	$cmd = join ' ','realm',@arg;
    }
    else {
	$cmd = 'realm';
    }
    $emp->empcmd($cmd);
    my $realm = $emp->empreadline($cmd);
    $emp->{REALM} = $realm;
    return $realm;
}
sub coast {

    my $emp = shift;
    my $sect = shift;

    my $cmd = "coast $sect";
    $emp->empcmd($cmd);
    my $coast = $emp->empreadline($cmd);
    $emp->{COAST}->{$sect} = $coast;
    return $coast;
}
sub lookout {

    my $emp = shift;
    my $fleet = shift;

    $fleet = '*' unless defined $fleet;
    my $cmd = "lookout $fleet";
    $emp->empcmd($cmd);
    my $lookout = $emp->empreadline($cmd);
    $emp->{LOOKOUT}->{$fleet} = $lookout;
    return $lookout;
}
sub spy {

    my $emp = shift;
    my $sect = shift;

    return '' unless defined $sect;
    my $cmd = "spy $sect";
    $emp->empcmd($cmd);
    my $spy = $emp->empreadline($cmd);
    $emp->{SPY}->{$sect} = $spy;
    return $spy;
}
sub set_spy {

    my $emp = shift;
    my $spy = shift;
    my (@spyline) = split(/\n/,$spy);
    my (@dumpfield) = qw(timestamp x y des own oldown eff road rail defense civ mil shell gun pet food bars bdes);
    my $status = 0;
    for (@spyline) {
	if ($status == 0) {
	    if (/sect/) {
		$status = 1;
	    }
	}
	elsif ($status == 1) {
	    s/^\s+//;
	    s/\s+$//;
	    my (@dumpvalue) = split(/\s+/);
	    unshift(@dumpvalue,time);
	    if ($dumpvalue[3] =~ /(\S)(\S)/) {
		$dumpvalue[3] = $1;
		push(@dumpvalue,$2);
	    }
	}
    }
}
sub set_lookout {

    my $emp = shift;
    my $lookout = shift;
    my (@lktline) = split(/\n/,$lookout);
    my (@sdumpfield) = qw(own timestamp id type x y);
    my (@dumpfield) = qw(own timestamp x y des eff civ mil);

    for (@lktline) {
	if (/\d+\% efficient/) {
	    my @dumpvalue;
	    if (/Your (\S.*)/) {
		push(@dumpvalue,$emp->nnum());
		$_ = $1;
	    }
	    elsif (/\(\#\s*(\d+)\)\s+(\S.*)/) {
		push(@dumpvalue,$1);
		$_ = $2;
	    }
	    /^(.*)\s+(\d+)\% efficient\s+(.*)\s+\@\s*(\S+)\,(\S+)/;
	    $_ = $3;
	    my $x = $4;
	    my $y = $5;
	    my $des = $1;
	    my $eff = $2;
	    push(@dumpvalue,time,$x,$y,$emp->{backdes}->{$des},$eff);
	    if (/(\d+) civ/) {
		push(@dumpvalue,$1);
	    }
	    else {
		push(@dumpvalue,0);
	    }
	    if (/(\d+) mil/) {
		push(@dumpvalue,$1);
	    }
	    else {
		push(@dumpvalue,0);
	    }
	    unless (defined $emp->{SECTOR}->{$x}{$y}) {
		$emp->{SECTOR}->{$x}{$y} = Empire::Sector->new([@dumpfield],[@dumpvalue]);
	    }
	    else {
		$emp->{SECTOR}->{$x}{$y}->refresh([@dumpfield],[@dumpvalue]);
	    }
	}
    }
}
sub set_coast {

    my $emp = shift;
    my $coast = shift;
    my (@cstline) = split(/\n/,$coast);
    my $state = 1;
    my (@sdumpfield) = qw(own timestamp id type x y);
    for (@cstline) {
	if ($state == 1) {
	    if (/^\s*Country\s+Ship\s+Location/) {
		$state = 2;
	    }
	}
	elsif ($state == 2) {
	    if (/\(\#\s*(\d+)\)\s+(\S+).*\(\#\s*(\d+)\)\s*\@\s*(\S+)\,(\S+)/) {
		my (@sdumpvalue) = ($1,time,$2,$3,$4,$5);
		unless (defined $emp->{SHIP}->{$2}) {
		    $emp->{SHIP}->{$2} = Empire::Ship->new([@sdumpfield],[@sdumpvalue]);
		}
		else {
		    $emp->{SHIP}->{$2}->refresh([@sdumpfield],[@sdumpvalue]);
		}
	    }
	}
    }
}
sub set_realm {

    my $emp = shift;
    my $realm = shift;
    my (@rlmline) = split(/\n/,$realm);

    for (@rlmline) {
	if (/^Realm\s+\#(d+)\s+is\s+(\S+):(\S+)\,(\S+):(\S+)/) {
	    $emp->{realm}->[$1]->{left} = $2;
	    $emp->{realm}->[$1]->{top} = $3;
	    $emp->{realm}->[$1]->{right} = $4;
	    $emp->{realm}->[$1]->{bottom} = $5;
	}
    }
}
sub set_show_bridge_build {

    my $self = shift;
    my $sbrb = $self->{SHOW_BRIDGE_BUILD};
    my (@sbrbline) = split(/\n/,$sbrb);

    for (@sbrbline) {
	if (/Bridges require (\d+) tech, (\d+) hcm\, (\d+) workers,/) {
	    $self->{version}->{buil_bt}->{value} = $1;
	    $self->{version}->{buil_bh}->{value} = $2;
	}
	elsif (/(\d+) available workforce\, and cost \$(\d+)/) {
	    $self->{version}->{buil_bc}->{value} = $3;
	}
    }
}
sub set_show_bridge_stats {

    my $self = shift;
    $self->set_show_bridge_build();
}
sub set_show_bridge_capabilities {

    my $self = shift;
    $self->set_show_bridge_build();
}
sub set_show_tower_build {

    my $self = shift;
    my $stwb = $self->{SHOW_TOWER_BUILD};
    my (@stwbline) = split(/\n/,$stwb);

    for (@stwbline) {
	if (/Towers require (\d+) tech, (\d+) hcm\, (\d+) workers,/) {
	    $self->{version}->{buil_tower_bt}->{value} = $1;
	    $self->{version}->{buil_tower_bh}->{value} = $2;
	}
	elsif (/(\d+) available workforce\, and cost \$(\d+)/) {
	    $self->{version}->{buil_tower_bc}->{value} = $3;
	}
    }
}
sub set_show_tower_stats {

    my $self = shift;
    $self->set_show_tower_build();
}
sub set_show_tower_capabilities {

    my $self = shift;
    $self->set_show_tower_build();
}
sub set_show_sector_build {

    my $self = shift;
    my $sseb = $self->{SHOW_SECTOR_BUILD};
    my @ssebline = split(/\n/,$sseb);

    for (@ssebline) {
	if (/^(\S)\s/) {
	    my @sectdata = split(/\s+/);
	    $self->{sector_type}->{$sectdata[0]}->{cost_to_des} = $sectdata[1];
	    $self->{sector_type}->{$sectdata[0]}->{cost_for_1} = $sectdata[2];
	    $self->{sector_type}->{$sectdata[0]}->{lcm_for_1} = $sectdata[3];
	    $self->{sector_type}->{$sectdata[0]}->{hcm_for_1} = $sectdata[4];
	}
	elsif (/^(road|rail|defense)/) {
	    my $itype = $1;
	    my(@sectdata) = /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/;
	    $self->{infrastructure_type}->{$itype}->{lcm_for_1} = $sectdata[0];
	    $self->{infrastructure_type}->{$itype}->{hcm_for_1} = $sectdata[1];
	    $self->{infrastructure_type}->{$itype}->{mob_for_1} = $sectdata[2];
	    $self->{infrastructure_type}->{$itype}->{cost_for_1} = $sectdata[3];
	}
    }
}
sub set_show_sector_stats {

    my $self = shift;
    my $sses = $self->{SHOW_SECTOR_STATS};
    my @ssesline = split(/\n/,$sses);

    for (@ssesline) {
	if (/^\S\s/) {
	    my($secttype,$sectname,$sectdata) = /(\S)\s(.*\D)\s(\d.*)/;
	    my (@sectdata) = split(/\s+/,$sectdata);
	    $self->{sector_type}->{$secttype}->{name} = $sectname;
	    $self->{backdes}->{$sectname} = $secttype;
	    $self->{sector_type}->{$secttype}->{base_mcost} = $sectdata[0];
	    $self->{sector_type}->{$secttype}->{max_off} = $sectdata[1];
	    $self->{sector_type}->{$secttype}->{max_def} = $sectdata[2];
	    $self->{sector_type}->{$secttype}->{pack_mil} = $sectdata[3];
	    $self->{sector_type}->{$secttype}->{pack_uw} = $sectdata[4];
	    $self->{sector_type}->{$secttype}->{pack_civ} = $sectdata[5];
	    $self->{sector_type}->{$secttype}->{pack_bar} = $sectdata[6];
	    $self->{sector_type}->{$secttype}->{pack_other} = $sectdata[7];
	    $self->{sector_type}->{$secttype}->{max_pop} = $sectdata[8];
	}
    }
}
sub set_show_sector_capabilities {

    my $self = shift;
    my $ssec = $self->{SHOW_SECTOR_CAPABILITIES};
    my @ssecline = split(/\n/,$ssec);

    for (@ssecline) {
	if (/^(\S)\s/) {
	    my $secttype = $1;
	    my $sectdata = substr($_,26);
	    my $sectsubd = substr($_,49);
	    my $rest;
	    $self->{sector_type}->{$secttype}->{type} = $secttype;
	    ($self->{sector_type}->{$secttype}->{product}) = ($sectdata =~ /^(\S+)/);
	    ($self->{sector_type}->{$secttype}->{level}) = ($sectsubd =~ /^(\S+)/);
	    unless ($self->{sector_type}->{$secttype}->{level}) {
		$self->{sector_type}->{$secttype}->{level} = 'none';
		substr($_,49,4,'none');
	    }
	    my ($sectuses) = (/$self->{sector_type}->{$secttype}->{product}(.*)$self->{sector_type}->{$secttype}->{level}/);
	    my ($sectrest) = (/$self->{sector_type}->{$secttype}->{level}(.*)$/);
	    $sectuses =~ s/^\s+//;
	    $sectuses =~ s/\s+$//;
	    $sectrest =~ s/^\s+//;
	    $sectrest =~ s/\s+$//;
	    my @sectuse = split(/\s+/,$sectuses);
	    $self->{sector_type}->{$secttype}->{use} = [];
	    my $u;
	    for ($u=0;$u<=$#sectuse;$u+=2) {
		$self->{sector_type}->{$secttype}->{use}->[$u % 2]->{pamnt} = $sectuse[$u];
		$self->{sector_type}->{$secttype}->{use}->[$u % 2]->{pmnem} = $sectuse[$u+1];
	    }
	    my (@sectrest) = split(/\s+/,$sectrest);
	    $self->{sector_type}->{$secttype}->{min_level} = $sectrest[0];
	    $self->{sector_type}->{$secttype}->{lag_level} = $sectrest[1];
	    $self->{sector_type}->{$secttype}->{eff_prod} = $sectrest[2];
	    $self->{sector_type}->{$secttype}->{cost_prod} = $sectrest[3];
	    $self->{sector_type}->{$secttype}->{reso_depl} = $sectrest[4];
	    $self->{sector_type}->{$secttype}->{pmnem} = $sectrest[5] if $sectrest[5];
	    $self->{product_type}->{$secttype} = Empire::ProductType->new($self->{sector_type}->{$secttype});
	}
    }
}
sub set_power {

    my $emp = shift;
    my $power = shift;
    my $coun = $emp->{POWERAS};
    my (@powline) = split(/\n/,$power);
    my $state = 0;
    my @pfield;

    for my $powerline (@powline) {
	$_ = $powerline;
	s/^\s+//;
	s/\s+$//;
	if ($state == 0) {
	    unless (/\S/) {
		$state = 1;
	    }
	    next;
	}
	elsif ($state == 1) {
	    (@pfield) = split(/\s+/);
	    $state = 2;
	    next;
	}
	elsif ($state == 2) {
	    if (/\-\-\-\- \-\-\-\- \-\-\-\- \-\-\-\-/) {
		$state = 3;
		next;
	    }
	    else {
		my (@pdata) = split(/\s+/);
		shift @pdata;
		for my $p (@pfield) {
		    $emp->{nation}->[$coun]->{$p} = tonumber(shift @pdata);
		}
		$emp->{nation}->[$coun]->{treasury} = $emp->{nation}->[$coun]->{money}
		  unless $coun == $emp->nnum();
	    }
	}
    }
}
sub set_coun {

    my $emp = shift;
    my $coun = shift;

    my (@counline) = split(/\n/,$coun);
    for (@counline) {
	s/^\s+//;
	s/\s+$//;
	if (/^(\d+)\s+(.*)\s+\[(\d+)\]\s+(\S+)\s+(.*)/) {
	    $emp->{nation}->[$1]->{nstatus} = $4;
	}
    }
}
sub set_map {

    my $emp = shift;
    my $map = shift;
    my $mode = shift;

    $mode = 'm' unless defined $mode;

    my $xsize = $emp->xsize();
    my $ysize = $emp->ysize();

    my %map = %{$emp->{MAP}};
    my (@mapline) = split(/\n/,$map);
    my $x;
    my $y;
    my $state = 0;
    my $l1;
    my $l2;
    my $r1;
    my $r2;
    my $lminus = 1;
    my $rminus = 1;

    for (@mapline) {
	if ($state == 0) {
	    if (/     (\S).*(\S)/) {
		$state = 1;
		$l1 = $1;
		if ($l1 eq '-') {
		    $l1 = 0;
		    $lminus = -1;
		}
		$r1 = $2;
		if ($r1 eq '-') {
		    $r1 = 0;
		    $rminus = -1;
		}
		if (/\-\d+$/) {
		    $lminus = -1;
		}
		elsif ($r1 < $l1) {
		    $lminus = -1;
		    $rminus = -1;
		}
	    }
	    next;
	}
	elsif ($state == 1) {
	    if (/     (\S).*(\S)/) {
		$state = 2;
		$l2 = $1;
		$r2 = $2;
		$l2 = (10*$l1 + $l2)*$lminus;
		$r2 = (10*$r1 + $r2)*$rminus;
	    }
	    next;
	}
	elsif ($state == 2) {
	    if (/^     (\S).*(\S)/) {
		$emp->{MAP} = {%map};
		last;
	    }
	    elsif (/(\-?\d+)/) {
		$y = $1;
		for $x ($l2..$r2) {
		    if (($x+$y) % 2 == 0) {
			$map{$x}{$y} = substr($_,5+$x-$l2,1);
			if ($map{$x}{$y} =~ /\S/) {
			    my @mapfield = qw(x y);
			    my @mapvalue = ();
			    push(@mapvalue,$x,$y);
			    if ($mode eq 'b') {
				push(@mapfield,'bdes');
				push(@mapvalue,$map{$x}{$y});
			    }
			    elsif ($mode eq 'n') {
				push(@mapfield,'sdes');
				push(@mapvalue,$map{$x}{$y});
			    }
			    push(@mapfield,'des');
			    push(@mapvalue,$map{$x}{$y});
			    $emp->{SECTOR}->{$x}{$y} = Empire::Sector->new([@mapfield],[@mapvalue])
			      unless defined $emp->{SECTOR}->{$x}{$y};
			    $emp->{SECTOR}->{$x}{$y}->{bdes} = $map{$x}{$y} if $mode eq 'b';
			    $emp->{SECTOR}->{$x}{$y}->{des} = $map{$x}{$y} if $mode eq 'b'
			      && (!defined $emp->{SECTOR}->{$x}{$y}->{des});
			    $emp->{SECTOR}->{$x}{$y}->{sdes} = $map{$x}{$y} if $mode eq 'n';
			    $emp->{SECTOR}->{$x}{$y}->{des} = $map{$x}{$y}  if $mode eq 'm';
			    if ($emp->{SECTOR}->{$x}{$y}->des() eq '.') {
				$emp->{SECTOR}->{$x}{$y}->{own} = 0;
			    }
			    if ($emp->{SECTOR}->{$x}{$y}->des() eq '?') {
				$emp->{SECTOR}->{$x}{$y}->{des} = '+';
			    }
			    unless (defined $emp->{SECTOR}->{$x}{$y}->own()) {
				$emp->{SECTOR}->{$x}{$y}->{own} = 0;
			    }
			}
		    }
		}
	    }
	}
    }
    $emp->{MAP} = {%map};
}
sub set_relations {

    my $emp = shift;
    my $rel = shift;
    my $ascoun = $emp->{RELATIONSAS};
    my (@relline) = split(/\n/,$rel);
    my $coun;
    my $enemy;
    my $ename;
    my $yours;
    my $theirs;
    my $tstamp;

    for (@relline) {
	if (/\s+(.*)\s+Diplomatic Relations Report\s+(.*)/) {
	    $emp->{nation}->[$ascoun] = Empire::Nation->new() unless defined $emp->{nation}->[$ascoun];
	    $coun = $1;
	    $tstamp = parsedate($2);
	    $emp->{RELATIONS}->[$ascoun]->{tstamp} = $tstamp;
	    $emp->{nation}->[$ascoun]->{cnum} = $ascoun;
	    $emp->{nation}->[$ascoun]->{name} = $coun;
	    $emp->{NATIONS}->{$coun} = $ascoun;
	}
	elsif (/(\d+)\)\s+(.*)/) {
	    $enemy = $1;
	    $emp->{nation}->[$enemy] = Empire::Nation->new() unless defined $emp->{nation}->[$enemy];
	    $ename = substr($_,5,22);
	    $ename =~ s/\s+$//;
	    $emp->{nation}->[$enemy]->{cnum} = $enemy;
	    $emp->{nation}->[$enemy]->{name} = $ename;
	    my $rels = substr($_,29,80);
	    $rels =~ s/^\s+//;
	    $rels =~ s/\s+$//;
	    my @rels = split(/\s+/,$rels);
	    if ($rels[0] eq 'At') {
		$emp->{nation}->[$ascoun]->{relations}->[$enemy] = $REL{'At War'};
		if ($rels[2] eq 'At') {
		    $emp->{nation}->[$enemy]->{relations}->[$ascoun] = $REL{'At War'};
		}
		else {
		    $emp->{nation}->[$enemy]->{relations}->[$ascoun] = $REL{$rels[2]};
		}
	    }
	    else {
		$emp->{nation}->[$ascoun]->{relations}->[$enemy] = $REL{$rels[0]};
		if ($rels[1] eq 'At') {
		    $emp->{nation}->[$enemy]->{relations}->[$ascoun] = $REL{'At War'};
		}
		else {
		    $emp->{nation}->[$enemy]->{relations}->[$ascoun] = $REL{$rels[1]};
		}
	    }
	    $emp->{NATIONS}->{$ename} = $enemy;
	}
    }
}
sub set_report {

    my $emp = shift;
    my $report = shift;

    my @repdata = split(/\n/,$report);
    my @field = qw(technology research education happiness);
    for (@repdata) {
	if (/^\s*\d+/) {
	    /^\s*(\d+)\s+(\S.*)$/;
	    my $cnum = $1;
	    unless ($cnum eq $emp->{nnum}) {
		$_ = $2;
		$emp->{nation}->[$cnum] = Empire::Nation->new() unless defined $emp->{nation}->[$cnum];
		$emp->{nation}->[$cnum]->{name} = substr($2,0,14) unless defined $emp->{nation}->[$cnum]->{name};
		$_ = substr($2,14);
		$emp->{nation}->[$cnum]->{name} =~ s/\s+$//;
		for my $f (@field) {
		    s/^\s+//;
		    if (/^n\/a\s+(\S.*)/) {
			$emp->{nation}->[$cnum]->{$f} = 0;
			$_ = $1;
		    }
		    elsif (/^(\d+\.\d+)\s+(\S.*)/) {
			$emp->{nation}->[$cnum]->{$f} = $1;
			$_ = $2;
		    }
		    elsif (/^\>\=\s+(\d+)\s+(\S.*)/) {
			$emp->{nation}->[$cnum]->{$f} = $1+1;
			$emp->{nation}->[$cnum]->{$f.'_flag'} = 1;
			$_ = $2;
		    }
		    elsif (/^(\d+)\s+\-\s+(\d+)\s+(\S.*)/) {
			$emp->{nation}->[$cnum]->{$f} = ($1+$2)/2;
			$emp->{nation}->[$cnum]->{$f.'_flag'} = 2;
			$_ = $3;
		    }
		}
		s/^\s+//;
		my $tmp = $_;
		$emp->{nation}->[$cnum]->{nstatus} = $tmp;
	    }
	}
    }
}
sub strip_map {

    my $emp = shift;
    my $map = shift;
    my $state = 0;
    my $skinned_map = '';
    my @lines = split(/\n/,$map);

    for my $line (@lines) {
        if($state == 2) {
            if($line =~ /^\s\s\s\s\s\S/ and $state == 2) {
		$emp->{CURMAP} = $skinned_map;
                return $skinned_map;
            }
            my $mapline = substr($line,5);
            $mapline =~ s/\s+$//g;
            $mapline =~ s/\S+$//g;
            $mapline =~ s/\s$//g;
            $skinned_map .= $mapline . "\n";
        }
        if($line =~ /^\s\s\s\s\s\S/ and $state == 1) {
            $state = 2;
        }
        if($line =~ /^\s\s\s\s\s\S/ and $state == 0) {
	    $state = 1;
        }
    }
    $emp->{CURMAP} = $skinned_map;
    return $emp->{CURMAP};
}
sub set_nation {

    my $emp = shift;
    my $nation = Empire::Nation->new();
    my $natdata = $emp->{NATION};
    $natdata =~ s/^\s+//gs;
    $natdata =~ s/\s+$//gs;
    my (@nationdata) = split(/\n/s,$natdata);

    $nationdata[0] =~ /^\(\#(\d+)\) (.*) Nation Report/;
    $nation->{cnum} = $1;
    $emp->{nnum} = $1;
    $nation->{name} = $2;
    $nationdata[1] =~ /Nation status is (\S+)\s+Bureaucratic Time Units: (\d+)/;
    $nation->{nstatus} = $1;
    $nation->{btu} = $2;
    if ($nationdata[2] =~ /(\d+)\% eff capital at (\d+\,\d+) has (\d+) civilians \& (\d+) military/) {
	$nation->{capital}{eff} = $1;
	$nation->{capital}{coord} = $2;
	$nation->{capital}{civ} = $3;
	$nation->{capital}{mil} = $4;
    }
    else {
	$nationdata[2] =~ /No capital. \(was at (\d+,\d+)\)/;
	$nation->{capital}{eff} = undef;
	$nation->{capital}{coord} = $1;
	$nation->{capital}{civ} = undef;
	$nation->{capital}{mil} = undef;
    }
    $nationdata[3] =~ /The treasury has \$(\d+)\.00     Military reserves: (\d+)/;
    $nation->{treasury} = $1;
    $nation->{reserves} = $2;
    $nationdata[4] =~ /(\d+\.\d+).*(\d+\.\d+)/;
    $nation->{education} = $1;
    $nation->{happiness} = $2;
    $nationdata[5] =~ /(\d+\.\d+).*(\d+\.\d+)/;
    $nation->{technology} = $1;
    $nation->{research} = $2;
    $nationdata[6] =~ /(\d+\.\d+).*(\d+\.\d+)/;
    $nation->{techfactor} = $1;
    $nation->{plagchance} = $2;
    $nationdata[8] =~ /(\d+)/;
    $nation->{maxpop} = $1;
    $nationdata[9] =~ /(\d+)\/(\d+)/;
    $nation->{maxsafeciv} = $1;
    $nation->{maxsafeuw} = $2;
    $nationdata[10] =~ /(\d+\.\d+)/;
    $nation->{hapneeded} = $1;
    $emp->{nation}->[$nation->cnum()] = $nation;
}
sub set_version {

    my $emp  = shift;
    my $version = $emp->{VERSION};
    $version =~ s/^\s+//gs;
    $version =~ s/\s+$//gs;
    my (@versiondata) = split(/\n/s,$version);
    my $ver_state = 0;

    for my $versionline (@versiondata) {
	if (! $versionline =~ /\S/) {
	    next;
	}
	if ($ver_state == 1) {
	    if ($versionline =~ /Options disabled in this game/) {
		$ver_state = 2;
		next;
	    }
	    else {
		$versionline =~ s/\s//g;
		chop $versionline;
		my (@options) = split(/\,/,$versionline);
		for my $option (@options) {
		    $emp->{options}->{$option} = 1;
		}
	    }
	}
	elsif ($ver_state == 2) {
	    if ($versionline =~ /The person to annoy if something goes wrong is/) {
		$ver_state = 3;
		next;
	    }
	    else {
		$versionline =~ s/\s//g;
		chop $versionline;
		my (@options) = split(/\,/,$versionline);
		for my $option (@options) {
		    $emp->{options}->{$option} = 0;
		}
	    }
	}
	elsif ($ver_state == 3) {
	    $versionline =~ s/^\s+//;
	    $versionline =~ s/\s+$//;
	    $emp->{privname} = $versionline;
	    $ver_state = 4;
	}
	elsif ($ver_state == 4) {
	    $versionline =~ s/^\s+//;
	    $versionline =~ s/\s+$//;
	    $emp->{privlog} = $versionline;
	    $ver_state = 0;
	}
	elsif ($ver_state == 0) {
	    if ($versionline =~ /Options enabled in this game/) {
		$ver_state = 1;
		next;
	    }
	    elsif ($versionline =~ /Empire (\d+\.\d+\.\d+)/) {
		$emp->{version}->{versionnum}->{value} = $1;
	    }
	    elsif ($versionline =~ /KSU distribution (\d+\.\d+), Chainsaw version (\d+\.\d+), Wolfpack version (\d+\.\d+)/) {
		$emp->{version}->{ksu}->{value} = $1;
		$emp->{version}->{chainsaw}->{value} = $2;
		$emp->{version}->{wolfpack}->{value} = $3;
	    }
	    elsif ($versionline =~ /World size is (\d+) by (\d+)/) {
		$emp->{version}->{WORLD_X}->{value} = $1;
		$emp->{version}->{WORLD_Y}->{value} = $2;
	    }
	    elsif ($versionline =~ /There can be up to (\d+) countries/) {
		$emp->{version}->{maxcoun}->{value} = $1;
	    }
	    elsif ($versionline =~ /By default\, countries use their own coordinate system/) {
		$emp->{version}->{players_at_00}->{value} = 0;
	    }
	    elsif ($versionline =~ /An Empire time unit is (\d+) seconds long/) {
		$emp->{version}->{s_p_etu}->{value} = $1;
	    }
	    elsif ($versionline =~ /An update consists of (\d+) empire time units/) {
		$emp->{version}->{etu_per_update}->{value} = $1;
	    }
	    elsif ($versionline =~ /Each country is allowed to be logged in (\d+) minutes a day/) {
		$emp->{version}->{m_m_p_d}->{value} = $1;
	    }
	    elsif ($versionline =~ /It takes (\d+\.\d+) civilians to produce a BTU in one time unit/) {
		$emp->{version}->{btu_build_rate}->{value} = 1/100/$1;
	    }
	    elsif ($versionline =~ /100 fertility sector can grow (\d+\.\d+) food per etu/) {
		$emp->{version}->{fertrate}->{value} = $1;
	    }
	    elsif ($versionline =~ /(\d+) civilians will harvest (\d+\.\d+) food per etu/) {
		$emp->{version}->{harvrate}->{value} = $2/$1;
	    }
	    elsif ($versionline =~ /(\d+) civilians will give birth to (\d+\.\d+) babies per etu/) {
		$emp->{version}->{civbirthrate}->{value} = $2/$1;
	    }
	    elsif ($versionline =~ /(\d+) uncompensated workers will give birth to (\d+\.\d+) babies/) {
		$emp->{version}->{uwbrate}->{value} = $2/$1;
	    }
	    elsif ($versionline =~ /(\d+) people eat (\d+\.\d+) units of food/) {
		$emp->{version}->{eatrate}->{value} = $2/$1;
	    }
	    elsif ($versionline =~ /(\d+) babies eat (\d+\.\d+) units of food becoming adults/) {
		$emp->{version}->{babyeat}->{value} = $2/$1;
	    }
	    elsif ($versionline =~ /Banks pay \$(\d+\.\d+) in interest per (\d+) gold bars per etu/) {
		$emp->{version}->{bankint}->{value} = $1/$2;
	    }
	    elsif ($versionline =~ /(\d+) civilians generate \$(\d+\.\d+), uncompensated workers \$(\d+\.\d+) each time unit/) {
		$emp->{version}->{money_civ}->{value} = $2/$1;
		$emp->{version}->{money_uw}->{value} = $3/$1;
	    }
	    elsif ($versionline =~ /(\d+) active military cost \$(\d+\.\d+), reserves cost \$(\d+\.\d+)/) {
		$emp->{version}->{money_mil}->{value} = $2/$1;
		$emp->{version}->{money_res}->{value} = $3/$1;
	    }
	    elsif ($versionline =~ /Declaring war will cost you \$(\d+)/) {
		$emp->{version}->{war_cost}->{value} = $1;
	    }
	    elsif ($versionline =~ /requires (\d+) happy stroller per (\d+) civ/) {
		$emp->{version}->{hap_cons}->{value} = $2*$emp->{version}->{etu_per_update}->{value};
	    }
	    elsif ($versionline =~ /requires (\d+) class of graduates per (\d+) civ/) {
		$emp->{version}->{edu_cons}->{value} = $2*$emp->{version}->{etu_per_update}->{value};
	    }
	    elsif ($versionline =~ /Happiness is averaged over (\d+) time units/) {
		$emp->{version}->{hap_avg}->{value} = $1;
	    }
	    elsif ($versionline =~ /Education is averaged over (\d+) time units/) {
		$emp->{version}->{edu_avg}->{value} = $1;
	    }
	    elsif ($versionline =~ /boost you get from your allies is (\d+\.\d+)\%/) {
		$emp->{version}->{ally_factor}->{value} = 100/$1;
	    }
	    elsif ($versionline =~ /decline (\d+)% every (\d+) time units/) {
		if ($2 != 0 && $1 != 0) {
		    $emp->{version}->{level_age_rate}->{value} = $2/$1;
		}
		else {
		    $emp->{version}->{level_age_rate}->{value} = 0;
		}
	    }
	    elsif ($versionline =~ /Tech Buildup is not limited/) {
		$emp->{version}->{tech_log_base}->{value} = 0;
		$emp->{version}->{easy_tech}->{value} = 0;
	    }
	    elsif ($versionline =~ /Tech Buildup is limited to logarithmic growth \(base (\d+\.\d+)\) after (\d+\.\d+)/) {
		$emp->{version}->{tech_log_base}->{value} = $1;
		$emp->{version}->{easy_tech}->{value} = $2;
	    }
	    elsif ($versionline =~ /Maximum mobility\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
		$emp->{version}->{sect_mob_max}->{value} = $1;
		$emp->{version}->{ship_mob_max}->{value} = $2;
		$emp->{version}->{plane_mob_max}->{value} = $3;
		$emp->{version}->{land_mob_max}->{value} = $4;
	    }
	    elsif ($versionline =~ /Max mob gain per update\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
		$emp->{version}->{sect_mob_scale}->{value} = $1/$emp->{version}->{etu_per_update}->{value};
		$emp->{version}->{ship_mob_scale}->{value} = $2/$emp->{version}->{etu_per_update}->{value};
		$emp->{version}->{plane_mob_scale}->{value} = $3/$emp->{version}->{etu_per_update}->{value};
		$emp->{version}->{land_mob_scale}->{value} = $4/$emp->{version}->{etu_per_update}->{value};
	    }
	    elsif ($versionline =~ /Max eff gain per update.*\s+(\d+)\s+(\d+)\s+(\d+)/) {
		$emp->{version}->{ship_grow_scale}->{value} = $1/$emp->{version}->{etu_per_update}->{value};
		$emp->{version}->{plane_grow_scale}->{value} = $2/$emp->{version}->{etu_per_update}->{value};
		$emp->{version}->{land_grow_scale}->{value} = $3/$emp->{version}->{etu_per_update}->{value};
	    }
	    elsif ($versionline =~ /Ships on autonavigation may use (\d+)  cargo holds per ship/) {
		$emp->{version}->{autonavcargo}->{value} = $1;
	    }
	    elsif ($versionline =~ /Nukes are disabled/) {
		$emp->{version}->{nukes}->{value} = 0;
	    }
	    elsif ($versionline =~ /Fire ranges are scaled by (\d+\.\d+)/) {
		$emp->{version}->{fire_range_factor}->{value} = $1;
	    }
	}
    }
}
sub set_update {

    my $self = shift;
    my $update = shift;
    $update =~ s/^\s+//gs;
    $update =~ s/\s+$//gs;
    my (@updatedata) = split(/\n/s,$update);

    $self->{enableupdate} = 1;
    $self->{mobupdate} = 0;
    for (@updatedata) {
	if (/Mobility updating is enabled/) {
	    $self->{mobupdate} = 1;
	}
	elsif (/UPDATES ARE DISABLED/) {
	    $self->{enableupdate} = 0;
	}
	elsif (/Updates occur at times specified by the ETU rates/) {
	    $self->{version}->{update_policy}->{value} = 0;
	}
	elsif (/Updates occur at scheduled times/) {
	    $self->{version}->{update_policy}->{value} = 1;
	}
	elsif (/Blitz Updates occur every (\d+) minutes/) {
	    $self->{version}->{update_policy}->{value} = 2;
	    $self->{version}->{blitz_time}->{value} = $1;
	}
	elsif (/There are no regularly scheduled updates/) {
	    $self->{version}->{update_policy}->{value} = 3;
	}
	elsif (/^The next update.*(\S\S\S \d\d \d\d:\d\d:\d\d+)/) {
	    $self->{nextupdate} = parsedate($1);
	}
	elsif (/^The next update window starts at.*(\S\S\S \d\d \d\d:\d\d:\d\d+)/) {
	    $self->{updatewindowstart} = parsedate($1);
	}
	elsif (/^The next update window stops at.*(\S\S\S \d\d \d\d:\d\d:\d\d+)/) {
	    $self->{updatewindowstop} = parsedate($1);
	    $self->{version}->{update_window}->{value} = $self->{updatewindowstop} - $self->{updatewindowstart};
	}
	elsif (/The update schedule is: (\S+)/) {
	    $self->{version}->{update_times}->{value} = $1;
	}
	elsif (/Game days are: (.*)/) {
	    $self->{version}->{game_days}->{value} = $1;
	}
	elsif (/Game hours are: (.*)/) {
	    $self->{version}->{game_hours}->{value} = $1;
	}
	elsif (/Update times are variable\, update window is \+\/\- (\d+) minutes (\d+) seconds/) {
	    $self->{version}->{update_window}->{value} = $1*60+$2;
	}
    }
}
sub set_dump {

    my $emp  = shift;
    my $dump = shift;
    return if ($dump =~ /command failed/);
    $dump =~ s/^\s+//gs;
    $dump =~ s/\s+$//gs;
    my (@dumpvalue) = split(/\n/s,$dump);
    my $x;
    my $y;
    $dumpvalue[1] =~ /(\d+)/;
    my $timestamp = $1;
    my @sect;
    my (@dumpfield) = split(/ /,$dumpvalue[2]);
    unshift @dumpfield,'own' unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
    unshift @dumpfield,'timestamp';
    for my $di (3..$#dumpvalue) {
	if ($dumpvalue[$di] =~ /^\d+ sector/) {
	    last;
	}
	else {
	    my(@dumpvalue) = split(/ /,$dumpvalue[$di]);
	    unshift @dumpvalue,$emp->nnum() unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
	    $x = $dumpvalue[1];
	    $y = $dumpvalue[2];
	    unshift @dumpvalue,$timestamp;
	    $emp->{SECTOR}->{$x}{$y} = Empire::Sector->new([@dumpfield],[@dumpvalue]);
	    push @sect,$emp->{SECTOR}->{$x}{$y};
	}
    }
    return (@sect);
}
sub set_sdump {

    my $emp  = shift;
    my $sdump = shift;
    my @ship;
    return if ($sdump =~ /command failed/);
    $sdump =~ s/^\s+//gs;
    $sdump =~ s/\s+$//gs;
    my (@sdumpvalue) = split(/\n/s,$sdump);
    my $id;
    $sdumpvalue[1] =~ /(\d+)/;
    my $timestamp = $1;

    my (@sdumpfield) = split(/ /,$sdumpvalue[2]);
    unshift @sdumpfield,'own' unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
    unshift @sdumpfield,'timestamp';
    for my $di (3..$#sdumpvalue) {
	if ($sdumpvalue[$di] =~ /^\d+ ship/) {
	    last;
	}
	else {
	    $sdumpvalue[$di] =~ s/^\s+//;
	    my(@sdumpvalue) = split(/\s+/,$sdumpvalue[$di]);
	    unshift @sdumpvalue,$emp->nnum() unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
	    $id = $sdumpvalue[1];
	    unshift @sdumpvalue,$timestamp;
	    $emp->{SHIP}->{$id} = Empire::Ship->new([@sdumpfield],[@sdumpvalue]);
	    push @ship,$emp->{SHIP}->{$id};
	}
    }
    return(@ship);
}
sub set_pdump {

    my $emp  = shift;
    my $pdump = shift;
    my @plane;

    return if ($pdump =~ /command failed/);
    $pdump =~ s/^\s+//gs;
    $pdump =~ s/\s+$//gs;
    my (@pdumpvalue) = split(/\n/s,$pdump);
    my $id;
    $pdumpvalue[1] =~ /(\d+)/;
    my $timestamp = $1;

    my (@pdumpfield) = split(/ /,$pdumpvalue[2]);
    unshift @pdumpfield,'own' unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
    unshift @pdumpfield,'timestamp';
    for my $di (3..$#pdumpvalue) {
	if ($pdumpvalue[$di] =~ /^\d+ plan/) {
	    last;
	}
	else {
	    $pdumpvalue[$di] =~ s/^\s+//;
	    my(@pdumpvalue) = split(/\s+/,$pdumpvalue[$di]);
	    unshift @pdumpvalue,$emp->nnum() unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
	    $id = $pdumpvalue[1];
	    unshift @pdumpvalue,$timestamp;
	    $emp->{PLANE}->{$id} = Empire::Plane->new([@pdumpfield],[@pdumpvalue]);
	    push @plane,$emp->{PLANE}->{$id};
	}
    }
    return(@plane);
}
sub set_ldump {

    my $emp  = shift;
    my $ldump = shift;
    my @unit;

    return if ($ldump =~ /command failed/);
    $ldump =~ s/^\s+//gs;
    $ldump =~ s/\s+$//gs;
    my (@ldumpvalue) = split(/\n/s,$ldump);
    my $id;
    $ldumpvalue[1] =~ /(\d+)/;
    my $timestamp = $1;

    my (@ldumpfield) = split(/ /,$ldumpvalue[2]);
    unshift @ldumpfield,'own' unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
    unshift @ldumpfield,'timestamp';
    for my $di (3..$#ldumpvalue) {
	if ($ldumpvalue[$di] =~ /^\d+ unit/) {
	    last;
	}
	else {
	    $ldumpvalue[$di] =~ s/^\s+//;
	    my(@ldumpvalue) = split(/\s+/,$ldumpvalue[$di]);
	    unshift @ldumpvalue,$emp->nnum() unless ($emp->{nation}->[$emp->nnum()]->nstatus() eq 'DEITY');
	    $id = $ldumpvalue[1];
	    unshift @ldumpvalue,$timestamp;
	    $emp->{UNIT}->{$id} = Empire::Unit->new([@ldumpfield],[@ldumpvalue]);
	    push @unit,$emp->{UNIT}->{$id};
	}
    }
    return(@unit);
}
sub get_ships_by_coord {

    my $emp = shift;
    my $xcoord = shift;
    my $ycoord = shift;
    my @ship;

    for my $ship (values %{$emp->{SHIP}}) {
	push @ship,$ship if (($ship->xcoord() == $xcoord && ($ship->ycoord() == $ycoord)));
    }

    return @ship;
}
sub getsector {my ($emp,$x,$y) = @_; return $emp->{SECTOR}->{$x}{$y}};
sub getship   {my ($emp,$id)   = @_; return $emp->{SHIP}->{$id}};
sub getships  {my ($emp) = @_; return keys %{$emp->{SHIP}}};
sub getunit   {my ($emp,$id)   = @_; return $emp->{UNIT}->{$id}};
sub getunits  {my ($emp) = @_; return keys %{$emp->{UNIT}}};
sub getplane  {my ($emp,$id)   = @_; return $emp->{PLANE}->{$id}};
sub getplanes {my ($emp) = @_; return keys %{$emp->{PLANE}}};
sub nnum      {my $emp = shift; return $emp->{nnum}};
sub exist     {my ($emp,$num) = @_; return defined $emp->{nation}->[$num]};
sub nat       {my ($emp,$num) = @_; return $emp->{nation}->[$num]};
sub gamename       { my ($nation) = shift; return $nation->{gamename};}
sub xsize          { my ($emp) = shift; return $emp->{version}->{WORLD_X}->{value};}
sub ysize          { my ($emp) = shift; return $emp->{version}->{WORLD_Y}->{value};}
sub maxcoun        { my ($emp) = shift; return $emp->{version}->{maxcoun}->{value};}
sub xleft          { my ($emp) = shift; return -$emp->xsize()/2;}
sub xright         { my ($emp) = shift; return $emp->xsize()/2-1;}
sub ytop           { my ($emp) = shift; return -$emp->ysize()/2;}
sub ybottom        { my ($emp) = shift; return $emp->ysize()/2-1;}
sub secname  { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{name}}
sub secmcost { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{mcost}}
sub secmoff  { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{moff}}
sub secmdef  { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{mdef}}
sub secpackm { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{packm}}
sub secpacku { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{packu}}
sub secpackc { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{packc}}
sub secpackb { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{packb}}
sub secpacko { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{packo}}
sub secmxpop { my $emp = shift; my $sym = shift; return $emp->{SHOW}{sector}{stats}{$sym}{mxpop}}

sub tonumber {

    my $string = shift;
    my $number;

    if ($string =~ /(.*)(\D)$/) {
        if ($2 eq 'K') {
            $number = $1 * 1000;
        }
        elsif ($2 eq 'M') {
            $number = $1 * 1000000;
        }
        elsif ($2 eq 'G') {
            $number = $1 * 1000000000;
        }
        elsif ($2 eq '%') {
            $number = $1;
        }
    }
    else {
        $number = $string;
    }
    return $number;
}
1;
