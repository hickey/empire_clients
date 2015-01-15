#!/usr/local/bin/perl
# $Id: parse.pl,v 2.9.3.1 1997/06/08 20:09:50 root Exp root $
#                      Perl Empire Interface Parser
#
#                Written by Drake Diedrich and Sam Tetherow
#
#
# DESCRIPTION:
# This module parses Empire data and stores it in variables.
#
# INSTALLATION:
# You do not need to do anything to install parse.pl.  It will be automatically
# included into pei when you connect to a game.  Just make sure that it
# is in the same directory as pei when pei is run.  Or you can put parse.pl
# in the directory ~/perl and add the following line to your ~/.login file:
#   setenv PERLLIB ~/perl
#
# AUTHORS:
# Written by Drake Diedrich.
# Modified to use packages by Ken Stevens.
# Completely rewritten by Sam Tetherow.
#
# BUG REPORTS:
# mail your bug-reports and comments to:
# tetherow@nol.org (Sam Tetherow)

#       --- Global variables ---
#
# Game related variables:
# $world{'etu'}                Number of Empire Time Units per update
# $world{'eps'}                Number of seconds per empire time unit
# $world{'timelimit'}          Number of seconds allowed per day
# $world{'cpe'}                Number of civilians to produce 1 BTU
# $world{'growfood'}           Food produced by a 100 fert (non-aggi) per etu
# $world{'harvest'}            Food harvest by 1 civ per etu
# $world{'obrate'}             Civilian babies born per ETU per civilian
# $world{'eatrate'}            Food eaten per person per ETU
# $world{'babyeat'}            Food eaten per baby at the update
# $world{'uwbrate'}            uw babies born per ETU per uw
# $world{'nofood'}             1 if food not needed
# $world{'irate'}              Interest per bar per etu
# $world{'trate'}              Tax per civ per etu
# $world{'utrate'}             Tax per uw per etu
# $world{'milcost'}            Cost per active military per ETU
# $world{'reservecost'}        Cost per reserve per ETU
# $world{'happe'}              strollers/civ required for hap p.e.
# $world{'edupe'}              grads/civ required for edu p.e.
# $world{'hapavg'}             etus which happiness is averaged over
# $world{'eduavg'}             etus which education is averaged over
# $world{'bleed'}              Percent tech/research bleed from world
# $world{'decay'}              Percent decay per etu
# $world{'easytech'}           Tech up to this amount is not reduced
# $world{'logtech'}            Log base factored into tech above easytech
# $sector{'max_mob'}           Maximum mobility in a sector
# $ship{'max_mob'}             Maximum mobility in a ship
# $plane{'max_mob'}            Maximum mobility in a plane
# $land{'max_mob'}             Maximum mobility in a unit
# $sector{'max_gain'}          Mobility gained in a sector at the update
# $ship{'max_gain'}            Ship mobility gained at the update
# $plane{'max_gain'}           Plane mobility gained at the update
# $land{'max_gain'}            Unit mobility gained at the update
# $sector{'seceff'}            Maximum sector efficiency gained at the update
# $ship{'max_eff'}             Maximum ship efficiency gained at the update
# $plane{'max_eff'}            Maximum plane efficiency gained at the update
# $land{'max_eff'}             Maximum unit efficiency gained at the update
# $world{'mfgtax'}             Tax on selling things
# $world{'salestax'}           Tax on buying things
# $world{'width'}              Width of the world
# $world{'height'}             Height of the world
# $world{'maxnumcountries'}    Maximum number of countries
# $world{'firerangefactor'}    Fire ranges are scaped by this number
# %world{'option'}             Array of options
# 
# Country related variables:
# $nation{$coun}{'name'}       Name of country
# $nation{$coun}{'cap'}        capitol of country
# $nation{$coun}{'money'}      money of country
# $nation{$coun}{'reserves'}   reserves of country
# $nation{$coun}{'edu'}        Edu of country
# $nation{$coun}{'happy'}      Happiness of country
# $nation{$coun}{'tech'}       Tech of country
# $nation{$coun}{'res'}        Research of country
# $nation{$coun}{'techfactor'} Tech factor of country
# $nation{$coun}{'plaguefactor'} Plague factor of country
# $nation{$coun}{'maxpop'}     Maximum population per sector of country
# $nation{$coun}{'maxciv'}     Maximum civs/sector for max growth of country
# $nation{$coun}{'maxuw'}      Maximum uws/sector for max growth of country
# $nation{$coun}{'needhappy'}  Happiness need for country
### May be supported
# $budget             Estimated treasury after the next update
# $estimated_delta    Change in the treasury at the next update
# %realm              List of realms
# %status             Array of country statuses
###
# 
# Sector related variables:
# $dump{'x,y'}{FIELD}          dump values (FIELD is dump header)
# $dump{'x,y'}{'bdes'}         bdes of sector if known
# $dump{'x,y'}{'oldown'}       oldowner of sector if known
# 
# Planes:
# $plane{ID}{FIELD}   ID is plane # FIELD are from headers in pdump
# $plane{TYPE}{FIELD} TYPE is plane type (first 4 chars) FIELD are from show p b
# $plane{ID}{'own'}   Owner of a plane if known
#
# Ships:
# $ship{ID}{FIELD}    ID is ship # FIELD are from headers in sdump
# $ship{TYPE}{FIELD}  TYPE is ship type (first 4 chars) FIELD are from show s b
# $ship{ID}{'own'}    Owner of a ship if known
#
# Units:
# $land{ID}{FIELD}    ID is land # FIELD are from headers in ldump
# $land{TYPE}{FIELD}  TYPE is land type (first 4 chars) FIELD are from show l b
# $land{ID}{'own'}    Owner of a land if known

if (!$main::parse_loaded) {
	package main;

	%month=('Jan', 1, 'Feb', 2, 'Mar', 3, 'Apr', 4, 'May', 5, 'Jun', 6, 'Jul', 7,
					'Aug', 8, 'Sep', 9, 'Oct', 10, 'Nov', 11, 'Dec', 12);
	%monthname=(0, 'Jan', 1, 'Feb', 2, 'Mar', 3, 'Apr', 4, 'May', 5, 'Jun', 6,
					'Jul', 7, 'Aug', 8, 'Sep', 9, 'Oct', 10, 'Nov', 11, 'Dec');
	%sectype=('gold mine','g', 'highway','+', 'airfield','*', 'warehouse','w',
						'mine','m', 'bridge span','=', 'capitol','c', 'mountain','^',
			'radar installation',')', 'light manufacturing','j', 'harbor','h',
			'enlistment center','e', 'bank','b', 'refinery','%', 'park','p',
			'headquarters','!', 'heavy manufacturing','k', 'agribusiness','a',
			'technical center','t', 'research lab','r', 'defense plant','d',
			'library/school','l', 'shell industry','i', 'wilderness','-',
			'oil field','o', 'fortress','f', 'nuclear plant','n',
			'sanctuary','s', 'wasteland','\\', 'uranium mine','u', 
						'bridge head','#');

	sub add_parsemap {
		local ($command, $len, $subroutine) = @_;
		local ($i);

		for ($i = $len; $i <= length($command); ++$i) {
			$parsemap{substr($command, 0, $i)} = $subroutine;
		}
	}
}

if (!$main::parse_loaded) {
	package main;

	&add_parsemap('change', 2, 'parse_change');
	&add_parsemap('version', 1, 'parse_version');
	&add_parsemap('dump',2,'parse_dump');
	&add_parsemap('sdump',2,'parse_sdump');
	&add_parsemap('pdump',3,'parse_pdump');
	&add_parsemap('ldump',3,'parse_ldump');
	&add_parsemap('show',4,'parse_show');
	&add_parsemap('budget',3,'parse_budget');
	&add_parsemap('neweff',4,'parse_neweff');
	&add_parsemap('product',2,'parse_product');
	&add_parsemap('nation',3,'parse_nation');
	&add_parsemap('realm',4,'parse_realm');
	&add_parsemap('navigate',3,'parse_look');
	&add_parsemap('march',3,'parse_look');
	&add_parsemap('lookout',3,'parse_look');
	&add_parsemap('llookout',4,'parse_look');
	&add_parsemap('sonar',3,'parse_look');
	&add_parsemap('coastwatch',3,'parse_look');
	&add_parsemap('spy',2,'parse_spy_report');
	&add_parsemap('recon',3,'parse_spy_plane');
	&add_parsemap('bomb',3,'parse_spy_plane');
	&add_parsemap('fly',3,'parse_spy_plane');
	&add_parsemap('paradrop',4,'parse_spy_plane');
	&add_parsemap('drop',3,'parse_spy_plane');
	&add_parsemap('satellite',3,'parse_satellite');
	&add_parsemap('level',3,'parse_level');
	&add_parsemap('build',3,'parse_build');
	$parsemap{'show ship build'}='parse_ship_build';
	$parsemap{'show ship stats'}='parse_ship_stats';
	$parsemap{'show land build'}='parse_land_build';
	$parsemap{'show land stats'}='parse_land_stats';
	$parsemap{'show plane build'}='parse_plane_build';
	$parsemap{'show plane stats'}='parse_plane_stats';
	$parsemap{'show capabilities'}='parse_capabilities';
	&add_parsemap('country',3,'parse_country');
	&add_parsemap('read',4,'parse_read');
	$parsemap{'show sect stats'}='parse_sector_stats';
	$parsemap{'show sect build'}='parse_sector_build';
	&add_parsemap('map',2,'parse_map');
	&add_parsemap('bmap',2,'parse_map');
	&add_parsemap('explore',3,'parse_explore');
	&add_parsemap('info',1,'parse_show');
}

$DEBUG=1;

sub parse_change {
	if (/^Country \#(\d+) is already called/) {
		$coun = $1;
	}
}

$world{'firerangefactor'} = 1.0;		# for backwards compatability

sub parse_version {
	if (/World size is (\d+) by (\d+)\./) {
		$world{'width'} = $1;
		$world{'height'} = $2;
		return;
	}
	if (/There can be up to (\d+) countries\./) {
		$world{'maxnumcountries'} = $1;
		return;
	}
	if (/An Empire time unit is (\d+) seconds long\./) {
		$world{'eps'}=$1;
		return;
	}
	if (/An update consists of (\d+) empire time units/) { 
		$world{'etu'}=$1; 
		return; 
	}
	if (/Each country is allowed to be logged in (\d+) minutes a day\./) {
		$world{'timelimit'}=$1;
		return;
	}
	if (/It takes (\S+) civilians to produce a BTU in one time unit\./) {
		$world{'cpe'}=$1;
		return;
	}
	if (/A non-aggi, 100 fertility sector can grow (\S+) food per etu\./) {
		$world{'growfood'}=$1/100;
		return;
	}
	if (/1000 civilians will harvest (\S+) food per etu\./) {
		$world{'harvest'}=$1/1000;
		return;
	}
	if (/1000 civilians will give birth to (\S+) babies per etu./) {
		$world{'obrate'} = $1/1000.0;
		return;
	}
	if (/1000 uncompensated workers will give birth to (\S+) babies./) {
		$world{'uwbrate'} = $1/1000.0;
		return;
	}
	if (/In one time unit, 1000 people eat (\S+) units of food./) {
		$world{'eatrate'} = $1/1000.0;
		return;
	}
	if (/1000 babies eat (\S+) units of food becoming adults./) {
		$world{'babyeat'} = $1/1000.0;
		return;
	}
	if (/No food is needed!!/) {
		$world{'nofood'}=1;
		return;
	}
	if (/Banks pay \$(\S+) in interest per 1000 gold barse per etu\./) {
		$world{'irate'}=$1/1000;
		return;
	}
	if (/1000 civilians generate \$(\S+), uncompensated workers \$(\S+) each time unit\./) {
		$world{'trate'}=$1/1000;
		$world{'utrate'}=$1/1000;
		return;
	}
	if (/1000 active military cost \$(\S+), reserves cost \$(\S+)\.$/) {
		$world{'milcost'}=$1 / 1000.0;
		$world{'reservecost'}=$2/1000.0;
		return;
	}
	if (/Happiness p\.e\. requires (\d+) happy stroller per (\d+) civ\./) {
		$world{'happe'}=$1/$2;
		return;
	}
	if (/Education p\.e\. requires (\d+) class of graduates per (\d+) civ\./) {
		$world{'edupe'}=$1/$2;
		return;
	}
	if (/Happiness is averaged over (\d+) time units\./) {
		$world{'hapavg'}=$1;
		return;
	}
	if (/Education is averaged over (\d+) time units\./) {
		$world{'eduavg'}=$1;
		return;
	}
	if (/The technology\/research boost you get from the world is (\S+)%\./) {
		$world{'bleed'}=$1;
		return;
	}
	if (/Nation levels \(tech etc.\) decline (\d+)% every (\d+) time units./) {
		$world{'decay'} = $1 * $etu / $2 / 100.0;
	}
	if (/Tech Buildup is limited to logarithmic growth \(base (.+)\) after (.+)\./) {
		$world{'easytech'} = $2;
		$world{'logtech'} = $1;
		return;
	}
	if (/Maximum mobility\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
		$sector{'max_mob'}=$1;
		$ship{'max_mob'}=$2;
		$plane{'max_mob'}=$3;
		$land{'max_mob'}=$4;
		return;
	}
	if (/Max mob gain per update\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
		if ($1>0) { $sector{'max_gain'} = $1; }
		if ($2>0) { $ship{'max_gain'} = $2; }
		if ($3>0) { $plane{'max_gain'} = $3;}
		if ($4>0) { $land{'max_gain'} = $4; }
		return;
	}
	if (/Max eff gain per update\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
		if ($1>0) { $sector{'max_eff'} = $1; }
		if ($2>0) { $ship{'max_eff'} = $2; }
		if ($3>0) { $plane{'max_eff'} = $3;}
		if ($4>0) { $land{'max_eff'} = $4; }
		return;
	}
	if (/The tax you pay on selling things on the trading block is (\S+)%/) {
		$world{'mfgtax'}=$1;
		return;
	}
	if (/The tax you pay on buying commodities on the market is (\S+)%/) {
		$world{'salestax'}=$1;
		return;
	}
	if (/Fire ranges are scaled by (.*)/) {
		$world{'firerangefactor'} = $1;
	}
	if (/Options enabled in this game:/) {
		$options=1;
		return;
	}
	if ($options==1) {
		@F = split(/\,/, $_);
		$options=0 if ($#F<1);
		for ($i=0;$i<=$#F;$i++) { $F[$i]=~s/\s+//go; $world{'option'}{$F[$i]}="1"; }
	}
}

# Need to check for the realm (only *) for keeping track of last dump
sub parse_dump {
	local($i,@F,$x,$y);

	if (/DUMP SECTOR (\d+)/) {
		$last_dump=$1;
		return;
	}
	elsif (/x y des sdes/) {
		@header = split(/\s+/, $_);
		for ($i=0;$i<=$#header;$i++) {
			if ($header[$i] eq 'x') {
				$xpos=$i;				# Find x and y since they are keys
				$ypos=$i + 1;
				last;
			}
		}
	} else {
		@F = split(/\s+/, $_);
		if ($#header != $#F) {
			if ($#header>0) { undef @header; undef $xpos; undef $ypos; }
			return;
		}
		$x = $F[$xpos];
		$y = $F[$ypos];
		for ($i=0;$i<=$#F;$i++) {
			$dump{$x,$y}{$header[$i]} = $F[$i];
		}
		if ($dump{$x,$y}{'*'} eq '*') {
			if (!defined($dump{$x,$y}{'oldown'})) {
				$dump{$x,$y}{'oldown'} = 0;
			}
		} else {
			$dump{$x,$y}{'oldown'} = $coun;
		}
		$dump{$x,$y}{'own'} = $coun;
	}
}

sub parse_sdump {
	if (/DUMP SHIPS (\d+)/) {
		$last_sdump=$1;
	} elsif (/^\s*id\s*type/) {			# this line gives us the fields
		@sfields=split(/\s+/, $_);
		for($i=0;$i<=$#sfields;$i++) {
			if ($sfield[$i]=='id') {
				$idfield=$i;
				last;
			}
		}
	} else {
		@F=split(/\s+/, $_);
		if ($#sfields>$#F) {
			if ($#sfields>0) { undef @sfields; undef $idfield; }
			return;
		}
		$id=$F[$idfield];
		for($i=0; $i<=$#sfields; $i++) {
			$data=shift(@F);
			if (substr($data, 0, 1) eq '"') {
				while(substr($data, -1, 1) ne '"' || length($data)<2) {
					$data=$data . " " . shift(@F);
				}
			}
			$ship{$id}{$sfields[$i]}=$data;
		}
		$ship{$id}{'own'}=$coun;
	}
}

sub parse_ldump {
	if (/DUMP LAND UNITS (\d+)/) {
		$last_ldump=$1;
	} elsif (/^\s*id\s*type/) {			# this line gives us the fields
		@lfields=split(/\s+/, $_);
		for($i=0;$i<=$#lfields;$i++) {
			if ($lfield[$i]=='id') {
				$idfield=$i;
				last;
			}
		}
	} else {
		@F=split(/\s+/, $_);
		if ($#lfields>$#F) {
			if ($#lfields>0) { undef @lfields; undef $idfield; }
			return;
		}
		$id=$F[$idfield];
		for($i=0; $i<=$#lfields; $i++) {
			$data=shift(@F);
			if (substr($data, 0, 1) eq '"') {
				while(substr($data, -1, 1) ne '"' || length($data)<2) {
					$data=$data . " " . shift(@F);
				}
			}
			$land{$id}{$lfields[$i]}=$data;
		}
		$land{$id}{'own'}=$coun;
	}
}


sub parse_pdump {
	if (/DUMP PLANES (\d+)/) {
		$last_pdump=$1;
	} elsif (/^\s*id\s*type/) {			# this line gives us the fields
		@pfields=split(/\s+/, $_);
		for($i=0;$i<=$#pfields;$i++) {
			if ($pfields[$i]=='id') {
				$idfield=$i;
				last;
			}
		}
	} else {
		@F=split(/\s+/, $_);
		if ($#pfields>$#F) {
			if ($#pfields>0) { undef @pfields; undef $idfield; }
			return;
		}
		$id=$F[$idfield];
		for($i=0; $i<=$#pfields; $i++) {
			$data=shift(@F);
			if (substr($data, 0, 1) eq '"') {
				while(substr($data, -1, 1) ne '"' || length($data)<2) {
					$data=$data . " " . shift(@F);
				}
			}
			$plane{$id}{$pfields[$i]}=$data;
		}
		$plane{$id}{'own'}=$coun;
	}
}

sub parse_show {
	($show_type)=(split(/\s+/, $main::commandarg))[0];
	if ($show_type=~/^l/) { $show_type="land"; }
	elsif ($show_type=~/^p/) { $show_type="plane"; }
	elsif ($show_type=~/^se/) { $show_type="sect"; }
	elsif ($show_type=~/^s/) { $show_type="ship"; }
	if (/sector type\s+mcost\s+off\s+def/) { 
		$main::command='show sect stats'; 
	}
	elsif (/^\s*sector type\s+cost to des/) {
		$main::command='show sect build'; 
	}
	elsif (/^\s+lcm hcm avail tech \$$/) {
		$main::command='show ship build'; 
	}
	elsif (/ *def  d  s  y  g  r  d  n  l  l/) {
		$main::command='show ship stats'; 
	}
	elsif (/ *cargos & capabilities/) {
		$main::command='show capabilities'; 
	}
	elsif (/\s+lcm\s+hcm\s+guns\s+avail\s+tech\s+\$/) {
		$main::command='show land build'; 
	}
	elsif (/^ *capabilities$/) {
		$main::command='show capabilities'; 
	}
	elsif (/ *att def vul  d  s  y  d  g  c  m  m  f  c  u  l/) {
		$main::command='show land stats';
	}
	elsif (/ *att def vul  d  s  y  d  g  f  c  u  l/) {
		$main::command='show land stats';
	}
	elsif (/ *lcm hcm crew avail tech  \$$/) {
		$main::command='show plane build'; 
	}
	elsif (/ *acc load att def ran fuel stlth/) {
		$main::command='show plane stats'; 
	}
	elsif (/^Bridges require (\d+) tech, (\d+) hcm, (\d+) workers,/) {
		$bridgetech=$1;
		$bridgehcm=$2;
		$bridgeworkers=$3;
	}
	elsif (/^(\d+) available workforce, and cost \$(\d+)/) {
		$bridgeavail=$1;
		$bridgecost=$2;
	}
}

sub parse_budget {
	if (/Esitmated new treasury\.+(\d+)/) { $budget = $1; }
	elsif (/Estimated Delta\.+(\d+)/) { $estimated_delta = $1; }
}

sub parse_neweff {
	if (/(\S+,\S+)\s+(\S) +(\d+)\%$/) {
		$newdes{$1}=$2;
		$neweff{$1}=$3;
	}
}

sub parse_product {
	if (/PRODUCTION SIMULATION/) { 	# undef old values we can't rely on them
		undef %wkfc;
		undef %will;
		undef %make;
		undef %prodmax;
		undef %use1;
		undef %use2;
		undef %use3;
		undef %max1;
		undef %max2;
		undef %max3;
		undef %comm1;
		undef %comm2;
		undef %comm3; 
	}
	elsif (/^\s*(\S+,\S+)\s+(\S)\s+\d+\%\s+(\d+)\s+(\S+)\s+(\S+)\s+\S+\s+\$\d+\s+(\S+)$/) {
		$newdes{$1}=$2;
		$wkfc{$1}=$3;
		$will{$1}=$4;
		$make{$1}=$5;
		$prodmax{$1}=$6;

	} elsif (/^\s*(\S+,\S+)\s+(\S)\s+\d+\%\s+(\d+)\s+(\S+)\s+(\S+)\s+\S+\s+\$\d+\s+(\d+)([a-z])\s+(\d+)[a-z]\s+(\S+)$/) {
		$newdes{$1}=$2;
		$wkfc{$1}=$3;
		$will{$1}=$4;
		$make{$1}=$5;
		$use1{$1}=$6;
		$comm1{$1}=$commstr{$7};
		$max1{$1}=$8;
		$prodmax{$1}=$9;

	} elsif (/^\s*(\S+,\S+)\s+(\S)\s+\d+\%\s+(\d+)\s+(\S+)\s+(\S+)\s+\S+\s+\$\d+\s+(\d+)([a-z])\s+(\d+)([a-z])\s+(\d+)[a-z]\s+(\d+)[a-z]\s+(\S+)$/) {
		$newdes{$1}=$2;
		$wkfc{$1}=$3;
		$will{$1}=$4;
		$make{$1}=$5;
		$use1{$1}=$6;
		$comm1{$1}=$commstr{$7};
		$use2{$1}=$8;
		$comm2{$1}=$commstr{$9};
		$max1{$1}=$10;
		$max2{$1}=$11;
		$prodmax{$1}=$12;

	} elsif (/^\s*(\S+,\S+)\s+(\S)\s+\d+\%\s+(\d+)\s+(\S+)\s+(\S+)\s+\S+\s+\$\d+\s+(\d+)([a-z])\s+(\d+)([a-z])\s+(\d+)([a-z])\s+(\d+)[a-z]\s+(\d+)[a-z]\s+(\d+)[a-z]\s+(\S+)$/) {
		$newdes{$1}=$2;
		$wkfc{$1}=$3;
		$will{$1}=$4;
		$make{$1}=$5;
		$use1{$1}=$6;
		$comm1{$1}=$commstr{$7};
		$use2{$1}=$8;
		$comm2{$1}=$commstr{$9};
		$use3{$1}=$10;
		$comm3{$1}=$commstr{$11};
		$max1{$1}=$12;
		$max2{$1}=$13;
		$max3{$1}=$14;
		$prodmax{$1}=$15;
	}
	if ($make{$1} eq 'petro') { $make{$1}='pet'; }
	if ($make{$1} eq 'bars') { $make{$1}='bar'; }
	if ($make{$1} eq 'guns') { $make{$1}='gun'; }
}

sub parse_nation {
	if (/\(\#(\d+)\)\s+(.+) Nation Report/) {
		$coun = $1;
		$nation{$coun}{'name'} = $2;
		$new_server = 1;
	}
	elsif (/.* eff(| mountain) capit[oa]l at (\S+)/) { 
		$nation{$coun}{'cap'} = $2; 
	}
	elsif (/No capit[oa]l\./) { 
		$nation{$coun}{'cap'} = ''; 
	}
	elsif (/\s+The treasury has\s+\$(\d+)\.00\s+Military\s+reserves:\s+(\d+)/) {
		$nation{$coun}{'money'} = $1;
		$nation{$coun}{'reserves'} = $2;
	}
	elsif (/Education\.+\s*(\S+)\s+Happiness\.+\s*(\S+)/) {
		$nation{$coun}{'edu'} = $1;
		$nation{$coun}{'happy'} = $2;
	}
	elsif (/Technology\.+\s*(\S+)\s+Research\.+\s*(\S+)/) {
		$nation{$coun}{'tech'} = $1;
		$nation{$coun}{'res'} = $2;
	}
	elsif (/Technology factor\s+:\s+(.+)%\s+Plague factor\s+:\s+([^%]+)%/) {
		$nation{$coun}{'techfactor'} = $1;
		$nation{$coun}{'plaguefactor'} = $2;
	}
	elsif (/^Max population\s+:\s+(\d+)/) { 
		$nation{$coun}{'maxpop'}=$1; 
	}
	elsif (/^Max safe population for civs\/uws:\s+(\d+)\/(\d+)$/) {
		$nation{$coun}{'maxciv'}=$1;
		$nation{$coun}{'maxuw'}=$2;
	}
	elsif (/^Happiness needed is (\S+)\s/) {
		$nation{$coun}{'needhappy'} = $1;
	}
}

sub parse_realm {
	if (/^Realm \#(\d+) is (\S+)$/) {
		$realm{$1} = $2;
	}
}

# Unchecked
sub parse_look {
	## mine detection from nuke sub 2s needs to be added (and the auto-des of the
	## bmap accordingly.  Also need to add this into parse_nav.
	if (/^Your (.+) (\d+)% efficient (.*)\s*@ (\S+,\S+)\s*/) {
		local($contents, $sect)=($3, $4);
		$own{$sect}=$coun;
		$dump{$sect, "eff"}=$2;
		$dump{$sect, "des"}=$main::sectype{$1};
		if ($contents=~/with (\d+) civ/) { $dump{$sect, "civ"}=$1; }
		if ($contents=~/with (\d+) mil/) { $dump{$sect, "mil"}=$1; }
	}
	elsif (/^(.+)\s+\(#(\d+)\) (.+) (\d+)% efficient (.*)\s*@ (\S+,\S+)\s*/) {
		local($sect, $contents)=($6, $5);
		$country{$2}=$1; $number{$1}=$2; $own{$6}=$2; 
		$dump{$sect, "eff"}=$4;
		$dump{$sect, "des"}=$main::sectype{$3};
		if ($contents=~/with approx (\d+) civ/) { $dump{$sect, "civ"}=$1+1; }
		if ($contents=~/with approx (\d+) mil/) { $dump{$sect, "mil"}=$1+1; }
		local(@tmp)=localtime;
		$dump{$sect, 'date'}="$tmp[4]/$tmp[3] $tmp[2]:$tmp[1]";
	}
	elsif (/^\s*(.+)\s+\(#\s*(\d+)\)\s+(\S+\D*\d*)\s+#(\d+)\s+@\s*(\S+,\S+)\s*/) {
		$country{$2}=$1;
		$number{$1}=$2;
		if ($shipname{$3}) {
			$shipname{$4}=$3;
			$shipsect{$4}=$5;
			$shipown{$4}=$2;
			local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
			$shipdate{$4}="$mon/$mday $hour:$min";
		} elsif ($unitname{$3}) {
			$unitname{$4}=$3;
			$unitsect{$4}=$5;
			$unitown{$4}=$2;
			local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
			$unitdate{$4}="$mon/$mday $hour:$min";
		}
	}
}

sub parse_spy_plane {
	if (/^Your (.+) (\d+)% efficient (.*)\s*@ (\S+,\S+)\s*/) {
		local($contents, $sect)=($3, $4);
		$own{$sect}=$coun;
		$dump{$sect, "eff"}=$2;
		$dump{$sect, "des"}=$main::sectype{$1};
		if ($contents=~/with (\d+) civ/) { $dump{$sect, "civ"}=$1; }
		if ($contents=~/with (\d+) mil/) { $dump{$sect, "mil"}=$1; }
	} elsif (/^(.+)\s+\(#(\d+)\) (.+) (\d+)% efficient (.*)\s*@ (\S+,\S+)\s*/) {
		local($sect, $contents)=($6, $5);
		$country{$2}=$1; $number{$1}=$2; $own{$6}=$2; 
		$dump{$sect, "eff"}=$4;
		$dump{$sect, "des"}=$main::sectype{$3};
		if ($contents=~/with approx (\d+) civ/) { $dump{$sect, "civ"}=$1+1; }
		if ($contents=~/with approx (\d+) mil/) { $dump{$sect, "mil"}=$1+1; }
		local(@tmp)=localtime;
		$dump{$sect, 'date'}="$tmp[4]/$tmp[3] $tmp[2]:$tmp[1]";
	} elsif (/\s*(\S+,\S+)\s+(\S)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*/) {
		$own{$1}=$3;
		$dump{$1,"des"}=$2;
		$dump{$1,"eff"}=$4;
		$dump{$1,"civ"}=$5;
		$dump{$1,"mil"}=$6;
		$dump{$1,"shell"}=$7;
		$dump{$1,"gun"}=$8;
		$dump{$1,"iron"}=$9;
		$dump{$1,"pet"}=$10;
		$dump{$1,"food"}=$11;
		local(@tmp)=localtime;
		$dump{$1, 'date'}="$tmp[4]/$tmp[3] $tmp[2]:$tmp[1]";
	} elsif (/flying over\s+(.+)\s+at\s+(\S+,\S+)/) {
		$bmap{$2}=$main::sectype{$1}; $last_overfly_sect=$2;
	} elsif (/^\s*(\d+)\s+(\d+)\s+(\S+\D*\d*)\s+(\S+,\S+)\s+(\d+)%\s*$/) {
		local($own, $unit, $type, $sect, $eff)=($1, $2, $3, $4, $5);
		$type=~s/\s*$//;
		if ($unitname{$type}) {
			$unitname{$unit}=$type; 
			$unitown{$unit}=$own; 
			$unitsect{$unit}=$sect; 
			$uniteff{$unit}=$eff;
			local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
			$unitdate{$unit}="$mon/$mday $hour:$min";
		} elsif ($shipname{$type}) {
			$shipname{$unit}=$type; 
			$shipown{$unit}=$own;
			$shipsect{$unit}=$sect;
			$shipeff{$unit}=$eff;
			local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
			$shipdate{$unit}="$mon/$mday $hour:$min";
		}
	} elsif (/\s*\(#\s*(\d+)\)\s+(.+)\s+(minimally|partially|moderately|completely)\s+(\S+\D*\d*)\s*$/) {
		local($unit, $countryname, $eff, $type)=($1, $2, $3, $4);
		$countryname=~s/\s*$//; $type=~s/\s*$//;
		local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
		if ($unitname{$type}) {
			$uniteff{$unit}=25 if $eff eq 'minimally';  
			$uniteff{$unit}=50 if $eff eq 'partially';  
			$uniteff{$unit}=75 if $eff eq 'moderately'; 
			$uniteff{$unit}=100 if $eff eq 'completely'; 
			$unitown{$unit}=$number{$countryname};
			$unitsect{$unit}=$last_overfly_sect;
			$unitname{$unit}=$type;
			$unitdate{$unit}="$mon/$mday $hour:$min";
		} elsif ($planename{substr($type,0,19)}) {
			$planeeff{$unit}=25 if $eff eq 'minimally';  
			$planeeff{$unit}=50 if $eff eq 'partially';  
			$planeeff{$unit}=75 if $eff eq 'moderately'; 
			$planeeff{$unit}=100 if $eff eq 'completely'; 
			$planeown{$unit}=$number{$countryname};
			$planesect{$unit}=$last_overfly_sect;
			$planename{$unit}=substr($type,0,19);
			$planedate{$unit}="$mon/$mday $hour:$min";
		} elsif ($shipname{$type}) {
			$shipeff{$unit}=25 if $eff eq 'minimally';  
			$shipeff{$unit}=50 if $eff eq 'partially';  
			$shipeff{$unit}=75 if $eff eq 'moderately'; 
			$shipeff{$unit}=100 if $eff eq 'completely'; 
			$shipown{$unit}=$number{$countryname};
			$shipsect{$unit}=$last_overfly_sect;
			$shipname{$unit}=$type;
			$shipdate{$unit}="$mon/$mday $hour:$min";
		}
	}
}

sub parse_spy_report {
	if (/\s*(\S+,\S+)\s+(\S)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*/) {
		$own{$1}=$3;
		$dump{$1,"des"}=$2;
		$dump{$1,"eff"}=$4;
		$dump{$1,"civ"}=$5;
		$dump{$1,"mil"}=$6;
		$dump{$1,"shell"}=$7;
		$dump{$1,"gun"}=$8;
		$dump{$1,"iron"}=$9;
		$dump{$1,"pet"}=$10;
		$dump{$1,"food"}=$11;
		local(@tmp)=localtime;
		$dump{$1, 'date'}="$tmp[4]/$tmp[3] $tmp[2]:$tmp[1]";
	} elsif (/$Spies report .+ unit in (\S+,\S+): (.+) #(\d+) (.*)/) {
		$unitown{$3}=$own{$1};
		$unitsect{$3}=$1;
		$unitname{$3}=$2;
		local($unit, $rest)=($3, $4);
		if ($rest=~/efficiency (\d+)[,\)]/) { $uniteff{$unit}=$1; }      
		if ($rest=~/tech (\d+)\)/) { $unittech{$unit}=$1; }      
		local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
		$unitdate{$unit}="$mon/$mday $hour:$min";
	}
}

sub parse_satellite {
	if (/\s*(\S+,\S+)\s+(\S)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*/) {
		$own{$1}=$3;
		$dump{$1,"des"}=$2;
		$dump{$1,"eff"}=$4;
		$dump{$1,"civ"}=$5;
		$dump{$1,"mil"}=$6;
		$dump{$1,"shell"}=$7;
		$dump{$1,"gun"}=$8;
		$dump{$1,"iron"}=$9;
		$dump{$1,"pet"}=$10;
		$dump{$1,"food"}=$11;
		local(@tmp)=localtime;
		$dump{$1, 'date'}="$tmp[4]/$tmp[3] $tmp[2]:$tmp[1]";
	}
	elsif (/^\s*(\d+)\s+(\d+)\s+(\S+\D*\d*)\s+(\S+,\S+)\s+(\d+)%\s*$/) {
		local($own, $unit, $type, $sect, $eff)=($1, $2, $3, $4, $5);
		$type=~s/\s*$//;
		if ($unitname{$type}) {
			$unitname{$unit}=$type; $unitown{$unit}=$own; 
			$unitsect{$unit}=$sect; $uniteff{$unit}=$eff;
			local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
			$unitdate{$unit}="$mon/$mday $hour:$min";
		} elsif ($shipname{$type}) {
			$shipname{$unit}=$type; $shipown{$unit}=$own; 
			$shipsect{$unit}=$sect; $shipeff{$unit}=$eff;
			local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
			$shipdate{$unit}="$mon/$mday $hour:$min";
		}
	}
}

sub parse_ship_build {
	my(@builddata, $type);
	@builddata=split(/\s+/, $_);
	return if ($#builddata<6);
	$type=shift(@builddata);
	$ship{$type}{'cost'}=pop(@builddata);
	$ship{$type}{'cost'}=~s/\$//g;
	$ship{$type}{'tech'}=pop(@builddata);
	$ship{$type}{'avail'}=pop(@builddata);
	$ship{$type}{'hcm'}=pop(@builddata);
	$ship{$type}{'lcm'}=pop(@builddata);
	$ship{$type}{'name'}=join(' ', @builddata);
}

sub parse_capabilities {
	local (@F,$name,$tmp);
	if (/^(\S+( {1,2}\S+)*)  +/) {
		$name=$1;
		@F=split(/\s+/,$');
		($type)=split(/\s+/, $name);
		while ($tmp=pop(@F)) {
			if ($tmp =~ /(\d+)([a-z])/) { 
				$tag=$2 . "lim"; $amt=$1;
				if ($show_type=~/ship/) { $ship{$type}{$tag}=$amt; }
				if ($show_type=~/land/) { $ship{$type}{$tag}=$amt; }
				if ($show_type=~/plane/) { $ship{$type}{$tag}=$amt; }
			} else { 
				if ($show_type=~/ship/) { $ship{$type}{$tmp}=1; }
				if ($show_type=~/land/) { $ship{$type}{$tmp}=1; }
				if ($show_type=~/plane/) { $ship{$type}{$tmp}=1; }
			}
		}
	}
}

sub parse_ship_stats {
	my($statdata, $type);
	@statdata=split(/\s+/, $_);
	return if ($#statdata<11);
	$type=shift(@statdata);
	$ship{$type}{'xpl'}=pop(@statdata);
	$ship{$type}{'hel'}=pop(@statdata);
	$ship{$type}{'pln'}=pop(@statdata);
	$ship{$type}{'lnd'}=pop(@statdata);
	$ship{$type}{'fir'}=pop(@statdata);
	$ship{$type}{'rng'}=pop(@statdata);
	$ship{$type}{'spy'}=pop(@statdata);
	$ship{$type}{'vis'}=pop(@statdata);
	$ship{$type}{'spd'}=pop(@statdata);
	$ship{$type}{'def'}=pop(@statdata);
	$ship{$type}{'name'}=join(' ', @statdata);
}

sub parse_land_stats {
	my(@statdata, $type);
	@statdata=split(/\s+/, $_);
	return if ($#statdata<16);
	$type=shift(@statdata);
	$land{$type}{'lnd'}=pop(@statdata);
	$land{$type}{'xpl'}=pop(@statdata);
	$land{$type}{'fu'}=pop(@statdata);
	$land{$type}{'fc'}=pop(@statdata);
	$land{$type}{'aaf'}=pop(@statdata);
	$land{$type}{'amm'}=pop(@statdata);
	$land{$type}{'dam'}=pop(@statdata);
	$land{$type}{'acc'}=pop(@statdata);
	$land{$type}{'frg'}=pop(@statdata);
	$land{$type}{'rad'}=pop(@statdata);
	$land{$type}{'spy'}=pop(@statdata);
	$land{$type}{'vis'}=pop(@statdata);
	$land{$type}{'spd'}=pop(@statdata);
	$land{$type}{'vul'}=pop(@statdata);
	$land{$type}{'def'}=pop(@statdata);
	$land{$type}{'att'}=pop(@statdata);
	$land{$type}{'name'}=join(' ', @statdata);
}

sub parse_land_build {
	my(@builddata, $type);
	@builddata=split(/\s+/, $_);
	return if ($#builddata<7);
	$type=shift(@builddata);
	$land{$type}{'cost'}=pop(@builddata);
	$land{$type}{'cost'}=~s/\$//g;
	$land{$type}{'tech'}=pop(@builddata);
	$land{$type}{'avail'}=pop(@builddata);
	$land{$type}{'guns'}=pop(@builddata);
	$land{$type}{'hcm'}=pop(@builddata);
	$land{$type}{'lcm'}=pop(@builddata);
	$land{$type}{'name'}=join(' ', @builddata);
}


sub parse_plane_build {
	my(@builddata, $type);
	@builddata=split(/\s+/, $_);
	return if ($#builddata<7);
	$type=shift(@builddata);
	$plane{$type}{'cost'}=pop(@builddata);
	$plane{$type}{'cost'}=~s/\$//g;
	$plane{$type}{'tech'}=pop(@builddata);
	$plane{$type}{'avail'}=pop(@builddata);
	$plane{$type}{'crew'}=pop(@builddata);
	$plane{$type}{'hcm'}=pop(@builddata);
	$plane{$type}{'lcm'}=pop(@builddata);
	$plane{$type}{'name'}=join(' ', @builddata);
}


sub parse_plane_stats {
	my(@data, $type);
	@data=split(/\s+/, $_);
	return if ($#data<8);
	$type=shift(@data);
	$plane{$type}{'stlth'}=pop(@data);
	$plane{$type}{'fuel'}=pop(@data);
	$plane{$type}{'ran'}=pop(@data);
	$plane{$type}{'def'}=pop(@data);
	$plane{$type}{'att'}=pop(@data);
	$plane{$type}{'load'}=pop(@data);
	$plane{$type}{'acc'}=pop(@data);
	$land{$type}{'name'}=join(' ', @data);
}

sub parse_map {
# Internal variables: 
#   @H		Header lines of the map.
#   %mapcol		The x coordinates.
#   $mapheader	Set to 1 if the header has already been read.
#   $maprow		The current y coordinate.
#   $mappartial	Contains the map data minus the y coordinate.
	local($x, $y, $digit);
	if ($mapheader==0) {
		if (/\s*\S+\s+\S+/) { 
			$mapheader=1;
			for($x=0;$x<length($H[0]); $x++) {
				$mapcol[$x]=0;
	for($y=0;$y<=$#H;$y++) { 
		$digit=substr($H[$y], $x, 1);
		if ($digit=~/\d/) {
			$mapcol[$x]=$mapcol[$x]*10+substr($H[$y],$x,1); 
					}
				}
			}
			for($x=0;$x<$#mapcol;$x++) {
				if ($mapcol[$x]>$mapcol[$x+1]) { $mapcol[$x]*=-1; }
			}
			if ($mapcol[$#mapcol-1]<0 && $mapcol[$#mapcol]<(-1*$mapcol[$#mapcol-1])) {
				$mapcol[$#mapcol]*=-1;
			}
			undef @H; 
		} else {
			undef @mapcol;
			push(@H, $_);
			$H[$#H]=~s/^\s*//; $H[$#H]=~s/\s*$//;
		}
	}
	if (/\s*(\S+) (.+) \S+\s*$/ && $mapheader==1) { 
		$maprow=$1; $mappartial=$2;
		for($x=0; $x<=$#mapcol; $x++) { 
			$xy="$mapcol[$x],$maprow";
			if (substr($mappartial, $x, 1) cmp ' ') {
				$dump{$xy}{'bdes'}=substr($mappartial, $x, 1);
			}
		}
	} else { $mapheader=0; }
}
		
sub parse_sector_stats {
	my(@data, $des, $type, $mcost, $off, $def, $pmil, $puw, $pciv, $pbar, $po);
	@data=split(/\s+/, $_);
	$des=shift(@data);
	$po=pop(@data);
	$pbar=pop(@data);
	$pciv=pop(@data);
	$puw=pop(@data);
	$pmil=pop(@data);
	$def=pop(@data);
	$off=pop(@data);
	$mcost=pop(@data);
	$type=join(' ', @data);
	$sector{$des}{'type'}=$type;
	$sector{$des}{'mcost'}=$mcost;
	$sector{$des}{'off'}=$off;
	$sector{$des}{'def'}=$def;
	$sector{$des}{'pmil'}=$pmil;
	$sector{$des}{'puw'}=$puw;
	$sector{$des}{'pciv'}=$pciv;
	$sector{$des}{'pbar'}=$pbar;
	$sector{$des}{'po'}=$po;
}

# Needs fixed.
sub parse_sector_build {
	if (/(\S)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*/) {
		$descost{$1}=$2;
		$buildcost{$1}=$3;
		$buildlcm{$1}=$4;
		$buildhcm{$1}=$5;
	}
}


# Unchecked
sub parse_attack {
	if (/(\S+,\S+) is a (\d+)% (.+) with approximately (\d+) military\.$/) {
		local($thiscoun, $eff, $mil)=($3, $2, $4);
		$last_attacked_sector=$1;
		local(@info)=split(/ /, $3);
		if ($main::sectype{$info[$#info]}) { 
			local($type)=pop(@info);
			$dump{$last_attacked_sector, 'des'}=$main::sectype{$type}; 
		} else { 
			local($type)=pop(@info); $type=pop(@info) . " " . $type;
			$dump{$last_attacked_sector, 'des'}=$main::sectype{$type}; 
		}
		$thiscoun=join(' ', @info);
		$own{$last_attacked_sector}=$number{$thiscoun};
		if (!$own{$last_attacked_sector} || $own{$last_attacked_sector}==$coun) {
			$own{$last_attacked_sector} = -1;
		}
		$dump{$last_attacked_sector,"mil"} = $mil+1;
		$dump{$last_attacked_sector,"eff"} = $eff;
		local(@tmp)=localtime();
		$dump{$last_attacked_sector, 'date'}="$tmp[4]/$tmp[3] $tmp[2]:$tmp[1]";
	} elsif (/^\s*defender\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*/) {
		$def{$last_attacked_sector, 'fort'}=$1;
		$def{$last_attacked_sector, 'ship'}=$2;
		$def{$last_attacked_sector, 'land'}=$3;
		$def{$last_attacked_sector, 'plane'}=$4;
	} elsif (/^Final defender strength (\d+)/) {
		$defense_strength{$last_attacked_sector} = $1;
	} elsif (/^\S+\D*\d* #(\d+) occupies (\S+,\S+)\s*/) {
		$unitsect{$1}=$2; 
	} elsif (/^Scouts sight new enemy unit: (\S+\D*\d*) #(\d+)(.*)/) {
		$unitname{$2}=$1;
		$unitown{$2}=$own{$last_attacked_sector};
		$unitnear{$2}=$last_attacked_sector;
		local($unit, $rest)=($2, $3);
		if ($rest=~/efficiency (\d+)[\,\)]/) { $uniteff{$unit}=$1; }
		if ($rest=~/tech (\d+)\)/) { $unittech{$unit}=$1; }
	} elsif (/^Scouts report enemy unit: (\S+\D*\d*) #(\d+)(.*)/) {
		$unitname{$2}=$1;
		$unitown{$2}=$own{$last_attacked_sector};
		$unitsect{$2}=$last_attacked_sector;
		local($unit, $rest)=($2, $3);
		if ($rest=~/efficiency (\d+)[\,\)]/) { $uniteff{$unit}=$1; }
		if ($rest=~/tech (\d+)\)/) { $unittech{$unit}=$1; }
	} elsif (/^\s*\S+\D*\d* #(\d+) dies attacking/) {
		delete $unitname{$1}; delete $unitown{$1}; delete $unitarmy{$1};
		delete $uniteff{$1}; delete $unitfort{$1}; delete $unitmob{$1};
		delete $unitfuel{$1}; delete $unittech{$1}; delete $unitretr{$1};
		delete $unitrad{$1}; delete $unitxpl{$1}; delete $unitnear{$1};
	} elsif (/\s*(.+) #(\d+) retreats at (\d+)% efficiency to (\S+,\S+)!\s*/) {
		$unitname{$2}=$1;
		$uniteff{$2}=$3;
		$unitsect{$2}=$4;
		$unitown{$2}=$coun;
		local($tmp, $min, $hour, $mday, $mon, $tmp, $tmp, $tmp, $tmp)=localtime;
		$unitdate{$2}="$mon/$mday $hour:$min";
	} elsif (/(\d+) of your troops now occupy (\S+,\S+)\s*/) {
		$own{$2}=$main::coun;
		$dump{$2, 'mil'}=$1;
	}
}


sub parse_read {
# should the mines be in a BULLETIN??
	if (/^Kawhomp! Mine detected by (.+) \(#(\d+)\) in (\S+,\S+)!/) {
			$mine{$3} = 20;
	}
	if ($teletype==0) {
		if (/^> BULLETIN.+dated \S+\s+(\S+)\s+(\S+)\s+(\d+):(\d+):.+/) {
			$teletype=1;
			$bullet_month=$main::month{$1};
			$bullet_day=$2;
			$bullet_hour=$3;
			$bullet_min=$4;
		}
	} elsif ($teletype==1) {
		&parse_bulletin;
	}
}

# unchecked
sub parse_bulletin {
	if (/^> /) { $teletype=0; &parse_read; return; }
	elsif (/^(.+) \(#([0-9]+)\) lost ([0-9]+) troops taking (\S+,\S+)/) {
		($mon, $mday, $hour, $min)=($dump{$sect, 'date'}=~/(\d+)\/(\d+) (\d+):(\d+)/);
		if (!($mon) || ($mon<=$bullet_month && $mday<=$bullet_day && $hour<=$bullet_hour && $min<=$bullet_min)) {
			$dump{$2, 'date'}="$bullet_month/$bullet_day $bullet_hour:$bullet_min";
			$country{$2}=$1;
			$number{$1}=$2;
			$own{$4}=$2;
		}
		while($#aunits>-1) {
			$unitown{$aunits[0]}=$2;
			$unitnear{$aunits[0]}=$4;
			shift(@aunits);
		}
	} elsif (/^(.+) \(#(\d+)\) lost (\d+) troops attacking (\S+,\S+)/) {
		while($#aunits>-1) {
			$unitown{$aunits[0]}=$2;
			$unitnear{$aunits[0]}=$4;
			shift(@aunits);
		}
	} elsif (/^Scouts report attacking unit: (.+) #(\d+)(.*)/) {
		local($type, $unit, $rest)=($1, $2, $3);
		($mon, $mday, $hour, $min)=($unitdate{$unit}=~/(\d+)\/(\d+) (\d+):(\d+)/);
		if (!($mon) || ($mon<=$bullet_month && $mday<=$bullet_day && $hour<=$bullet_hour && $min<=$bullet_min)) {
			$type=~s/\s*$//;
			$unitname{$unit}=$type;
			if ($rest=~/efficiency (\d+)[,\)]/) { $uniteff{$unit}=$1; }
			if ($rest=~/tech (\d+)\)/) { $unittech{$unit}=$1; }
			push(@aunits, $unit);
			$unitdate{$2}="$bullet_month/$bullet_day $bullet_hour:$bullet_min";
		}
	} elsif (/\s*(.+) #(\d+) retreats at (\d+)% efficiency to (\S+,\S+)!\s*/) {
		local($type, $unit, $eff, $sect)=($1, $2, $3, $4);
		($mon, $mday, $hour, $min)=($unitdate{$unit}=~/(\d+)\/(\d+) (\d+):(\d+)/);
		if (!($mon) || ($mon<=$bullet_month && $mday<=$bullet_day && $hour<=$bullet_hour && $min<=$bullet_min)) {
			$unitname{$2}=$1;
			$uniteff{$2}=$3;
			$unitsect{$2}=$4;
			$unitown{$2}=$coun;
			$unitdate{$2}="$bullet_month/$bullet_day $bullet_hour:$bullet_min";
		}
	} elsif (/^\s*Diplomatic relations with (.+) downgraded to \"(.+)\"/) {
		$relation{$coun, $1}=$2;
	} elsif (/^\s*.+ \(#(\d+)\) .+ -- shot down/) {
		local($unit)=$1;
		($mon, $mday, $hour, $min)=($planedate{$unit}=~/(\d+)\/(\d+) (\d+):(\d+)/);
		if (!($mon) || ($mon<=$bullet_month && $mday<=$bullet_day && $hour<=$bullet_hour && $min<=$bullet_min)) {
			delete $planename{$unit}; delete $planeeff{$unit}; 
			delete $planesect{$unit}; delete $planewing{$unit}; 
			delete $planemob{$unit}; delete $planetech{$unit};
			delete $planehard{$unit}; delete $planesln{$unit}; 
			delete $planeatt{$unit}; delete $planedef{$unit}; 
			delete $planeran{$unit}; delete $planeown{$unit};
			delete $planenear{$unit}; delete $planedate{$unit};
		}
	} elsif (/firing \d+ flak guns in (\S+,[^.]+)\.+/) {
		$last_flak_sector=$1;
	} elsif (/\s*(.+)\s+\(#\s*(\d+)\)\s+takes \d+/) {
		local(@tmp)=split(/ /, $1); local($unit)=$2;
		local($pilot)=join(' ', shift(@tmp));
		while (!(defined($number{$pilot})) && $#tmp > -1) { $pilot=join(' ', shift(@tmp)); }
		local($type)=join(' ', @tmp); $type=substr($type,0,19);
		($mon, $mday, $hour, $min)=($planedate{$unit}=~/(\d+)\/(\d+) (\d+):(\d+)/);
		if (!($mon) || ($mon<=$bullet_month && $mday<=$bullet_day && $hour<=$bullet_hour && $min<=$bullet_min)) {
			$planeown{$unit}=$number{$pilot};
			$planename{$unit}=$type;
			$planenear{$unit}=$last_flak_sector;
			$planedate{$unit}="$bullet_month/$bullet_day $bullet_hour:$bullet_min";
		}
	} elsif (/^.+ turned (\S+,\S+) into a radioactive wasteland/) {
		$dump{$1, 'own'}=0; $dump{$1, 'des'}='\\'; $own{$1}=0;
		$dump{$1, 'date'}="$bullet_month/$bullet_day $bullet_hour:$bullet_min";
	} elsif (/^\s*(.+) #(\d+) fires at you/) {
		local(@info)=split(/ /, $1); local($unit)=$2;
		local($countryname)=shift(@info);
		while(1) {
			if ($number{$countryname}) { last; }
			else { $countryname=$countryname . " " . shift(@info); }
		}
		$type=join(' ', @info);
		($mon, $mday, $hour, $min)=($shipdate{$unit}=~/(\d+)\/(\d+) (\d+):(\d+)/);
		if (!($mon) || ($mon<=$bullet_month && $mday<=$bullet_day && $hour<=$bullet_hour && $min<=$bullet_min)) {
			if ($shipname{$type}) {
	$shipown{$unit}=$number{$countryname};
	$shipname{$unit}=$type;
	$shipdate{$unit}="$bullet_month/$bullet_day $bullet_hour:$bullet_min";
			}
		}
	}
	elsif (/Bridge falls at (\S+,\S+)\s*/) {
		$own{$1}=0; $dump{$1, "des"}='.';
	}
}

sub parse_explore {
	if (/\s+\S+\s+\S+\s+\S+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*/) {
		$expmin=$1; $expgold=$2; $expfert=$3; $expoil=$4; $expuran=$5;
	} elsif (/<\d+\.\d+:\s*(\S)\s+(\S+,\S+)>/) {
		$dump{$2, 'des'}=$1; $dump{$2, 'min'}=$expmin; $dump{$2, 'gold'}=$expgold;
		$dump{$2, 'fert'}=$expfert; $dump{$2, 'oil'}=$expoil; $dump{$2, 'uran'}=$expuran;
		undef $expmin;
		undef $expgold;
		undef $expfert;
		undef $expoil;
		undef $expuran;
	}
	elsif (/(\d+) mob left in (\S+,\S+)$/) {
		$dump{$2,'mob'} = $1;
	} elsif (/^Sector (\S+,\S+) is now yours.$/) {
		$own{$1} = $coun;
		$oldown{$1} = $coun;
		$dump{$1,'own'} = $coun;
	}
}

$main::parse_loaded = 1;
