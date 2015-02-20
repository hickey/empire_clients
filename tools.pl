#!/usr/local/bin/perl
# $Id: tools.pl,v 2.9.3.1 1997/06/08 20:09:50 root Exp root $
#
#                       Perl Empire Interface Tools
#
#         Written by Drake Diedrich, Ken Stevens, and Sam Tetherow
#
#
# DESCRIPTION:
# This perl module illustrates how user defined perl tools may be integrated
# into pei.  A list of the tools that it contains may be found in the file
# "tools.man".
#
# INSTALLATION:
# You do not need to do anything to install tools.pl.  It will be automatically
# included into pei when you connect to a game.  Just make sure that it
# is in the same directory as pei when pei is run.  Or you can put tools.pl
# in the directory ~/perl and add the following line to your ~/.login file:
#   setenv PERLLIB ~/perl
# 
# Type "help tools" from within pei for the syntax of tool commands,
# or read the file help.tools that comes with pei.
#
# AUTHORS:
# Drake Diedrich and Ken Stevens co-wrote:
#   nova, xmvr, and router.
# Sam Tetherow and Ken Stevens co-wrote:
#   delta, fdelta, tele, anno, mail, and wmail.
# Ken Stevens wrote:
#   setfood, rebel, reach, sreach, lreach, and civs.
# Sam Tetherow wrote:
#   sneweff, pneweff, lneweff, foreach, wdelta, stat, sstat, pstat, and lstat.

# All code updated for wolfpack by Sam Tetherow.  In some places it was major,
# in other minor.  All bugs are surely mine.
#
# BUG REPORTS:
# mail your bug-reports and comments to:
# Sam Tetherow <tetherow@nol.org>

# Working to date: (04/24/97)
# nova
# xmvr
# router
# setfood
# foreach
# rebel
# civs
# lneweff, pneweff, sneweff
# tele, anno, mail, wmail
#
# Untested/Unworking
#
# wdelta, delta, fdelta, 
# reach, sreach, lreach
# stat, sstat, pstat, lstat

#       --- Global variables ---
#
# General tool variables:
# %xdir, %ydir      x,y direction vectors
# @dirstr           The six directions
# $maxpath          Maximum path length used by any of the tools
# @desig            Sector designations
# @commo            Commodities
# %weight           Weights of commodities
# %packing          Warehouse packing factors for commodities
# %commstr          Converts 'f' to 'food', etc...
# %target           Contains list of sectors in <SECTS> argument
#
# xmvr variables:
# %minmob           Minimum mob to be left in sector (by designation)
#
# External variables:
# $main::tools_loaded     Used by pei to determine if we need country number

#       --- Functions ---
#
# Initialization functions:
# xmvr_init       Initialize variables used by xmvr
# comm_init       Initialize commodity variables
# buildcost_init  Initialize variables used by buildcost
# 
# Buildcost functions:
# wrap            If sector co-ords wrap around the world, fix them
# adjacent        Return an array of the six sectors adjacent to arg
# movcost         The mob cost to move into sector arg
# buildcost       Build up path costs for nearby sectors
#
# Nova functions:
# border_sectors  Find unowned '-' sectors on my border
# makepath        Find the cheapest path to an unowned sector
# nova            Explore into adjacent unowned '-' sectors
# tools_supernova Keep calling nova until all '-' are explored
#
# xmvr functions:
# do_move         Move a commodity from one sector to another
# tools_xmvr      Move commodities based on $maxciv, $maxuw, or thresh
#
# Router functions:
# useless         Return a list of sectors in need of redesignation
# tools_router    Dist sectors to the nearest warehouse
#
# Setfood functions:
# tools_setfood   Set food thresholds for maximum civ growth
#
# External functions:
# main::find_country_number   Find my country number
# main'tools_init            Set $country, $coun, $btus, and $timeused
#
# Sam Tetherow's Functions
# tools_landeff        user interface for build_units
# build_units          Actual unit calculations
# tools_planeeff       user interface for build_planes
# build_planes         Actual plane calculations
# tools_shipeff        user interface for build_ships
# build_ships          Actual ship calculations
# max                  return max of 2 numbers
# min                  return min of 2 numbers
# round                standard round
# getline              stub for &main'getline
# tools_foreach        issue a command for an AREA of sectors
# resolve              evaluate variables in foreach command
# resolve              evaluate variables in foreach command
# tools_prod_delta     compute production delta for a country
# tools_food_delta     estimate civ/uw/food production
# tools_warehouse_delta estimate deltas for dist centers
# prod_warn            used in tools_*_delta
# in_realm             return 1 if sect in a realm
# tools_status         show sector info from DB
# tools_lstat          show land info from DB
# tools_pstat          show plane info from DB
# tools_sstat          show ship info from DB
# makerealm            return all sectors in a realm (used in stat)

#       --- Main ---

&buildcost_init;        # initialize buildcost variables
&comm_init;                # initialize commodity variables
&xmvr_init;                # initialize xmvr variables

#       --- Initialization ---

# You may wish to change some of the variables in xmvr_init.
# The variables in this subroutine are used by xmvr.
sub xmvr_init {
	local ($des, $comm);

	# The associative array $minmob{$des} specifies the minimum amount
	# of mobility we want left in a sector after moving stuff out.
	$minmob{'w'} = 60;
	$minmob{'e'} = 80;                # need to move mil out of enlistment centres
	# b,l,t,r,p,) don't need to have much mob...
	$minmob{'b'} = 20;
	$minmob{'l'} = 20;
	$minmob{'t'} = 20;
	$minmob{'r'} = 20;
	$minmob{'p'} = 20;
	$minmob{')'} = 0;
	# Set $minmob to 40 for all other sector types:
	foreach $des (@desig) {
		$minmob{$des} = 40 unless defined($minmob{$des});
	}

	foreach $comm (@commo) {
		$main::functionmap{$comm.'mvr'} = "&tools_xmvr('$comm')";
	}
}

# Initialize commodity variables
sub comm_init {
	# Sector designations
	@desig = ('-', '^', 'c', 'p', '+', ')', '#', '=',
						'd', 'i', 'm', 'g', 'h', 'w', 'u', '*', 'a', 'o', 'j', 'k', '%',
						't', 'f', 'r', 'n', 'l', 'e', '!', 'b');

	# Commodities.
	@commo = ('c', 'm', 'u', 'f',
						's', 'g', 'p', 'i', 'd', 'b', 'o', 'l', 'h', 'r');

	# Commodity weights and warehouse packing factors.
	$weight{'civ'} = 1;    $packing{'civ'} = 4;
	$weight{'mil'} = 1;    $packing{'mil'} = 1;
	$weight{'uw'} = 2;     $packing{'uw'} = 2;
	$weight{'food'} = 1;   $packing{'food'} = 10;
	$weight{'shell'} = 1;  $packing{'shell'} = 10;
	$weight{'gun'} = 10;   $packing{'gun'} = 10;
	$weight{'pet'} = 1;    $packing{'pet'} = 10;
	$weight{'iron'} = 1;   $packing{'iron'} = 10;
	$weight{'dust'} = 5;   $packing{'dust'} = 10;
	$weight{'bar'} = 50;   $packing{'bar'} = 5;
	$weight{'oil'} = 1;    $packing{'oil'} = 10;
	$weight{'lcm'} = 1;    $packing{'lcm'} = 10;
	$weight{'hcm'} = 1;    $packing{'hcm'} = 10;
	$weight{'rad'} = 8;    $packing{'rad'} = 10;
	
	# Commodity strings
	$commstr{'c'} = 'civ';
	$commstr{'m'} = 'mil';
	$commstr{'u'} = 'uw';
	$commstr{'f'} = 'food';
	$commstr{'s'} = 'shell';
	$commstr{'g'} = 'gun';
	$commstr{'p'} = 'pet';
	$commstr{'i'} = 'iron';
	$commstr{'d'} = 'dust';
	$commstr{'b'} = 'bar';
	$commstr{'o'} = 'oil';
	$commstr{'l'} = 'lcm';
	$commstr{'h'} = 'hcm';
	$commstr{'r'} = 'rad';
}

sub buildcost_init {
	# x and y direction vectors.
	$xdir{'j'}=2;         $ydir{'j'}=0;
	$xdir{'u'}=1;         $ydir{'u'}=-1;
	$xdir{'y'}=-1;        $ydir{'y'}=-1;
	$xdir{'g'}=-2;        $ydir{'g'}=0;
	$xdir{'b'}=-1;        $ydir{'b'}=1;
	$xdir{'n'}=1;         $ydir{'n'}=1;
	
	# Directions.
	@dirstr = ( 'j', 'u', 'y', 'g', 'b', 'n' );
	
	# Maximum path lengths (to prevent long loops).  $maxpath MUST be positive.
	$maxpath=999;
}

#       --- Buildcost ---

# The following functions are used by the "buildcost" subroutine which
# calculates pathcosts from a sector to nearby sectors.

# Print a command and then send it to the server.
sub send {
	local ($line) = @_;

	if ($main::terse) {
		print main::UNTERSEOUT '.';
	} else {
		print $line."\n";
	}
	&main::singlecommand($line);
}

# If co-ordinates wrap around the edge of the world, modify the co-ordinates.
sub wrap {
	local ($x,$y) = @_;
	$x -= $world{'width'} if ($x >= $world{'width'}/2);
	$x += $world{'width'} if ($x < -$world{'width'}/2);
	$y -= $world{'height'} if ($y >= $world{'height'}/2);
	$y += $world{'height'} if ($y < -$world{'height'}/2);
	($x,$y);
}

# Returns an array of the six sectors adjacent to the argument $sect.
sub adjacent {
	local ($sect) = pop(@_);
	local (@adjacent,$x,$y,$ax,$ay,$dir);
	
	($x,$y) = split(',', $sect);
	foreach $dir (@dirstr) {
		($ax,$ay) = &wrap($x+$xdir{$dir}, $y+$ydir{$dir});
		push(@adjacent, $ax.','.$ay);
	}
	@adjacent;
}

# Cost to move into a sector.
# Uses $sector{des}{'mcost'} loaded from show sector stats.
sub movcost {
	local($sect) = @_;
	local($des, $c);

	$des = $dump{$sect}{'des'};
	$des = $dump{$sect}{'bdes'} unless $des;
	if ($des eq '\.') { return 1e9; }        # to keep us from moving through the sea
	$c = (100*$sector{$des}{'mcost'} - $dump{$sect}{'eff'})*0.002;
	$c = 1e9 if $c < 0;
	$c = 0.01 if $c < 0.01;
	$c;
}

# buildcost calculates how much mobility it costs to move into a dest sector
# from path-connected sectors.  Each time it is called, the array of
# sectors connected by a path to the dest sector grows to include certain
# adjacent sectors.  It is like an exploding disk, increasing in diameter
# with each call to buildcost.  It explodes along the cheapest path, with
# each expanding ring having the same path cost to the dest sector.
# The costs to move into the dist sector from the path-connected sectors
# is contained in the associative array %cost.  The associative array %marked,
# contains those sectors of %cost which have the cheapest pathcost.
# buildcost returns the number of sectors added to the %cost array.
# If used in an array context, it returns the added sectors.
sub buildcost {
	my($cost, $marked) = @_;
	my(@added, $sect, $c, $newsect, $mincost);
	
	@added=();
	do {
		$mincost = 1e9;
	
		# Find the minimum pathcost to move into unmarked sectors.
		foreach $sect (keys %{$cost}) {
			if ($cost->{$sect} < $mincost && !(defined $marked->{$sect})) {
				$mincost = $cost->{$sect};
			}
		}
		last if $mincost == 1e9;
	
		# For each sector with minimum pathcost.
		while (($sect,$c) = each %{$cost}) {
			next if $c != $mincost;
			$marked->{$sect} = 1;                # mark the sector

			# find pathcost to all owned adjacent sectors not already in %cost
			foreach $newsect (&adjacent($sect)) {
				next if (defined($cost->{$newsect}) || $dump{$newsect}{'own'} != $coun);
				$cost->{$newsect} = $c + &movcost($newsect);
				push (@added, $newsect);
			}
		}
	} while (!@added);
	@added;
}

#       --- Nova ---

# return a list of all unowned wilderness sectors adjacent to my sectors
sub border_sectors {
	local ($asect, $sect, $own);
	local (%border_sectors);
	
	foreach $sect (keys %dump) {
		$own=$dump{$sect}{'own'};
		next if $own!=$coun;
		foreach $asect (&adjacent($sect)) {
			if (!$dump{$asect}{'own'} && $dump{$asect}{'bdes'} eq '-') {
				$border_sectors{$asect}=1;
			}
		}
	}
	keys %border_sectors;
}

# Find the cheapest path from $from to $to.  We cannot use "bestpath" because
# we might not own the destination sector.
sub makepath {
	local($from, $to, $cost) = @_;
	local($newsect,$path,$sect,$dir,$x,$y,$ax,$ay,$found);
	
	return '' unless defined $cost->{$to};

	$sect = $from;
	$path = '';
	while ($sect ne $to) {
		($x,$y) = split(',', $sect);
		$found = 0;
		foreach $dir (@dirstr) {
			($ax,$ay) = &wrap($x+$xdir{$dir}, $y+$ydir{$dir});
			$newsect = $ax . ',' . $ay;
			if (defined($cost->{$newsect}) && $cost->{$newsect} < $cost->{$sect}) {
				$path .= $dir;
				$found = 1;
				last;
			}
		}
		if ($found) {
			$sect = $newsect;
		} else {
			warn "Failed to find path from $from to $to at $sect\n";
			print STDERR %path;
			return '';
		}
	}
	$path;
}

sub nova {
	local ($dest,$sect,$des,$comm,%cost,%marked,@added,$success);
	
	foreach $dest (&border_sectors) {
		last if $main::status;
		undef %cost;
		undef %marked;
		$cost{$dest} = &movcost($dest);
	explore:
		while (@added = &buildcost(\%cost,\%marked)) {
			foreach $sect (@added) {
				last explore if $main::status;
				next if ($dump{$sect}{'mob'} <= 2*$cost{$dest});
				next if ($dump{$sect}{'oldown'} != $coun);
				if ($dump{$sect}{"civ"} > 1) {
					$comm = 'c';
				} elsif ($dump{$sect}{"mil"} > 1) {
					$comm = 'm';
				} else {
					next;
				}
				print "explore $comm $sect 1 ".
					&makepath($sect,$dest,\%cost)."h\n";
				print $main::S "explore $comm $sect 1 ".
					&makepath($sect,$dest,\%cost)."h\n";
				&main::slurp;
				if ($main::mode eq '4') {
					$dump{$dest}{'own'}=-1;
					print "$_\n";
					print $main::S "\n";
					&main::slurp;
				} else {
					$dump{$sect}{$commstr{$comm}}--;
					$dump{$dest}{$commstr{$comm}}++;
					$dump{$dest}{'own'} = $coun;
					$success = 1;
				}
				last explore;
			}
		}
	}
	&send("des * ?des=- +");
	$success;
}

# Keep calling nova until there is no place else to expand to.
# Argument is the realm to explore.
$main::functionmap{'nova'} = '&tools_supernova';
sub tools_supernova {
	local ($realm) = $main::commandarg;
	$realm = '#' unless $realm;
		
	&print_n_parse('dump *');
	&send("map $realm");

	while (&nova && !$main::status) {
		&print_n_parse('dump *');
		&send("map $realm");
	}
}

#       --- xmvr ---

# This function moves a commodity from $from to $to.
sub do_move {
	my ($from, $to, $des, $comm, $pathcost, $rich, $poor) = @_;
	my ($amount, $mobcost, $packing);
	my($cs)=$commstr{$comm};

	if ($des eq 'w' && $dump{$from}{'eff'} >= 60) {
		$packing = $packing{$cs};
	} elsif ($des eq 'b' && $comm eq 'b' && $dump{$from}{'eff'} >= 60) {
		$packing = 4;
	} else {
		$packing = 1;
	}
	$amount = $rich->{$from};
	$amount = $poor->{$to} if ($rich->{$from} > $poor->{$to});
	$mobcost = $weight{$cs} * $pathcost / $packing;
	if ($dump{$from}{'mob'} - $amount * $mobcost < $minmob{$des}) {
		$amount = int(($dump{$from}{'mob'} - $minmob{$des})/$mobcost);
		$rich->{$from} = 0;
	}
	if ($amount > 0) {
		&send("move $comm $from $amount $to");

		$dump{$from}{$cs} -= $amount;
		$rich->{$from} -= $amount;
		$rich->{$from} = 0 if $rich->{$from} < 0;

		$dump{$to}{$cs} += $amount;
		$poor->{$to} -= $amount;
		$poor->{$to} = 0 if $poor->{$to} < 0;
	}
}

# &tools_xmvr($comm) moves commodities from rich sectors to poor sectors.
# If $comm is 'c' or 'u', then $maxciv and $maxuw are used to determine
# the desired number of civs or uw's in each sector.  Otherwise,
# $dump{$sect}{$comm.'_dist'} is used.  xmvr does not reduce the mobility of any
# sector below $minmob{$des}.  It does not move out of or into conquered
# sectors.  It does not move civs or uws out of or into sectors with < 100%
# work.  It never moves into a mountain.  100% efficient sectors with
# Civs and uws are never moved out of a warehouse.
sub tools_xmvr {
	my ($comm) = @_;
	my ($cs) = $commstr{$comm};
	my ($sect, $extra, $des);
	my (%rich, %poor, $total);
	my (%marked, %cost);
	my ($icount, @added);
	my ($from, $to);
	my ($rehash) = 1;
	my ($found_poor, $found_rich);
	my (@poor, @rich);
	my($realm,$switches,$th,$area);

	($realm, $switches, $th) = ($main::commandarg =~
		/^([#*]\d{0,2})\s*(\?\S+)?\s*(\d*)$/);
	
	$area = $realm if $realm;
	$area .= " $switches" if $switches;
	$area = '*' unless $area;
	&build_sect_target($area);
	&print_n_parse("dump *") unless $area eq '*';
	if (!$th) {
			$th = $maxciv if $comm eq 'c';
			$th = $maxuw if $comm eq 'u';
	}

	if ($comm eq 'c' || $comm eq 'u') {
		foreach $sect (keys %dump) {
			next if (!$target{$sect} ||
							 $dump{$sect}{'own'} != $coun ||     # we do not own sector
							 $dump{$sect}{'oldown'} != $coun ||  # we are not oldowner of sector
							 $dump{$sect}{'work'} < 100); # do not move unhappy workers
			next if $dump{$sect}{$cs} == $th;  # has right amount
			$extra = $dump{$sect}{$cs} - $th;
			if ($extra > 0) {
				# Don't move civs or uw's out if not enough mob or if is a warehouse.
				next if ($dump{$sect}{'mob'} <= $minmob{$dump{$sect}{'des'}} ||
								 $dump{$sect}{'des'} eq 'w');
				$rich{$sect} = $extra;
			} elsif ($extra < 0) {
				# Never move into a mountain.
				next if ($dump{$sect}{'des'} eq '^');
				$poor{$sect} = -$extra;
			}
		}
	} else {
		foreach $sect (keys %target) {
			next if ($dump{$sect}{'own'}!=$coun);
			$th = $dump{$sect}{$comm.'_dist'};
			next if (!$target{$sect} ||
							 $dump{$sect}{$cs} == $th ||
							 $dump{$sect}{'own'} != $coun ||
							 ($dump{$sect}{'oldown'} != $coun && $dump{$sect}{$cs} < $th));
			$extra = $dump{$sect}{$cs} - $th;
			if ($extra > 0) {
				# Don't move out if not enough mobility.
				next if ($dump{$sect}{'mob'} <= $minmob{$dump{$sect}{'des'}});
				$rich{$sect} = $extra;
			} elsif ($extra < 0) {
				# Never move into a mountain.
				next if ($dump{$sect}{'des'} eq '^');      
				$poor{$sect} = -$extra;
			}
		}
	}

 xmvrloop:
	while ($rehash && !$main::status) {
		if ($rehash == 2) { # Clean out all the sectors which have done their thing
			foreach $sect (@poor) {
				delete $poor{$sect} unless $poor{$sect};
			}
			foreach $sect (@rich) {
				delete $rich{$sect} unless $rich{$sect};
			}
		}
		@poor = keys %poor;
		@rich = keys %rich;
		$rehash = 0;
		if (!@poor) {
			print "No poor sectors.\n";
		} elsif (!@rich) {
			print "No rich sectors.\n";
		} elsif (@poor >= @rich) {
			print "Poor in $cs.  Looping on rich sectors...\n";
		loop_on_rich:
			foreach $from (@rich) {
				undef %marked;
				undef %cost;
				$cost{$from} = 0;
				$icount = 0;
				$found_poor = 0;
				$des = $dump{$from}{'des'};
				while ($icount++ < $maxpath &&
							 $rich{$from} &&
							 (@added = &buildcost(\%cost, \%marked))) {
					foreach $to (@added) {
						next unless $poor{$to};
						$found_poor = 1;
						last xmvrloop if $main::status;
						&do_move($from, $to, $des, $comm, $cost{$to}, \%rich, \%poor);
					}
				}
				if (!$found_poor) {        # No more poor on this island.
					foreach $sect (keys %cost) {
						delete $rich{$sect};
					}
					$rehash = 2;
					print "\nSkipping island...\n";
					last loop_on_rich;
				}
			}
		} else {
			print "Rich in $cs.  Looping on poor sectors...\n";
		loop_on_poor:
			foreach $to (@poor) {
				undef %marked;
				undef %cost;
				$cost{$to} = 0;
				$icount = 0;
				$found_rich = 0;
				while ($icount++ < $maxpath &&
							 $poor{$to} &&
							 (@added = &buildcost(\%cost, \%marked))) {
					foreach $from (@added) {
						next unless $rich{$from};
						$found_rich = 1;
						last xmvrloop if $main::status;
						&do_move($from, $to, $dump{$from}{'des'}, $comm,
													 $cost{$from}, \%rich, \%poor);
					}
				}
				if (!$found_rich) {        # No more rich on this island
					foreach $sect (keys %cost) {
						delete $poor{$sect};
					}
					$rehash = 2;
					print "\nSkipping island...\n";
					last loop_on_poor;
				}
			}
		}
	}
}

#      --- Router ---

# Return a list of sectors which have des '+', 'g', or 'o', and have less
# than 8 gold and ocon.
sub useless {
	local ($sect,$des,@useless);

	foreach $sect (keys %dump) {
		next if ($dump{$sect}{'own'}!=$coun);
		next if $dump{$sect}{'sdes'} ne '_';
		$des = $dump{$sect}{'des'};
		if ($des eq '+' || $des eq 'g' || $des eq 'o') {
			if ($dump{$sect}{'gold'} < 8 && $dump{$sect}{'ocontent'} < 8) {
				push(@useless,$sect);
			}
		}
	}
	@useless;
}

# Find the nearest warehouse and dist to it.  If a warehouse can not be
# found within 10 sectors, find a useless sector, des it 'w', and dist to it.
$main::functionmap{'router'} = '&tools_router';
sub tools_router {
	local ($dsect,$sect,%cost,%marked,$gotsect,$gotwarehouse,@useless,$dist);
	
	&build_sect_target($main::commandarg);

	@useless=&useless;
 routerloop:
	foreach $sect (keys %dump) {        
		next if ($dump{$sect}{'own'}!=$coun);
		last routerloop if $main::status;
								next if !$target{$sect} ||
								$dump{$sect}{'own'} != $coun ||
								$dump{$sect}{"des"} eq 'w' ||
								$dump{$sect}{"sdes"} eq 'w';
		undef %cost;
		undef %marked;
		$cost{$sect}=0;
		$gotwarehouse = 0;
		$gotsect='';
		$dist=0;
	buildcost:
		while (($dist++)<$maxpath && (@added = &buildcost(\%cost,\%marked))) {
			foreach $dsect (@added) {
				last routerloop if $main::status;
				if ($dump{$dsect}{"des"} eq 'w' ||
						$dump{$dsect}{"sdes"} eq 'w') {
						$gotwarehouse=1;
					if ($dsect ne $dump{$sect}{"dist_x"}.','.$dump{$sect}{"dist_y"}) {
						&send("dist $sect $dsect");
						$gotsect=$dsect;
						last buildcost;
					}
				}
			}
		}
		if (!$gotsect) {                # did not find a warehouse
			if (!$gotwarehouse) {
				# Find the closest useless sector.
				foreach $dsect (@useless) {
					if (defined($cost{$dsect})) {
						if (!($gotsect) ||
								($cost{$dsect} < $cost{$gotsect})) {
							$gotsect=$dsect;
						}
					}
				}
				if ($gotsect) {
					&send("des $gotsect w");
					&send("dist $sect $gotsect");
					$dump{$gotsect}{"sdes"}='w';
					$newdes{$gotsect}='w';
				} else {
					print "Can't find a warehouse for $sect to dist to.\n";
				}
			}
		}
	}
}

#      --- Setfood ---

# This function sets your food thresholds for maximum civ growth.  It will
# never lower any existing food thresholds, and it doesn't set food thresholds
# in warehouses.
$main::functionmap{'setfood'} = '&tools_setfood';
sub tools_setfood {
	local ($sect, $th);
	local ($realm, $switches, $area, $num);
	local ($i, $civ, $uw, $mil);

	if (!$world{'eatrate'}) {
		print "No food is required in this game.\n";
		return;
	}
	if ($main::commandarg =~ /^([#*]\d{0,2}|\d+,\d+)\s*(\?\S+)?\s*(\d*)$/) {
			($realm,$switches,$num) = ($main::commandarg =~
																 /^([#*]\d{0,2}|\d+,\d+)\s*(\?\S+)?\s*(\d*)$/);
	} elsif ($main::commandarg =~ /^\d+$/) {
		$num = $main::commandarg;
	}
	$area = $realm if $realm;
	$area .= " $switches" if $switches;
	$area = '*' unless $area;
	&build_sect_target($area);
	$num = 1 unless $num;
	print "\nSetting food thresholds for $num updates...\n" if $num > 1;

	foreach $sect (keys %dump) {
		next if ($dump{$sect}{'own'}!=$coun);
		last if $main::status;
		next if !$target{$sect} || $dump{$sect}{'des'} eq 'w';        
		$civ = $dump{$sect}{'civ'};
		$uw = $dump{$sect}{'uw'};
		$mil = $dump{$sect}{'mil'};
		for $i (2..$num) {
			$civ += $civ*$world{'obrate'}*$world{'etu'};
			$uw += $uw*$world{'uwbrate'}*$world{'etu'};
		}
		# only capitols grow 1k+ civs
		if ($civ > 999) {         # better than no limit..
			$civ = 999 unless $dump{$sect}{'des'} eq 'c' &&
					defined($option{'BIG_CITY'});
		}
		if ($uw > 999) { $uw = 999; }
		# compute food threshold that will feed the projected number of
		# civs in $num updates, assuming food will be distributed to
		# sector every update (09/03/95 lorphos@empire.net)
		$th = int($num * $world{'etu'} * ($world{'eatrate'} * ($civ + $uw + $mil))
			+ 2 * $world{'babyeat'} * ($civ*$world{'obrate'} + $uw*$world{'uwbrate'}));
		&send("th f $sect $th") if $th > $dump{$sect}{'f_dist'} && $th > 1;
	}
}

#      --- External Functions ---

# Find my country number.

sub main::find_country_number {
	undef $coun;
	&print_n_parse('nation');
	$main::nstatus = $nstatus;
	if ($new_server) {
		print "Cool!  You're using the new server!\n";
	} else {
		&print_n_parse("change c $main::country");
	}
	if (!defined($coun)) {
		print STDERR "You didn't have enough BTU's to get your country number.\n";
		print STDERR "What is your country number? ";
		$coun = <STDIN>;
		chop $coun;
	}
	$main::coun = $coun;
	$number{$main::country} = $coun;
	print "Your country number is $coun.\n";
}

sub main::tools_init {
	&print_n_parse('show sector stats');
	return if $main::status;
	&print_n_parse('show ship build');
	return if $main::status;
	&print_n_parse('show ship capabilities');
	return if $main::status;
	&print_n_parse('show ship stats');
	return if $main::status;
	&print_n_parse('show plane build');
	return if $main::status;
	&print_n_parse('show land build');
	return if $main::status;
	&print_n_parse('show land stats');
	return if $main::status;
	&print_n_parse('version');
	return if $main::status;
	&letter_init;
	$country = $main::country;
	$coun = $main::coun;
	$btus = $main::btus;
	$timeused = $main::timeused;
}

$main::functionmap{'lneweff'} = '&tools_landeff';

sub tools_landeff {
	local(@u, %units, $unit, %newunit, %newsect, %newnat, $xy, $x, $y, $out, $area);

	$area = $main::commandarg;
	$area = '*' unless $area;
 
	undef(%newnat);
	print STDERR "parsing nation...";
	print $main::S "nation\n";
	$main::command="nation";
	while(&getline()) { 1; }
	print STDERR "done\n";
	$newnat{$coun}{'money'}=$nation{$coun}{'money'};

	print STDERR "parsing ldump $area...";
	print $main::S "ldump $area\n";
	$main::command="ldump";
	while(&getline()) {
		next if (split(/\s+/, $_)<39);   # minimun elements in ldump output
		if (/^\s*(\d+)/) {
			($unit)=$1;
			$units{"$land{$unit}{'x'},$land{$unit}{'y'}"}.="$unit ";
		}
	}
	print STDERR "done\n";

	print "\n Unit Type    x,y      Eff  Lcm      Hcm      Gun      Avail         Maint Build\n";
	foreach $xy (keys %units) {
		&build_units($xy);
		@u=split(/ /, $units{$xy});
		($x, $y)=($xy=~/(\S+),(\S+)/);

		while($#u>-1) {
			$unit=shift(@u);
			printf("#%-4d %4s %4d,%-4d %1s%4d%% %3d %4s %3d %4s %3d %4s % 5.1f %-7s \$%4d \$%4d\n",
				$unit, $land{$unit}{'type'}, $x, $y, $newunit{$unit}{'status'},
				$newunit{$unit}{'eff'}, $newunit{$unit}{'lcm'}, $newunit{$unit}{'nlcm'},
				$newunit{$unit}{'hcm'}, $newunit{$unit}{'nhcm'},
				$newunit{$unit}{'guns'}, $newunit{$unit}{'nguns'},
				$newunit{$unit}{'avail'}, $newunit{$unit}{'navail'},
				$newunit{$unit}{'maint'}, $newunit{$unit}{'bcost'});
		}
		printf("total ---- %4d,%-4d        %3d      %3d      %3d      % 5.1f\n",
			$x,$y,
			$newsect{$xy}{'lcm'}<=0 ? 
				$dump{$xy}{'lcm'} : ($dump{$xy}{'lcm'}-$newsect{$xy}{'lcm'}),
			$newsect{$xy}{'hcm'}<=0 ?
				$dump{$xy}{'hcm'} : ($dump{$xy}{'hcm'}-$newsect{$xy}{'hcm'}),
			$newsect{$xy}{'gun'}<=0 ?
				$dump{$xy}{'gun'} : ($dump{$xy}{'gun'}-$newsect{$xy}{'gun'}),
			$newsect{$xy}{'avail'}<=0 ?
				$dump{$xy}{'avail'} : ($dump{$xy}{'avail'}-$newsect{$xy}{'avail'}));
		printf("xtra/(need)%4d,%-4d      %6s   %6s   %6s    %6s\n\n",
			$x,$y,
			$newsect{$xy}{'lcm'}>=0 ?
				"$newsect{$xy}{'lcm'} " : sprintf("(%d)", -$newsect{$xy}{'lcm'}),
			$newsect{$xy}{'hcm'}>=0 ?
				"$newsect{$xy}{'hcm'} " : sprintf("(%d)", -$newsect{$xy}{'hcm'}),
			$newsect{$xy}{'gun'}>=0 ?
				"$newsect{$xy}{'gun'} " : sprintf("(%d)", -$newsect{$xy}{'gun'}),
			sprintf("% 5.1f", $newsect{$xy}{'avail'}));
	}

	foreach $xy (keys %units) {
		if ($dump{$xy}{'off'}==1) { print "Sector $xy is turned off!\n"; }
		$out="Sector $xy needs";
		if ($newsect{$xy}{'lcm'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'lcm'}*-1) , "lcm"); }
		if ($newsect{$xy}{'hcm'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'hcm'}*-1) , "hcm"); }
		if ($newsect{$xy}{'gun'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'gun'}*-1) , "gun"); }
		if (substr($out,length($out)-1,1) cmp "s") { print "$out\n"; }
	}
}

# Need to define $land{'money'} and $land{'min_eff'}
sub build_units {
	local($maint, $avail, $wp_eff, $delta, $left, $leftp, $mneed, $lneed, $hneed, $gneed, $optbuild, $amneed, $alneed, $ahneed, $agneed, $mult, $build, $buildp, $unit, $type);
	local(@units, %mil, %lcm, %hcm, %gun);

	local($xy)=@_;
	local(@units)=split(/ /, $units{$xy});

	print $main::S "dump $xy\n";
	$main::command="dump";
	while(&getline()) { 1; }

	undef(%{$newsect{$xy}});
	$newsect{$xy}{'avail'}=$dump{$xy}{'avail'};
	$newsect{$xy}{'lcm'}=$dump{$xy}{'lcm'}; 
	$newsect{$xy}{'hcm'}=$dump{$xy}{'hcm'};
	$newsect{$xy}{'gun'}=$dump{$xy}{'gun'};


#
# May want to add in a check for going broke and showing decay here
#
	while($#units>-1) {
		$unit=shift(@units);
		$type=$land{$unit}{'type'};
		$mult=1; 
		if ($nation{$coun}{'tech'}<$land{$unit}{'tech'}*0.85) { 
			$mult=2; 
		}
		if ($land{$type}{'engineer'}==1) {
			$mult*=3;
		}
		$land{'money'}=.001;
		$newunit{$unit}{'maint'}=$mult*$world{'etu'}*($land{'money'}*$land{$type}{'cost'});
# Decay due to poor finances
		if ($newnat{$coun}{'money'}-$newunit{$unit}{'maint'}<0) {
			$newunit{$unit}{'eff'}=$land{$unit}{'eff'}-$world{'etu'}/5;
			$newunit{$unit}{'status'}='-';
			$newunit{$unit}{'type'}=$land{$unit}{'type'};
			$newunit{$unit}{'lcm'}=0;
			$newunit{$unit}{'nlcm'}="";
			$newunit{$unit}{'hcm'}=0;
			$newunit{$unit}{'nhcm'}="";
			$newunit{$unit}{'gun'}=0;
			$newunit{$unit}{'ngun'}="";
			$newunit{$unit}{'avail'}=0;
			$newunit{$unit}{'navail'}="";
			$newunit{$unit}{'bcost'}=0;
			if ($newunit{$unit}{'eff'}<$land{'min_eff'}) {
				$newunit{$unit}{'eff'}=0;
				$newunit{$unit}{'status'}="!";
			}
			next;
		}

		if ($dump{$xy}{'off'}==1 || $dump{$xy}{'*'} eq "*") {
			# Sector is stopped or not owned by you
			$newunit{$unit}{'status'}="*";
			$newunit{$unit}{'type'}=$land{$unit}{'type'};
			$newunit{$unit}{'eff'}=$land{$unit}{'eff'};
			$newunit{$unit}{'lcm'}=0;
			$newunit{$unit}{'nlcm'}="";
			$newunit{$unit}{'hcm'}=0;
			$newunit{$unit}{'nhcm'}="";
			$newunit{$unit}{'gun'}=0;
			$newunit{$unit}{'ngun'}="";
			$newunit{$unit}{'avail'}=0;
			$newunit{$unit}{'navail'}="";
			$newunit{$unit}{'bcost'}=0;
			next;
		}
		if ($land{$unit}{'eff'}==100) {
			# Unit is fully efficient
			$newunit{$unit}{'status'}=" ";
			$newunit{$unit}{'eff'}=$land{$unit}{'eff'};
			$newunit{$unit}{'type'}=$land{$unit}{'type'};
			$newunit{$unit}{'lcm'}=0;
			$newunit{$unit}{'nlcm'}="";
			$newunit{$unit}{'hcm'}=0;
			$newunit{$unit}{'nhcm'}="";
			$newunit{$unit}{'gun'}=0;
			$newunit{$unit}{'ngun'}="";
			$newunit{$unit}{'avail'}=0;
			$newunit{$unit}{'navail'}="";
			$newunit{$unit}{'bcost'}=0;
			next;
		}

		$mult=1; 
		if ($nation{$coun}{'tech'}<$land{$unit}{'tech'}*0.85) { 
			$mult=2; 
		}
		$avail=$newsect{$xy}{'avail'}*100;
		$newunit{$unit}{'eff'}=$land{$unit}{'eff'};
		$wp_eff=20+($land{$type}{'lcm'}+2*$land{$type}{'hcm'});
		$delta=$avail/$wp_eff;
		if ($delta>$land{'max_eff'}) { 
			$delta=$land{'max_eff'}; 
		}
		$left=100-$land{$unit}{'eff'};
		$optbuild=&min($left, $land{'max_eff'});
		if ($left>$delta) { $left=$delta; }
		$build=0;
		$leftp=$left/100;
		# Compute what is needed 
		$lneed=&round($land{$type}{'lcm'}*$leftp);
		$hneed=&round($land{$type}{'hcm'}*$leftp);
		$gneed=&round($land{$type}{'guns'}*$leftp);
		$buildp=$leftp;
		# Compute any deficiency
		if ($newsect{$xy}{'lcm'}<$lneed) {
			$buildp=&min($buildp, $newsect{$xy}{'lcm'}/$land{$type}{'lcm'});
		}
		if ($newsect{$xy}{'hcm'}<$hneed) {
			$buildp=&min($buildp, $newsect{$xy}{'hcm'}/$land{$type}{'hcm'});
		}
		if ($land{$type}{'guns'}!=0 && $newsect{$xy}{'gun'}<$gneed) {
			$buildp=&min($buildp, $newsect{$xy}{'gun'}/$land{$type}{'guns'});
		}
		if ($buildp<0.0) { $buildp=0; }
		# Recompute based off what we can use
		$alneed=&round($land{$type}{'lcm'}*$buildp);
		$ahneed=&round($land{$type}{'hcm'}*$buildp);
		$agneed=&round($land{$type}{'guns'}*$buildp);
		$newsect{$xy}{'lcm'}-=$lneed;
		$newsect{$xy}{'hcm'}-=$hneed;
		$newsect{$xy}{'gun'}-=$gneed;
		if ($dump{$xy}{'des'} cmp '!' && $dump{$xy}{'des'} cmp 'f') {
			$buildp/=3; $optbuild/=3;
		}
		$build=$buildp*100;
		$newsect{$xy}{'avail'}=$avail/100-&round($build*$wp_eff/100);
		$newunit{$unit}{'avail'}=&round($build*$wp_eff/100);
		$newunit{$unit}{'eff'}+=$build;
		$newunit{$unit}{'bcost'}=($mult*$land{$type}{'cost'}*$build/100);
		$newunit{$unit}{'lcm'}=$alneed;
		$newunit{$unit}{'hcm'}=$ahneed;
		$newunit{$unit}{'guns'}=$agneed;
		# What could be done in the best case scenario
		if (&round($optbuild*$wp_eff/100)>$newunit{$unit}{'avail'}) {
			$newunit{$unit}{'navail'}=sprintf("(% 5.1f)", $optbuild*$wp_eff/100);
		}
		if ($lneed>$alneed) {
			$newunit{$unit}{'nlcm'}=sprintf("(%d)", $lneed-$alneed);
		}
		if ($hneed>$ahneed) {
			$newunit{$unit}{'nhcm'}=sprintf("(%d)", $hneed-$ahneed);
		}
		if ($gneed>$agneed) {
			$newunit{$unit}{'nguns'}=sprintf("(%d)", $gneed-$agneed);
		}
	}
}
 
$main::functionmap{'pneweff'} = '&tools_planeeff';

sub tools_planeeff {
 
local(@p, %planes, %newplane, %newsect, %newship, %newnat, $plane, $x, $y, $xy, $out, $area);

	$area = $main::commandarg;
	$area = "*" unless $area;

	undef(%newnat);
	print STDERR "parseing nation...";
	print $main::S "nation\n";
	$main::command="nation";
	while(&getline()) { 1; }
	print STDERR "done\n";
	$newnat{$coun}{'money'}=$nation{$coun}{'money'};

	print STDERR "parsing pdump $area...";
	$main::command="pdump";
	print $main::S "pdump $area\n";
	while(&getline()) {
		if (/^\s*(\d+)/) {
			next if (split(/\s+/, $_)<22);   # minimun elements in pdump output
			($plane)=/^\s*(\d+)\s+/;
			$planes{"$plane{$plane}{'x'},$plane{$plane}{'y'}"}.="$plane ";
		}
	}
	print STDERR "done\n";
	print "\nPlane Type    x,y      Eff  Mil      Lcm      Hcm      Avail         Maint Build\n";
	foreach $xy (keys %planes) {
		&build_planes($xy);
		($x, $y)=($xy=~/(\S+),(\S+)/);
		@p=split(/ /, $planes{$xy});
		while($#p>-1) {
			$plane=shift(@p);
			printf("#%-4d %4s %4d,%-4d %1s %3d%% %3d %4s %3d %4s %3d %4s % 5.1f %-7s \$%4d \$%4d\n", 
				$plane, $plane{$plane}{'type'}, $x, $y, $newplane{$plane}{'status'},
				$newplane{$plane}{'eff'}, $newplane{$plane}{'crew'},
				$newplane{$plane}{'ncrew'}, $newplane{$plane}{'lcm'},
				$newplane{$plane}{'nlcm'}, $newplane{$plane}{'hcm'},
				$newplane{$plane}{'nhcm'}, $newplane{$plane}{'avail'},
				$newplane{$plane}{'navail'}, $newplane{$plane}{'maint'},
				$newplane{$plane}{'build'});
		}
		printf("total ---- %4d,%-4d        %3d      %3d      %3d      % 5.1f\n",
		$x,$y,
		$newsect{$xy}{'mil'}<=0 ?
			$dump{$xy}{'mil'} : ($dump{$xy}{'mil'} - $newsect{$xy}{'mil'}),
		$newsect{$xy}{'lcm'}<=0 ?
			$dump{$xy}{'lcm'} : ($dump{$xy}{'lcm'} - $newsect{$xy}{'lcm'}),
		$newsect{$xy}{'hcm'}<=0 ?
			$dump{$xy}{'hcm'} : ($dump{$xy}{'hcm'} - $newsect{$xy}{'hcm'}),
		$newsect{$xy}{'avail'}<=0 ?
			$dump{$xy}{'avail'} : ($dump{$xy}{'avail'} - $newsect{$xy}{'avail'}));

		printf("xtra/(need)%4d,%-4d      %6s   %6s   %6s   %7s\n",
		$x,$y,
		$newsect{$xy}{'mil'}>=0 ?
			"$newsect{$xy}{'mil'} " : sprintf("(%d)", -$newsect{$xy}{'mil'}),
		$newsect{$xy}{'lcm'}>=0 ?
			"$newsect{$xy}{'lcm'} " : sprintf("(%d)", -$newsect{$xy}{'lcm'}),
		$newsect{$xy}{'hcm'}>=0 ?
			"$newsect{$xy}{'hcm'} " : sprintf("(%d)", -$newsect{$xy}{'hcm'}),
		sprintf("% 5.1f", $newsect{$xy}{'avail'}));
	}
	foreach $xy (keys %planes) {
		$out="Sector $xy needs";
		if ($newsect{$xy}{'mil'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'mil'}*-1) , "mil"); }
		if ($newsect{$xy}{'lcm'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'lcm'}*-1) , "lcm"); }
		if ($newsect{$xy}{'hcm'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'hcm'}*-1) , "hcm"); }
		if (substr($out,length($out)-1,1) cmp "s") { print "$out\n"; }
	}
}

sub build_planes {
	local($maint, $avail, $wp_eff, $delta, $left, $leftp, $mneed, $lneed, $hneed, $amneed, $alneed, $ahneed, $optbuild, $mult);
	local(@plane, %mil, %lcm, %hcm, %eff);

	local($xy)=@_;
	local(@plane)=split(/ /, $planes{$xy});

	print $main::S "dump $xy\n";
	$main::command="dump";
	while(&getline()) { 1; }

	if ($dump{$xy}{'own'}==$coun) {
		$newsect{$xy}{'avail'}=$dump{$xy}{'avail'};
		$newsect{$xy}{'mil'}=$dump{$xy}{'mil'};
		$newsect{$xy}{'lcm'}=$dump{$xy}{'lcm'};
		$newsect{$xy}{'hcm'}=$dump{$xy}{'hcm'};
		$newsect{$xy}{'own'}=$dump{$xy}{'own'};
	}

	while($#plane>-1) {
		($plane)=shift(@plane);
		$type=$plane{$plane}{'type'};
		$ship=$plane{$plane}{'ship'};
		$newplane{$plane}{'eff'}=$plane{$plane}{'eff'};
		if ($ship>-1) {
			if ($plane{$plane}{'eff'}>=80) {
				$newplane{$plane}{'status'}=' ';
				$newplane{$plane}{'eff'}=$plane{$plane}{'eff'};
				$newplane{$plane}{'crew'}=0;
				$newplane{$plane}{'ncrew'}="";
				$newplane{$plane}{'lcm'}=0;
				$newplane{$plane}{'nlcm'}="";
				$newplane{$plane}{'hcm'}=0;
				$newplane{$plane}{'nhcm'}="";
				$newplane{$plane}{'avail'}=0;
				next;
			}
			if (%{$newship{$ship}}) {
				print $main::S "sdump $ship\n";
				$main::command="sdump";
				while(&getline()) { 1; }
				$newship{$ship}{'lcm'}=$ship{$ship}{'lcm'};
				$newship{$ship}{'hcm'}=$ship{$ship}{'hcm'};
				$newship{$ship}{'mil'}=$ship{$ship}{'mil'};
				$newship{$ship}{'avail'}=$world{'etu'}*$ship{$ship}{'mil'}/2;
			}
		}

		$mult=1;
		if ($nation{$coun}{'tech'}<$plane{$plane}{'tech'}*0.85) { 
			$mult=2; 
		}
		$plane{'money'}=.001;
		$newplane{$plane}{'maint'}=$mult*$world{'etu'}*$plane{'money'}*$plane{$type}{'cost'};
		if ($newnat{$coun}{'money'}-$maint<0) {
			$newplane{$plane}{'eff'}=$plane{$plane}{'eff'};
			$newplane{$plane}{'eff'}-=($world{'etu'}/5);
			if ($newplane{$plane}{'eff'}<$plane{'min_eff'}) {
				$newplane{$plane}{'status'}='!';
			} else {
				$newplane{$plane}{'status'}='-';
			}
			$newplane{$plane}{'crew'}=0;
			$newplane{$plane}{'ncrew'}=0;
			$newplane{$plane}{'lcm'}=0;
			$newplane{$plane}{'nlcm'}=0;
			$newplane{$plane}{'hcm'}=0;
			$newplane{$plane}{'nhcm'}=0;
			$newplane{$plane}{'avail'}=0;
			next;
		}
		$newplane{$plane}{'maint'}+=($world{'etu'}*$plane{$type}{'crew'}*$world{'milcost'}*5);
		$newnat{$coun}{'money'}-=$newplane{$plane}{'maint'};
	
		if ($dump{$xy}{'*'}==1) {
			$newplane{$plane}{'status'}='*';
			$newplane{$plane}{'eff'}=$plane{$plane}{'eff'};
			$newplane{$plane}{'crew'}=0;
			$newplane{$plane}{'ncrew'}="";
			$newplane{$plane}{'lcm'}=0;
			$newplane{$plane}{'nlcm'}="";
			$newplane{$plane}{'hcm'}=0;
			$newplane{$plane}{'nhcm'}="";
			$newplane{$plane}{'avail'}=0;
			next;
		}

		$left=100-$plane{$plane}{'eff'};
		if ($left<=0) {
			$newplane{$plane}{'status'}=' ';
			$newplane{$plane}{'eff'}=$plane{$plane}{'eff'};
			$newplane{$plane}{'crew'}=0;
			$newplane{$plane}{'ncrew'}="";
			$newplane{$plane}{'lcm'}=0;
			$newplane{$plane}{'nlcm'}="";
			$newplane{$plane}{'hcm'}=0;
			$newplane{$plane}{'nhcm'}="";
			$newplane{$plane}{'avail'}=0;
			next;
		}
		$avail=$newsect{$xy}{'avail'}*100;
		if ($ship>-1) {
			$avail+=($world{'etu'}*$ship{$ship}{'mil'}/2);
		}
		$wp_eff=20+$plane{$type}{'lcm'}+2*$plane{$type}{'hcm'};
		$delta=$avail/$wp_eff;
		if ($delta<=0) {
			$newplane{$plane}{'status'}=' ';
			$newplane{$plane}{'eff'}=$plane{$plane}{'eff'};
			$newplane{$plane}{'crew'}=0;
			$newplane{$plane}{'ncrew'}="";
			$newplane{$plane}{'lcm'}=0;
			$newplane{$plane}{'nlcm'}="";
			$newplane{$plane}{'hcm'}=0;
			$newplane{$plane}{'nhcm'}="";
			$newplane{$plane}{'avail'}=0;
			next;
		}
		if ($delta>$plane{'max_eff'}) { 
			$delta=$plane{'max_eff'};
		}
		$optbuild=&min($left, $world{'max_eff'});
		if ($delta>$left) { 
			$delta=$left; 
		}
		if ($left>$delta) {
			$left=$delta;
		}
		$leftp=$left/100;
		$mneed=&round($plane{$type}{'crew'}*$leftp);
		$lneed=&round($plane{$type}{'lcm'}*$leftp);
		$hneed=&round($plane{$type}{'hcm'}*$leftp);

		# Set the actual available resources here
		$mil=0; $lcm=0; $hcm=0;
		if ($newsect{$xy}{'own'}==$coun) {
			$mil+=$newsect{$xy}{'mil'};
			$lcm+=$newsect{$xy}{'lcm'};
			$hcm+=$newsect{$xy}{'hcm'};
		}
		if ($ship>-1) {
			$mil+=$newship{$ship}{'mil'};
			$lcm+=$newship{$ship}{'lcm'};
			$hcm+=$newship{$ship}{'hcm'};
		}
		if ($ship>-1 && $newsect{$xy}{'own'}!=$coun) {
			$mil=9999; $lcm=9999; $hcm=9999;
		}
		if ($mil>=$mneed) { 
			$buildp=$leftp;
		} else {
			$buildp=$mil/$plane{$type}{'crew'};
		}
		if ($lcm<=$lneed) {
			$buildp=&min($buildp, $lcm/$plane{$type}{'lcm'});
		}
		if ($hcm<=$hneed) {
			$buildp=&min($buildp, $hcm/$plane{$type}{'hcm'});
		}
		if ($buildp<0.0) { $buildp=0; }
		$build=$buildp*100;
		$amneed=&round($plane{$type}{'crew'}*$buildp);
		$alneed=&round($plane{$type}{'lcm'}*$buildp);
		$ahneed=&round($plane{$type}{'hcm'}*$buildp);
# Need to handle ship resources here
		if ($ship>-1) {
			if ($newsect{$xy}{$own}==$coun) {
				$newsect{$xy}{'mil'}-=$mneed;
				if ($newsect{$xy}{'mil'}<0 && $newship{$ship}{'mil'}>0) {
					$newsect{$xy}{'mil'}+=$newship{$ship}{'mil'};
					$newship{$ship}{'mil'}=0;
					if ($newsect{$xy}{'mil'}>0) {
						$newship{$ship}{'mil'}=$newsect{$xy}{'mil'};
						$newsect{$xy}{'mil'}=0;
					}
				}
				$newsect{$xy}{'lcm'}-=$lneed;
				if ($newsect{$xy}{'lcm'}<0 && $newship{$ship}{'lcm'}>0) {
					$newsect{$xy}{'lcm'}+=$newship{$ship}{'lcm'};
					$newship{$ship}{'lcm'}=0;
					if ($newsect{$xy}{'lcm'}>0) {
						$newship{$ship}{'lcm'}=$newsect{$xy}{'lcm'};
						$newsect{$xy}{'lcm'}=0;
					}
				}
				$newsect{$xy}{'hcm'}-=$hneed;
				if ($newsect{$xy}{'hcm'}<0 && $newship{$ship}{'hcm'}>0) {
					$newsect{$xy}{'hcm'}+=$newship{$ship}{'hcm'};
					$newship{$ship}{'hcm'}=0;
					if ($newsect{$xy}{'hcm'}>0) {
						$newship{$ship}{'hcm'}=$newsect{$xy}{'hcm'};
						$newsect{$xy}{'hcm'}=0;
					}
				}
			} else {
				$newship{$ship}{'mil'}-=$mneed;
				$newship{$ship}{'lcm'}-=$lneed;
				$newship{$ship}{'hcm'}-=$hneed;
			}
		} else {
			$newsect{$xy}{'mil'}-=$mneed;
			$newsect{$xy}{'lcm'}-=$lneed;
			$newsect{$xy}{'hcm'}-=$hneed;
		}

		$build=$buildp*100;

		if ($ship>-1) {
			$build=$delta;
		}
		$used=$build*$wp_eff;
		$avail=($newsect{$xy}{'avail'}*100-$used)/100;
		if ($avail<0) {
			$avail=0;
		}
		$newsect{$xy}{'avail'}=$avail;
		# If we are on a ship we'll used the avail from the sector first.
		if ($ship>-1) {
			if ($newsect{$xy}{'avail'}<0 && $newship{$ship}{'avail'}>0) {
				$newship{$ship}{'avail'}+=$newsect{$xy}{'avail'};
				$newsect{$xy}{'avail'}=0;
			}
		}
		if ($dump{$xy}{'des'} ne '*') {
			$build/=3;
		}
		if ($ship>-1) {
			if (($newplane{$plane}{'eff'}+$build)>80) {
				$build=80-$newplane{$plane}{'eff'};
			}
		}
		$newplane{$plane}{'build'}=($mult*$build*$plane{$type}{'cost'}/100);
		$newnat{$count}{'money'}-=$newplane{$plane}{'build'};
		$newplane{$plane}{'eff'}+=$build;
		$newplane{$plane}{'status'}=' ';
		$newplane{$plane}{'crew'}=$amneed;
		if ($mneed!=$amneed) {
			$newplane{$plane}{'ncrew'}=sprintf("(%d)", $mneed);
		} else {
			$newplane{$plane}{'ncrew'}=" ";
		}
		$newplane{$plane}{'lcm'}=$alneed;
		if ($lneed!=$alneed) {
			$newplane{$plane}{'nlcm'}=sprintf("(%d)", $lneed);
		} else {
			$newplane{$plane}{'nlcm'}=" ";
		}
		$newplane{$plane}{'hcm'}=$ahneed;
		if ($hneed!=$ahneed) {
			$newplane{$plane}{'nhcm'}=sprintf("(%d)", $hneed);
		} else {
			$newplane{$plane}{'nhcm'}=" ";
		}
		$newplane{$plane}{'avail'}=$used/100;
	}
}
$main::functionmap{'sneweff'}='&tools_shipeff';

sub tools_shipeff {
 
	local(@s, %ships, %mil, %lcm, %hcm, %shipuse, %shipneed, %crewneed, %unit, %avail, $x, $y, $out, $area);

	$area = $main::commandarg;
	$area = '*' unless $area;

	print STDERR "parsing ship $area...";
	print $main::S "sdump $area\n";
	$main::command="sdump";
	while(&getline()) {
		next if (split(/\s+/, $_)<34);		# minimum elemetns in sdump output
		if (/^\s*(\d+)/) {
			($ship)=$1;
			$ships{"$ship{$ship}{'x'},$ship{$ship}{'y'}"}.="$ship ";
		}
	}
	print STDERR "done\n";
	print " Ship Type    x,y      Eff   Crew Lcm       Hcm       Avail         Maint Build\n";
	foreach $xy (keys %ships) {
		&build_ships($xy);
		($x, $y)=($xy=~/(\S+),(\S+)/);
		@s=split(/ /, $ships{$xy});

		while($#s>-1) {
			$ship=shift(@s);
			printf("#%-4d %4s %4d,%-4d %s %3d%% %5s %3d %5s %3d %5s %5.1f %7s \$%4d \$%4d\n", 
				$ship, $ship{$ship}{'type'}, $x, $y, $newship{$ship}{'status'},
				$newship{$ship}{'eff'}, $newship{$ship}{'nmil'}, 
				$newship{$ship}{'lcm'}, $newship{$ship}{'nlcm'},
				$newship{$ship}{'hcm'}, $newship{$ship}{'nhcm'},
				$newship{$ship}{'avail'}, $newship{$ship}{'navail'},
				$newship{$ship}{'maint'}, $newship{$ship}{'build'});
		}
		printf("total ---- %4d,%-4d              %3d       %3d      % 5.1f\n",
			$x,$y,
			$newsect{$xy}{'lcm'}<=0 ?
				$dump{$xy}{'lcm'} : ($dump{$xy}{'lcm'}-$newsect{$xy}{'lcm'}),
			$newsect{$xy}{'hcm'}<=0 ?
				$dump{$xy}{'hcm'} : ($dump{$xy}{'hcm'}-$newsect{$xy}{'hcm'}),
			$newsect{$xy}{'avail'}<=0 ?
				$dump{$xy}{'avail'} : ($dump{$xy}{'avail'}-$newsect{$xy}{'avail'}));
		printf("xtra/(need)%4d,%-4d            %6s    %6s     %6s\n\n",
			$x,$y,
			$newsect{$xy}{'lcm'}>=0 ?
				"$newsect{$xy}{'lcm'} " : sprintf("(%d)", -$newsect{$xy}{'lcm'}),
			$newsect{$xy}{'hcm'}>=0 ?
				"$newsect{$xy}{'hcm'} " : sprintf("(%d)", -$newsect{$xy}{'hcm'}),
			sprintf("% 5.1f", $newsect{$xy}{'avail'}));
	}

	foreach $xy (keys %ships) {
		if ($dump{$xy}{'off'}==1) { print "Sector $xy is turned off!\n"; }
		$out="Sector $xy needs";
		if ($newsect{$xy}{'lcm'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'lcm'}*-1) , "lcm"); }
		if ($newsect{$xy}{'hcm'}<0) { $out=join(' ', $out, sprintf("%.0f", $newsect{$xy}{'hcm'}*-1) , "hcm"); }
		if (substr($out,length($out)-1,1) cmp "s") { print "$out\n"; }
	}
}

sub build_ships {

	local($maint, $avail, $wp_eff, $delta, $left, $leftp, $lneed, $hneed, $alneed, $ahneed, $optbuild, $mult);
	local(@ships, %lcm, %hcm, %eff);
	local($xy)=@_;
	local(@ships)=split(/ /, $ships{$xy});

	print $main::S "dump $xy\n";
	$main::command="dump";
	while(&getline()) { 1; }

	undef(%{$newsect{$xy}});
	$newsect{$xy}{'avail'}=$dump{$xy}{'avail'};
	$newsect{$xy}{'lcm'}=$dump{$xy}{'lcm'};
	$newsect{$xy}{'hcm'}=$dump{$xy}{'hcm'};

	while($#ships>-1) {
		$ship=shift(@ships);
		$type=$ship{$ship}{'type'};
		$newship{$ship}{'eff'}=$ship{$ship}{'eff'};
		$newship{$ship}{'lcm'}=$ship{$ship}{'lcm'};
		$newship{$ship}{'nlcm'}="";
		$newship{$ship}{'hcm'}=$ship{$ship}{'hcm'};
		$newship{$ship}{'nhcm'}="";
		$newship{$ship}{'status'}=" ";
		$newship{$ship}{'avail'}="0.0";
		$newship{$ship}{'navail'}=" ";
		$newship{$ship}{'build'}=" ";

		$wf=0;
		if ($ship{$type}{'glim'}>0) {
			$wf=$world{'etu'}*$ship{$ship}{'mil'}/2;
		} else {
			$wf=$world{'etu'}*($ship{$ship}{'civ'}/2+$ship{$ship}{'mil'}/5);
		}
		if ($dump{$xy}{'des'} ne 'h') {
			$wf/=3;
			$avail=$wf;
		} else {
			$avail=$wf+$newsect{$xy}{'avail'}*100;
		}

		$wp_eff=20+$ship{$type}{'lcm'}+2*$ship{$type}{'hcm'};
		if ($dump{$xy}{'des'} ne 'h') {
			if ($ship{$type}{'glim'}>0) {
				$abs_max=$ship{$type}{'mlim'};
				$amt=$ship{$ship}{'mil'};
			} else {
				$abs_max=$ship{$type}{'clim'};
				$amt=$ship{$ship}{'civ'};
				if ($abs_max==0) {
					$abs_max=$ship{$type}{'mlim'};
					$amt=$ship{$ship}{'mil'};
				}
			}
			$avail-=($world{'etu'}*(100-(($amt*100)/$abs_max))/7);
		}

		if ($avail<=0) {
			if ($world{'option'}{'SHIP_DECAY'}==1) {
				$newship{$ship}{'eff'}+=($avail/$wp_eff);
				$newship{$ship}{'status'}='!';
			} else {
				$newship{$ship}{'status'}='*';
			}
####
#		if ($avail<=0 && $dump{$xy}{"des"} cmp "h") {
#			$neweff{$ship}=$eff{$ship}+$avail/$wp_eff;
#			if (&is_military_ship($type)) {
#				$crewneed{$ship}=&round(100/((7/6)+(100/$cargo{$type, "mil"})))-$shipcargo{$ship, 'mil'};
#			} else {
#				$crewneed{$ship}=&round((100-(7*$shipcargo{$ship, "mil"}/5))/((7/6)+(100/$cargo{$type, "civ"})))-$shipcargo{$ship, "civ"};
#			}
#			$crewneed{$ship}="($crewneed{$ship})";
#
			next;
		} else {
			$newship{$ship}{'ncrew'}=" ";
		}

		if ($dump{$xy}{'off'}==1) {
			$newship{$ship}{'status'}='*';
			next;
		}

		$ship{'money'}=.001;
		$mult=1;
		if ($nation{$coun}{'tech'}<$ship{$ship}{'tech'}*0.85) { $mult=2; }
		$newship{$ship}{'maint'}=$mult*$world{'etu'}*$ship{'money'}*$ship{$type}{'cost'};

		if ($newship{$ship}{'eff'}==100) {
			next;
		}

		$left=100-$newship{$ship}{'eff'};
		$delta=&round($avail/$wp_eff);
		if ($delta<=0) {
			$newship{$ship}{'status'}='*';
			next;
		}
		if ($delta>$ship{'max_eff'}) {
			$delta=$ship{'max_eff'};
		}
		if ($delta>$left) {
			$delta=$left;
		}

		$left=100-$newship{$ship}{'eff'};
		if ($left>$delta) {
			$left=$delta;
		}

		$leftp=$left/100;
		if ($dump{$xy}{'own'}==$coun) {
			$lneed=&round($ship{$type}{'lcm'}*$leftp);
			$hneed=&round($ship{$type}{'hcm'}*$leftp);
			if ($newsect{$xy}{'lcm'}>=$lneed) {
				$buildp=$leftp;
			} else {
				$buildp=$newsect{$xy}{'lcm'}/$ship{$type}{'lcm'};
			}
			if ($newsect{$xy}{'hcm'}<$hneed) {
				$buildp=min($buildp, $newsect{$xy}{'hcm'}/$ship{$type}{'hcm'});
			}
			$newship{$ship}{'lcm'}=$ship{$type}{'lcm'}*$buildp;
			$newship{$ship}{'hcm'}=$ship{$type}{'hcm'}*$buildp;
			if ($buildp!=$leftp) {
				$newship{$ship}{'nlcm'}=sprintf("(%d)", $lneed-$newship{$ship}{'lcm'});
				$newship{$ship}{'nhcm'}=sprintf("(%d)", $hneed-$newship{$ship}{'hcm'});
			}
		}
		$build=$buildp*100;
		if ($dump{$xy}{'own'} != $coun) {
			$build=$delta;
		}
		$wf-=$build*$wp_eff;
		if ($wf<0) {
			$avail=($newsect{$xy}{'avail'}*100+$wf)/100;
			if ($avail<0) {
				$avail=0;
			}
			$newsect{$xy}{'avail'}=$avail;
		}
		if ($dump{$xy}{'des'} ne 'h') {
			if ($build+$newship{$ship}{'eff'}>80) {
				$build=80-$newship{$ship}{'eff'};
				if ($build<0) {
					$build=0;
				}
			}
		}
		$newship{$ship}{'avail'}=$build*$wp_eff/100;
		$newship{$ship}{'build'}=$mult*$ship{$type}{'cost'}*$build/100;
		$newship{$ship}{'eff'}+=$build;
	}
}

sub max {
	local($x, $y)=@_;
	if ($x>$y) { return $x; }
	else { return $y; }
}
 
sub min {
	local($x, $y)=@_;
	if ($x<$y) { return $x; }
	else { return $y; }
}

sub round {
	local($val)=@_;
	local($int)=sprintf("%.0f", $val);
	if ($val>$int) { 
		return $int+1; 
	}
	else { 
		return $int; 
	}
}

sub getline {
	$mode = -1;
	$_ = &sock::S_read($main::S, $main::TIMEOUT); 
	return 0 if $main::status;

	($mode, $_)=/^\s*(\S+) (.+)*$/;
	if(defined($main::parsemap{$main::command})) {
		eval('&'.$main::game."'".$main::parsemap{$main::command});
	}
	if ($mode eq $main::C_FLUSH ||
			$mode eq $main::C_PROMPT) {
		$main::mode = $mode;
		return 0;
	}
	if ($mode ne $main::C_DATA) {
		$main::mode = $main::C_DATA;
		$_ = "$mode $_";
		&main::parse_serverline;
	}
	return 1;
}

# foreach command
# with replacement of $sect $mil $civ $uw $food $shell $gun $petrol $iron 
# $dust $bar $oil $lcm $hcm $rad
#
# Syntax: foreach AREA cmd
#
# Written by Sam "Drazz'zt" Tetherow

$main::functionmap{'foreach'}='&tools_foreach()';

sub tools_foreach {
	local(@data);
	local($sect, $civ, $mil, $uw, $food, $shell, $gun, $petrol, $iron, $dust, $bar, $oil, $lcm, $hcm, $rad, $tmp);

	local(@arguments)=split(/ /, $main::commandarg);
	local($AREA)=shift(@arguments);
	if (substr($arguments[0],0,1) eq '?') {
		$AREA="$AREA " . shift(@arguments);
	}
	local($command)=join(' ', @arguments);
	$command='"' . $command . '"';
	$main::command="dump";
	print $main::S "dump $AREA\n";
	while (&getline()) {
		if (/\./) {
			(@data)=split(/ /, $_);
			$sect=$data[0] . "," . $data[1]; $civ=$data[16]; $mil=$data[17]; 
			$uw=$data[18]; $food=$data[19]; $shell=$data[20]; $gun=$data[21];
			$petrol=$data[22]; $iron=$data[23]; $dust=$data[24]; $bar=$data[25]; 
			$oil=$data[26]; $lcm=$data[27]; $hcm=$data[28]; $rad=$data[29];
			push(@stack,&resolve(eval($command)) . "\n"); 
		}
	}
	while(@stack) { &main::parse_line(shift(@stack)); last if $main::status;}
}

sub resolve {
	local($this)=@_;

	local($x);
	local(@stack)=split(/ /, $this);
	for($x=0; $x<=$#stack; $x++) {
		if ($stack[$x] =~ /\,/) { next; }
		if ($stack[$x] =~ /^[1234567890\-\+\/\*]+/) { $stack[$x]=eval($stack[$x]); }
	}
	return join(' ', @stack);
}

$main::functionmap{'reach'}='&tools_reach';
sub tools_reach {
	local ($reach);
	print "\n--------------Sector Reach Report--------------\n";
	$reach = int(0.07*$techfactor*$firerangefactor) + 1;
	printf "Fire range of a 100%% fort:       %2.2f (%d at tech %s)\n",
		0.07*$techfactor*$firerangefactor + 1, $reach + 1, &reach_to_t($reach, 7);
	$reach = int(0.16*$techfactor);
	printf "Radar range general:             %3d  (%d at tech %s)\n", 
		$reach, $reach + 1, &reach_to_t($reach + 1, 16);
	$reach = int(0.08*$techfactor);
	printf "Radar range specifics:           %3d  (%d at tech %s)\n",
		$reach, $reach + 1, &reach_to_t($reach + 1, 8);
	$reach = int(0.04*$techfactor);
	printf "Coastwatch range from non-radar: %3d  (%d at tech %s)\n", 
		$reach, $reach + 1, &reach_to_t($reach + 1, 4);
	$reach = int(0.14*$techfactor);
	printf "Coastwatch range from radar:     %3d  (%d at tech %s)\n", 
		$reach, $reach + 1, &reach_to_t($reach + 1, 14);
}

sub reach_to_t {
	local ($r, $k) = (@_);
	if ($r < $k) {
		sprintf("%3.2f",(200*$r - 50*$k)/($k - $r));
	} else {
		"infinity";
	}
}

$main::functionmap{'sreach'}='&tools_sreach';
sub tools_sreach {
	local ($id, $mobcost, $tfactor, $newmob, $frange,);

	&build_ships_target($main::commandarg);
	print "\n        --------------Ship Reach Report--------------\n";
	print "                                       Fire   Movement   Movement\n";
	print "Ship  Type  Fleet    x,y    Eff  Tech  range    now      next upd\n";
	foreach $id (keys %target) {
		if ($target{$id}) {
			$type=$ship{$id}{'type'};
			$tfactor = (50 + $ship{$id}{'tech'})/(200 + $ship{$id}{'tech'});
			$mobcost = 48000/(($ship{$type}{'spd'} + $ship{$type}{'spd'}*$tfactor)*$ship{$id}{'eff'});
			$newmob = $ship{$id}{'mob'} + $ship{'max_mob'};
			$newmob = 127 if $newmob > 127;
			$frange = $ship{$id}{'eff'}>59?($world{'firerangefactor'}*$ship{$type}{'rng'}*$tfactor/2):0;
			if ($frange) {
				$frange = sprintf("%3.2f", $frange);
			} else {
				$frange = "";
			}
			printf "%4d  %4s    %1s   %4d,%-4d %3d%%  %3d %6s   %3d         %3d\n",
			$id,$type,$ship{$id}{'flt'},$ship{$id}{'x'},$ship{$id}{'y'},$ship{$id}{'eff'},$ship{$id}{'tech'},
			$frange,
			$ship{$id}{'mob'}>0?int($ship{$id}{'mob'}/$mobcost+0.999):0,
			int($newmob/$mobcost+0.999);
		}
	}
}

$main::functionmap{'lreach'}='&tools_lreach';
sub tools_lreach {
	local ($id, $mobcost, $tfactor, $newmob, $frange);

	&build_lands_target($main::commandarg);
	print "\n        --------------Land Unit Reach Report--------------\n";
	print "                                       Fire   Movement   Movement\n";
	print "Unit  Type  Army     x,y    Eff  Tech  range    now      next upd\n";
	foreach $id (keys %target) {
		if ($target{$id}) {
			$tfactor = (50 + $land{$id}{'tech'})/(200 + $land{$id}{'tech'});
			$mobcost = 48000/(($land{$id}{'spd'} + $land{$id}{'spd'}*$tfactor)*$land{$id}{'eff'});
			$newmob = $land{$id}{'mob'} + $land{'max_gain'};
			$newmob = 127 if $newmob > 127;
			$frange = $land{$id}{'eff'}>59?($world{'firerangefactor'}*$land{$id}{'frg'}*$tfactor/2):0;
			if ($frange) {
				$frange = sprintf("%3.2f", $frange);
			} else {
				$frange = "";
			}
			printf "%4d  %4s    %1s   %4d,%-4d %3d%%  %3d %6s   %3d         %3d\n",
			$id,$land{$id}{'type'},$land{$id}{'army'},$land{$id}{'x'},$land{$id}{'y'},$land{$id}{'eff'},$land{$id}{'tech'},
			$frange,
			$land{$id}{'mob'}>0?int($land{$id}{'mob'}/$mobcost+0.999):0,
			int($newmob/$mobcost+0.999);
		}
	}
}

$main::functionmap{'fus'}='&tools_fus';
sub tools_fus {
	local($id, $fuelmob, $mobcost, $tfactor);

	&build_ships_target($main::commandarg);
	&print_n_parse("dump *");

	foreach $id (keys %shipname) {
		next if !$target{$id} ||
						$shipfuel{$id} == $fuelcar{$shipname{$id}};
		if ($dump{$shipsect{$id}}{'des'} ne 'h') {
			if (!$shipfuel{$id} && $shipmob{$id} <= 0) {
				printf "Oops: ship \#%d %s is stranded at sea with no fuel and no mobility.\n",
				$id, $shipname{$id};
			} else {
				$tfactor = (50 + $shiptech{$id})/(200 + $shiptech{$id});
				$fuelmob = 10*($shipfuel{$id}/$fueluse{$shipname{$id}});
				if ($shipmob{$id} + $maxshipmob > 127) {
					$fuelmob += 127 - $maxshipmob;
				} else {
					$fuelmob += $shipmob{$id};
				}
				$mobcost = 48000/(($shipspd{$shipname{$id}}+$shipspd{$shipname{$id}}
													 *$tfactor)*$shipeff{$id});
				printf "ship \#%d %s is at sea and will run out of fuel in %.1f updates (%d sectors).\n",
				$id,
				$shipname{$id},
				$shipfuel{$id}/($fueluse{$shipname{$id}}*($maxshipmob/10)),
				int($fuelmob/$mobcost+0.9999);
			}
		} elsif ($dump{$shipsect{$id}}{'own'} != $coun) {
			$tfactor = (50 + $shiptech{$id})/(200 + $shiptech{$id});
			$fuelmob = 10*($shipfuel{$id}/$fueluse{$shipname{$id}});
			if ($shipmob{$id} + $maxshipmob > 127) {
				$fuelmob += 127 - $maxshipmob;
			} else {
				$fuelmob += $shipmob{$id};
			}
			$mobcost = 48000/(($shipspd{$shipname{$id}}+$shipspd{$shipname{$id}}
												 *$tfactor)*$shipeff{$id});
			printf "ship \#%d %s is in %s's harbour and will run out of fuel in %.1f updates (%d sectors).\n",
			$id,
			$shipname{$id},
			$country{$dump{$shipsect{$id}}{'own'}},
			$shipfuel{$id}/($fueluse{$shipname{$id}}*($maxshipmob/10)),
			int($fuelmob/$mobcost+0.9999);
		} else {
			if ($dump{$shipsect{$id}}{'oil'} == 0 &&
					$dump{$shipsect{$id}}{'pet'} == 0) {
				print "Warning: Not enough fuel in $shipsect{$id} to fuel ship \#$id $shipname{$id}!\n";
			} else {
				&send("fuel ship $id ".($fuelcar{$shipname{$id}} - $shipfuel{$id}));
			}
		}
	}
}

$main::functionmap{'crew'}='&tools_crew';
sub tools_crew {
	local($id,$type,$milship,$cneed,$mneed,$mil,$civ);

	&build_ships_target($main::commandarg);

	print "\n-----------------Ship Crew Report-----------------\n";
	printf "%4s %-20s %8s     %s\n",
	'shp#', 'type', 'needs', 'can unload';

	foreach $id (keys %shipname) {
		next if !$target{$id};
		$type = $shipname{$id};
		if ($milship = &is_military_ship($type)) {
			$mneed = &round(100/((7/6)+(100/$cargo{$type, 'mil'})));
			$mil = $shipcargo{$id, 'mil'};
		} else {
			$cneed = &round((100-(7*$shipcargo{$id, "mil"}/5))/((7/6)+(100/$cargo{$type, "civ"})));
			$civ = $shipcargo{$id, 'civ'};
		}
		next if $milship && $civ == $mneed ||
						!$milship && $mil == $cneed;
		if ($milship) {
			if ($mil < $mneed) {
				printf "%4s %-20s %8s     %s\n",
				$id, $type, ($mneed - $mil)." mil", '';
			} else {
				printf "%4s %-20s %8s      %s\n",
				$id, $type, '', ($mil - $mneed)." mil";
			}
		} else {
			if ($civ < $cneed) {
				printf "%4s %-20s  %8s     %s\n",
				$id, $type, ($cneed - $civ)." civs", '';
			} else {
				printf "%4s %-20s  %8s     %s\n",
				$id, $type, '', ($civ - $cneed)." civs";
			}
		}
	}
}

sub is_military_ship {
	local($type) = @_;

	$shipfir{$type} || !$cargo{$type,'civ'};
}

$main::functionmap{'jack'}='&tools_jack';
sub tools_jack {
	local($sect);

	&build_sect_target($main::commandarg);
	&print_n_parse("prod *");

	foreach $sect (keys %dump) {
		next if ($dump{$sect}{'own'}!=$coun);
		next if !$target{$sect} ||
						$dump{$sect}{'own'} != $coun ||
							($newdes{$sect} ne 'j' &&
							 $newdes{$sect} ne 'k');
		if ($use1{$sect} < $max1{$sect} && $dump{$sect}{'i_dist'} < $max1{$sect}) {
			&send("th i $sect $max1{$sect}");
		}
	}
}

$main::functionmap{'rebel'}='&tools_rebel';
sub tools_rebel {
	local($sect);

	&build_sect_target($main::commandarg);

	print "\n--------------Che Riviera Report--------------\n";
	printf "%7s %3s %3s   %5s    %5s\n", 'sector', 'des', 'mob', 'extra', 'needs';
	foreach $sect (keys %dump) {
		next if ($dump{$sect}{'own'}!=$coun);
		next if (!$target{$sect} || $dump{$sect}{'own'} != $coun);
		if ($dump{$sect}{'*'} eq '*') {
			if ($dump{$sect}{'mil'} < int($dump{$sect}{'civ'}/10) + 2) {
				printf "%7s %3s %3s   %5s    %5s\n", $sect, $dump{$sect}{'des'}, '', '',
				int($dump{$sect}{'civ'}/10) - $dump{$sect}{'mil'} + 2;
			} elsif ($dump{$sect}{'mil'} > int($dump{$sect}{'civ'}/10)+4 &&
							 $dump{$sect}{'mob'} > 1) {
				printf("%7s %3s %3s   %5s    %5s\n", $sect, $dump{$sect}{'des'},
               $dump{$sect}{'mob'},
				       $dump{$sect}{'mil'}-int($dump{$sect}{'civ'}/10)-4, '');
			}
		}
	}
}

$main::functionmap{'civs'}='&tools_civs';
sub tools_civs {
	local($sect, $use, $extra, $effdelta, $des, $neweff);
	local ($c1, $c2, $c3, $d1, $d2, $d3, $f21, $f31, $work, $why, $area);

	$area = $main::commandarg;
	$area = '*' unless $area;
	&build_sect_target($area);

	&print_n_parse("prod $area");
	&print_n_parse("neweff $area");

	print "\n--------------Workforce Employment Report--------------\n";
	printf "      sector     neweff  workforce extra        needs\n";
	foreach $sect (keys %dump) {
		next if ($dump{$sect}{'own'}!=$coun);
		next if !$target{$sect} ||
						$dump{$sect}{'own'} != $coun ||
						$dump{$sect}{'work'} < 90 ||
						$dump{$sect}{'oldown'} != $coun;
		$why = '';
	
# Calculate delta in sector efficiency
		$des = $dump{$sect}{'des'};
		if ($des eq $newdes{$sect}) {
			if ($dump{$sect}{'eff'} < $neweff{$sect}) { # building up
				if ($neweff{$sect} > 30) {
					if ($neweff{$sect} > 61) {
						$effdelta = 100 - $dump{$sect}{'eff'};
						$why = "to become 100%";
					} else {
						$effdelta = 61 - $dump{$sect}{'eff'};
						$why = "to become 61%";
					}
				} else {
					$effdelta = 0;
				}
			} elsif ($dump{$sect}{'eff'} > $neweff{$sect}) { # tearing down
				$effdelta = ($dump{$sect}{'eff'} - $neweff{$sect}) / 4;
			} else {
				$effdelta = 0;
			}
		} else { # tear down and build up
			$effdelta = $dump{$sect}{'eff'} / 4 + $neweff{$sect};
			if ($neweff{$sect} > 30) {
				if ($neweff{$sect} > 61) {
					$effdelta += 100 - $neweff{$sect};
					$why = "to become 100%";
				} else {
					$effdelta += 61 - $neweff{$sect};
					$why = "to become 61%";
				}
			}
		}
		
		if ($use1{$sect}) {                # It consumes
			if ($use1{$sect} < $max1{$sect}) { # Too many civs
				$use = $use1{$sect} + $use2{$sect} + $use3{$sect};
				$extra = $wkfc{$sect} -
					(($use>$effdelta?$use:0) + 2 * $effdelta) * 100 / $world{'etu'};
			} elsif ($des ne 'e') { # Maybe it needs more civs
				$c1 = $dump{$sect}{$comm1{$sect}};
				$c2 = $dump{$sect}{$comm2{$sect}} if $comm2{$sect};
				$c3 = $dump{$sect}{$comm3{$sect}} if $comm3{$sect};
				if ($use3{$sect}) {
					$f21 = $use2{$sect}/$use1{$sect};
					$f31 = $use3{$sect}/$use1{$sect};
					$d1 = $c1 - $use1{$sect};
					$d2 = $c2 - $use2{$sect};
					$d3 = $c3 - $use3{$sect};
					if ($d1 > 0 && $f21 * $d1 < $d2 && $f31 * $d1 < $d3) {
						$work = (1 + $f21 + $f31) * $d1;
						$why = "to be able to use ".($use1{$sect}+$d1)." ".$comm1{$sect};
					} elsif ($d2 > 0 && $d2 < $f21 * $d1 && $f31 * $d2 < $f21 * $d3) {
						$work = (1/$f21 + 1 + $f31/$f21) * $d2;
						$why = "to be able to use ".($use2{$sect}+$d2)." ".$comm2{$sect};
					} elsif ($d3 > 0 && $d3 < $f31 * $d1 && $f21 * $d3 < $f31 * $d2) {
						$work = (1/$f31 + $f21/$f31 + 1) * $d3;
						$why = "to be able to use ".($use3{$sect}+$d3)." ".$comm3{$sect};
					} else {
						$work = 0;
					}
				} elsif ($use2{$sect}) {
					$f21 = $use2{$sect}/$use1{$sect};
					$d1 = $c1 - $use1{$sect};
					$d2 = $c2 - $use2{$sect};
					if ($d1 > 0 && $f21 * $d1 < $d2) {
						$work = (1 + $f21) * $d1;
						$why = "to be able to use ".($use1{$sect}+$d1)." ".$comm1{$sect};
					} elsif ($d2 > 0 && $d2 < $f21 * $d1) {
						$work = (1/$f21 + 1) * $d2;
						$why = "to be able to use ".($use2{$sect}+$d2)." ".$comm2{$sect};
					} else {
						$work = 0;
					}
				} elsif ($use1{$sect} < $c1) {
					$work = $c1 - $use1{$sect};
					$why = "to be able to use ".($use1{$sect}+$work)." ".$comm1{$sect};
				} else {
					$work = 0;
				}
				$extra = -$work * 100 / $world{'etu'};
			} else {
				$extra = 0;
			}
		} elsif ($will{$sect}) {        # It produces but doesn't consume
			$extra = 0;
		} elsif ($des eq 'h' ||
						 $des eq '*' ||
						 $des eq '!' ||
						 $des eq 'f' ||
						 $des eq 'c') {
			$extra = 0;
		} else {                        # It doesn't produce
			$extra = $dump{$sect}{'civ'} * (1 + $world{'obrate'} * $world{'etu'}) +
							 $dump{$sect}{'uw'} * (1 + $world{'uwbrate'} * $world{'etu'}) +
							 $dump{$sect}{'mil'} / 5 -
							 2 * $effdelta * 100 / $world{'etu'};
		}
		$extra = int($extra / (1 + $world{'obrate'} * $world{'etu'}) - 1);
		if ($extra && $extra < $dump{$sect}{'civ'} - $maxciv) {
			$extra = $dump{$sect}{'civ'} - $maxciv;
		}
		if ($extra > 1) {
			local ($cextra,$uextra);
			$cextra = &min($extra,$dump{$sect}{'civ'});
			$uextra = &min($extra-$cextra,$dump{$sect}{'uw'});
			$cextra -=1 if ($cextra && $uextra);
			printf "%7s %1s %3d%%   %1s %4s   %4s    %4s %4s\n",
			$sect,
			$des,
			$dump{$sect}{'eff'},
			($newdes{$sect} ne $des)?$newdes{$sect}:'',
			($neweff{$sect} != $dump{$sect}{'eff'})?$neweff{$sect}.'%':'',
			int($dump{$sect}{'civ'} + $dump{$sect}{'uw'} + $dump{$sect}{'mil'} / 5),
			$cextra?($cextra.'c'):'',
			$uextra?($uextra.'u'):'';
		} elsif ($extra < -1) {
			printf "%7s %1s %3d%%   %1s %4s   %4s    %5s   %5s %s\n",
			$sect,
			$des,
			$dump{$sect}{'eff'},
			($newdes{$sect} ne $des)?$newdes{$sect}:'',
			($neweff{$sect} != $dump{$sect}{'eff'})?$neweff{$sect}.'%':'',
			int($dump{$sect}{'civ'} + $dump{$sect}{'uw'} + $dump{$sect}{'mil'} / 5),
			'',
			-$extra,
			$why?'('.$why.')':'';
		}
	}
}

$main::functionmap{'delta'}='&tools_prod_delta';

# prod_delta: originally written by Ken Stevens as a standalone perl script, 
#  added to tools.pl by Sam Tetherow

sub tools_prod_delta {
	local(%plus, %minus, %have, @usable, @unusable, $xy, $com, %unituse, %unitneed, %planeuse, %planeneed, %shipuse, %shipneed, $unit, $plane, $ship, %units, %planes, %ships, $area);
 
	$area = $main::commandarg;
	$area = '*' unless $area;

	&build_sect_target($area);
	
	&print_n_parse("dump *") if $area ne '*';
	&print_n_parse("product *");

	print STDERR "parsing land *...";
	$main::command="land";
	print $main::S "land *\n";
	while(&getline()) {
		if (/\s*(\d+)\s+.+%/) {
			$units{$unitsect{$1}}.="$1 ";
		}
	} 
	print STDERR "done\n";

	foreach $xy (keys %units) {
		local($disthit)="$dump{$xy}{'dist_x'},$dump{$xy}{'dist_y'}";
		if ($target{$disthit}) {
			&build_units($xy);
		}
	}
	foreach $unit (keys %unitmob) {        # Use mob so you don't get enemy units
		$minus{'mil'}+=$unituse{$unit, 'mil'};
		$minus{'lcm'}+=$unituse{$unit, 'lcm'};
		$minus{'hcm'}+=$unituse{$unit, 'hcm'};
		$minus{'gun'}+=$unituse{$unit, 'gun'};
		$minus{'shell'}+=$unituse{$unit, 'shell'};
	}

	print STDERR "parsing plane *...";
	$main::command="plane";
	print $main::S "plane *\n";
	while(&getline()) {
		if (/\s*(\d+)\s+.+%/) {
			$planes{$planesect{$1}}.="$1 ";
		}
	} 
	print STDERR "done\n";

	foreach $xy (keys %planes) {
		local($disthit)="$dump{$xy}{'dist_x'},$dump{$xy}{'dist_y'}";
		if ($target{$disthit}) {
			&build_planes($xy);
		}
	}
	foreach $plane (keys %planemob) {        # Use mob so you don't get enemy planes
		$minus{'mil'}+=$planeuse{$plane, 'mil'};
		$minus{'lcm'}+=$planeuse{$plane, 'lcm'};
		$minus{'hcm'}+=$planeuse{$plane, 'hcm'};
	}

	print STDERR "parsing ship *...";
	$main::command="ship";
	print $main::S "ship *\n";
	while(&getline()) {
		if (/\s*(\d+)\s+.+%/) {
			$ships{$shipsect{$1}}.="$1 ";
		}
	} 
	print STDERR "done\n";

	foreach $xy (keys %ships) {
		local($disthit)="$dump{$xy}{'dist_x'},$dump{$xy}{'dist_y'}";
		if ($target{$disthit}) {
			&build_ships($xy);
		}
	}
	foreach $ship (keys %shipmob) {        # Use mob so you don't get enemy ships
		$minus{'lcm'}+=$shipuse{$ship, 'lcm'};
		$minus{'hcm'}+=$shipuse{$ship, 'hcm'};
	}

	foreach $xy (keys %will) {                        # all producing sectors
		local($disthit)="$dump{$xy}{'dist_x'},$dump{$xy}{'dist_y'}";
		next unless $target{$disthit};
		$plus{$make{$xy}}+=&min($will{$xy}, $prodmax{$xy});
		if ($comm1{$xy}) {
			$minus{$comm1{$xy}}+=$use1{$xy};
		}
		if ($comm2{$xy}) {
			$minus{$comm2{$xy}}+=$use2{$xy};
		}
		if ($comm3{$xy}) {
			$minus{$comm3{$xy}}+=$use3{$xy};
		}
	}
	foreach $xy (keys %dump) {
		next if ($dump{$xy}{'own'}!=$coun);
		local($disthit)="$dump{$xy}{'dist_x'},$dump{$xy}{'dist_y'}";
		next unless $target{$disthit};
		next unless $dump{$xy}{'own'}==$main::coun;                        # skip if not ours
		foreach $com (values %commstr) {                        # for all commodites
			$have{$com}+=$dump{$xy}{$com};
		}
																	 # Fort usage of hcms
		if (($dump{$xy,'des'} eq 'f' && $dump{$xy,'eff'}<100) || $dump{$xy,'sdes'} eq 'f') {
			$main::command='neweff';
			print $main::S "neweff $xy\n";
			while(&getline()) { 1; }
			if ($neweff{$xy}>$dump{$xy}{'eff'} && $dump{$xy}{'des'} eq 'f') {
				$minus{'hcm'}+=$land{'f'}{'hcm'}*($neweff{$xy}-$dump{$xy}{'eff'});
			} elsif ($dump{$xy}{'sdes'} eq 'f') {
				$minus{'hcm'}+=$land{'f'}{'hcm'}*$neweff{$xy};
			}
		}
	}
	$plus{'civ'}=int($have{'civ'}*$world{'obrate'}*$world{'etu'});
	$plus{'uw'}=int($have{'uw'}*$world{'uwbrate'}*$world{'etu'});
	$minus{'food'}=int(($have{'civ'}+$have{'uw'}+$have{'mil'})*$world{'etu'}*$world{'eatrate'}+($plus{'civ'}+$plus{'uw'})*$world{'babyeat'});

	print "\n--------------------Production Delta Report--------------------\n";
	printf "%5s %8s %8s %8s %8s %8s %8s\n", 'com', 'start', '+', '-', 'delta', 'net', 'supply';
	@usable=('food', 'iron', 'oil', 'dust', 'lcm', 'hcm');
	@nonusable=('bar', 'pet', 'shell', 'gun', 'civ', 'uw', 'mil');
	while($com=shift(@usable)) {
		if ($have{$com}!=0 || $plus{$com}!=0) {
			printf "%5s %8s %8s %8s %8s %8s %8s\n", $com, $have{$com}, $plus{$com}, $minus{$com}, $plus{$com}-$minus{$com}, $have{$com}+$plus{$com}-$minus{$com}, &prod_warn($have{$com}, $plus{$com}-$minus{$com});
		}
	}
	print "---------------------------------------------------------------\n";
	while($com=shift(@nonusable)) {
		if ($have{$com}!=0 || $plus{$com}!=0) {
			printf "%5s %8s %8s %8s %8s %8s\n", $com, $have{$com}, $plus{$com}, '', '', $have{$com}+$plus{$com};
		}
	}
} 

$main::functionmap{'fdelta'}='&tools_food_delta'; 

# food_delta: Originally written by Ken Stevens as part of delta a standalone
#  perl tool, added to tools.pl by Sam Tetherow

sub tools_food_delta {
	local($type, $civcount, $uwcount, $sectcount, $citycount, $foodcount);
	local($xy, $fprod, $cbaby, $ubaby, $area);

	$area = $main::commandarg;
	$area = '*' unless $area;
	&build_sect_target($area);

	&print_n_parse("dump *") if $area ne '*';
	&print_n_parse("product *");

	foreach $xy (keys %dump) {
		next if ($dump{$xy}{'own'}!=$coun);
		next unless $dump{$xy}{'own'}==$main::coun;
		$dist="$dump{$xy}{'dist_x'},$dump{$xy}{'dist_y'}";
		next unless $target{$dist};
		$civcount+=$dump{$xy}{'civ'};
		$uwcount+=$dump{$xy}{'uw'};
		if ($dump{$xy}{'des'} ne '^') {
			if ($dump{$xy}{'des'} eq 'c' && defined($option{'BIG_CITY'})) {
				++$citycount;
			} else {
				++$sectcount;
			}
		}
		$foodcount+=$dump{$xy}{'food'};

																# If this sector products food add it
		if ($make{$xy} eq 'food') {
			$fprod+=&min($will{$xy}, $prodmax{$xy});
		}
	}
	local($civmax)=$sectcount*$maxpop + $citycount*$maxpop*10;
	local($uwmax)=$civmax;
	local($civ)=$civcount+$milcount;
	local($uw)=$uwcount;
	local($foo)=$foodcount;
	print "\n           ----FOOD DELTA REPORT----\n";
	printf "%6s %6s %6s %6s %6s %6s %6s\n", '', 'start', '', '', 'food', 'food', 'food';
	printf "%6s %6s %6s %6s %6s %6s %6s\n", 'update', 'food', 'civ', 'uw', 'eaten', 'prod', 'delta';
	print "---------------------------------------------------\n";
	for($i=1; $i<=15; ++$i) {
		local($cbaby)=$civ*$world{'obrate'}*$world{'etu'};
		local($ubaby)=$uw*$world{'uwbrate'}*$world{'etu'};
		local($eaten)=(($civ+$uw)*$world{'eatrate'}*$world{'etu'})+(($cbaby+$ubaby)*$world{'babyeat'});
		local($delta)=$fprod-$eaten;
		printf "%5d: %6d %6d %6d %6d %6d %6d\n", $i, $foo, $civ, $uw, $eaten, $fprod, $delta;
		$foo +=$delta;
		$civ +=$cbaby;
		$civ=$civmax if $civ>$civmax;
		$uw +=$ubaby;
		$uw=$uwmax if $uw>$uwmax;
	}
	if ($citycount) {
		print "Maximum civs for $citycount cities and $sectcount sectors: $civmax\n";
		print "Maximum uws for $citycount cities and $sectcount sectors: $uwmax\n";
	} else {
		print "Maximum civs for $sectcount sectors: $civmax\n";
		print "Maximum uws for $sectcount sectors: $uwmax\n";
	}
}

$main::functionmap{'wdelta'}='&tools_warehouse_delta';

# warehouse_delta: Written by Sam Tetherow to show warehouse action at the 
# update.

sub tools_warehouse_delta {
	local(%distcenters, %use, %make, @usabel, @nonusable);
	local($type, $dist, $xy, $c, $civbabies, $uwbabies, $com, $area);

	$area = $main::commandarg;
	$area = '*' unless $area;
 
	&build_sect_target($area);
	&print_n_parse("dump *") if $area ne '*';
	&print_n_parse("product *");

	print STDERR "parsing land *...";
	$main::command="land";
	print $main::S "land *\n";
	while(&getline()) {
		if (/\s+(\d+)\s+.+%/) {
			$units{$unitsect{$1}}.="$1 ";
		}
	} 
	print STDERR "done\n";

	print STDERR "parsing plane *...";
	$main::command="plane";
	print $main::S "plane *\n";
	while(&getline()) {
		if (/\s+(\d+)\s+.+%/) {
			$planes{$planesect{$1}}.="$1 ";
		}
	} 
	print STDERR "done\n";

	print STDERR "parsing ship *...";
	$main::command="ship";
	print $main::S "ship *\n";
	while(&getline()) {
		if (/\s+(\d+)\s+.+%/) {
			$ships{$shipsect{$1}}.="$1 ";
		}
	} 
	print STDERR "done\n";

	foreach $xy (keys %dump) {
		next if ($dump{$xy}{'own'}!=$coun);
		next unless $dump{$xy}{'own'}==$main::coun;
		$dist="$dump{$xy}{'dist_x'},$dump{$xy}{'dist_y'}";
		next if $dist eq $xy;
																# If the distcenter is undefined (1st occurance)
																# initialize the use variables.
		if (!defined($distcenters{$dist})) {
			if ($target{$dist}) { 
				$distcenters{$dist}=1;
			} else { 
				$distcenters{$dist}=0;
			}
		}

		next unless $distcenters{$dist}==1;

		undef %unituse;
		undef %unitneed;
		undef %planeuse;
		undef %planeneed;
		undef %shipuse;
		undef %shipneed;
		&build_units($xy) if $units{$xy};
		&build_planes($xy) if $planes{$xy};
		&build_ships($xy) if $ships{$xy};
		foreach $unit (keys %unituse) {
			$use{$xy, 'mil'}+=$unituse{$unit, 'mil'};
			$use{$xy, 'lcm'}+=$unituse{$unit, 'lcm'};
			$use{$xy, 'hcm'}+=$unituse{$unit, 'hcm'};
			$use{$xy, 'gun'}+=$unituse{$unit, 'gun'};
			$use{$xy, 'shell'}+=$unituse{$unit, 'shell'};
		}
		foreach $plane (keys %planeuse) {
			$use{$xy, 'mil'}+=$planeuse{$plane, 'mil'};
			$use{$xy, 'lcm'}+=$planeuse{$plane, 'lcm'};
			$use{$xy, 'hcm'}+=$planeuse{$plane, 'hcm'};
		}
		foreach $ship (keys %shipuse) {
			$use{$xy, 'lcm'}+=$shipuse{$ship, 'lcm'};
			$use{$xy, 'hcm'}+=$shipuse{$ship, 'hcm'};
		}

																	 # Fort usage of hcms
		if (($dump{$xy,'des'} eq 'f' && $dump{$xy,'eff'}<100) || $dump{$xy,'sdes'} eq 'f') {
			$main::command='neweff';
			print $main::S "neweff $xy\n";
			while(&getline()) { 1; }
			if ($neweff{$xy}>$dump{$xy}{'eff'} && $dump{$xy}{'des'} eq 'f') {
				$use{$xy, 'hcm'}+=$land{'f'}{'hcm'}*($neweff{$xy}-$dump{$xy}{'eff'});
			} elsif ($dump{$xy}{'sdes'} eq 'f') {
				$use{$xy, 'hcm'}+=$land{'f'}{'hcm'}*$neweff{$xy};
			}
		}
		if ($will{$xy}) {
			$make{$xy, $make{$xy}}+=&min($will{$xy}, $prodmax{$xy});
			$use{$xy, $comm1{$xy}}+=$use1{$xy} if $comm1{$xy};
			$use{$xy, $comm2{$xy}}+=$use2{$xy} if $comm2{$xy};
			$use{$xy, $comm3{$xy}}+=$use3{$xy} if $comm3{$xy};
		}

																				# Grow population and figure food.
		if ($dump{$xy}{'civ'}<$maxciv) {
			$civbabies=$dump{$xy}{'civ'}*$world{'obrate'}*$world{'etu'};
			if ($civbabies+$dump{$xy}{'civ'}>$maxciv) { $civbabies=$maxciv-$dump{$xy}{'civ'}; }
			$make{$xy, 'civ'}+=$civbabies;
		}
		if ($dump{$xy}{'uw'}<$maxuw) {
			$uwbabies=$dump{$xy}{'uw'}*$world{'uwbrate'}*$world{'etu'};
			if ($uwbabies+$dump{$xy}{'uw'}>$maxuw) { $uwbabies=$maxuw-$dump{$xy}{'uw'}; }
			$make{$xy, 'uw'}+=$uwbabies;
		}
		$use{$xy, 'food'}+=($dump{$xy}{'civ'}+$dump{$xy}{'mil'}+$dump{$xy}{'uw'})*$world{'etu'}*$world{'eatrate'};
		$use{$xy, 'food'}+=($uwbabies+$civbabies)*$world{'babyeat'};

																# If we have non-0 threshes account for them.
		foreach $c (keys %commstr) {
			local($distkey)="$c" . "_dist";
			local($com)=$commstr{$c};
			if ($dump{$xy}{$distkey}!=0) {
				if ($dump{$dist, $com}+$make{$dist, $com}-$use{$dist, $com}<=9999) {
					if ($dump{$xy}{$distkey}<$dump{$xy}{$com}+$make{$xy, $com}-$use{$xy, $com}) {
						$make{$dist, $com}+=$dump{$xy}{$com}+$make{$xy, $com}-$use{$xy, $com}-$dump{$xy}{$distkey};
					} else {
						$use{$dist, $com}+=$dump{$xy}{$distkey}-($dump{$xy}{$com}+$make{$xy, $com}-$use{$xy, $com});
					}
				}
			}
		}
	}
	 
	foreach $xy (keys %distcenters) {
		@usable=('food', 'iron', 'oil', 'dust', 'lcm', 'hcm');
		@nonusable=('bar', 'pet', 'shell', 'gun', 'civ', 'uw', 'mil');
		if ($distcenters{$xy}!=1) { next; }
		print "\n--------------------Distcenter $xy--------------------\n";
		printf("  %6s %8s %8s %8s %8s %8s %8s\n", "Com", "Start", "+", "-", "Delta", "Net", "Supply");
		while($com=shift(@usable)) {
			if ($dump{$xy}{$com}!=0 || $make{$xy, $com}!=0) {
				printf("  %6s %8d %8d %8d %8d %8d %8s\n", $com, $dump{$xy}{$com}, $make{$xy, $com}, $use{$xy, $com}, $make{$xy, $com}-$use{$xy, $com}, $dump{$xy}{$com}+$make{$xy, $com}-$use{$xy, $com}, &prod_warn($dump{$xy}{$com}, $make{$xy, $com}-$use{$xy, $com}));
			}
		}
		print "----------------------------------------------------------------\n";
		while($com=shift(@nonusable)) {
			if ($dump{$xy}{$com}!=0 || $make{$xy, $com}!=0) {
				printf("  %6s %8d %8d %8s %8s %8d\n", $com, $dump{$xy}{$com}, $make{$xy, $com}, ' ', ' ', $dump{$xy}{$com}+$make{$xy, $com});
			}
		}
	}
}
 
sub prod_warn {
	local($start, $delta)=@_;
	if ($delta>=0) { return ''; }
	return int(-1*$start / $delta) . '';
}

sub in_realm {                                # in_realm($realmstring, $sect)
	local($realm, $sect)=@_;
	if ($realm eq '*') { return 1; }
	local($left,$top)=split(/,/, $realm);
	local(@tmp)=split(/:/, $left);
	local($left)=shift(@tmp); local($right)=shift(@tmp);
	$right=$left unless $right;
	local(@tmp)=split(/:/, $top);
	local($top)=shift(@tmp); local($bottom)=shift(@tmp);
	$bottom=$top unless $bottom;
	($x, $y)=split(/,/, $sect);
	if ($left<=$right) {
		if ($top<=$bottom) {
			if ($x>=$left && $x<=$right && $y>=$top && $y<=$bottom) { return 1; }
			else { return 0; }
		} else {
			if ($x>=$left && $x<=$right && (($y>=$top && $y<$world{'height'}/2) || ($y<=$bottom && $y>=-1*$world{'height'}/2))) { 
				return 1;
			} else { return 0; }
		}
	} else {
		if ($bottom<=$top) {
			if (($y>=$top && $y<=$bottom) && (($x>=$left && $x<$world{'width'}/2) || ($x<=$right && $x>=-1*$world{'width'}/2))) { 
				return 1;
			} else { return 0; }
		} else {
			if ((($x>=$left && $x<$world{'width'}/2) || ($x<=$right && $x>=-1*$world{'width'}/2)) &&
					(($y>$top && $y<$world{'height'}/2) || ($y<$bottom && $y>-1*$world{'height'}/2))) { 
				return 1;
			} else { return 0; }
		}
	}
	return 0;
}
	
$main::functionmap{'stat'} = '&tools_status';
# Here are the status commands to get info out of the internal DB
# I don't if these should go in tools.pl or parse.pl, but tools seemed to
# be the logical place for them.

# status will get you information about a sector in enemy territory
# I should probably add dating to information while I am at it because it
# would be nice to know how old this information is.

sub tools_status {
	local(@switch, @equal, @less, @nequal, @great, @tmp, $amt, $val, $xy, $fail);
	local($mon, $mday, $hour, $min);
	if ($main::commandarg=~/\s*(\S+)\s*(.*)/) {
		$area=$1;
		$switches=$2 if $2;
	} else {
		print STDERR "stat <AREA> (?switch)\n";
		return;
	}
	if ($area=~/#(\d+)/) {
		$area=$realm{$1};
	}
	$switches=~s/^\?//; 
	local(@switch)=split(/&/, $switches);
	while($tmp=shift(@switch)) {
		if ($tmp=~/(\S+)=(\S+)/) { push(@equal, "$1 $2"); } # mask type to des
		elsif ($tmp=~/(\S+)\#(\S+)/) { push(@nequal, "$1 $2"); }
		elsif ($tmp=~/(\S+)<(\S+)/) { push(@less, "$1 $2"); }
		elsif ($tmp=~/(\S+)>(\S+)/) { push(@great, "$1 $2"); }
		else { print "Unknown switch $tmp\n"; return; }
	}
	foreach $xy (keys %dump) {
		next if ($dump{$xy}{'own'}!=$coun);
		push(@sects, $xy) if &in_realm($area, $xy);
	}
	print "own  x,y   des eff civ mil  pet food   fort   ship    air   land  date\n";
	$sectcount=0;
	while($xy=shift(@sects)) {
		$fail=0; ($x, $y)=($xy=~/(\S+),(\S+)/);
		@tmp=@equal;
		while($#tmp>-1) {
			($val, $amt)=split(/ /, shift(@tmp),2);
			if ($val eq 'type') { $val='des'; }
			if ($val eq 'own') {
				if ($dump{$xy}{'own'} ne $amt && $dump{$xy}{'own'} ne $number{$amt}) { $fail=1; }
			} elsif ($dump{$xy}{$val} ne $amt) { $fail=1; }
		}
		@tmp=@nequal;
		while($#tmp>-1) {
			($val, $amt)=split(/ /, shift(@tmp),2);
			if ($val eq 'type') { $val='des'; }
			if ($val eq 'own') {
				if ($dump{$xy}{'own'} ne $amt) { $fail=1; }
			} elsif ($dump{$xy}{$val} eq $amt) { $fail=1; }
		}
		@tmp=@less;
		while($#tmp>-1) {
			($val, $amt)=split(/ /, shift(@tmp),2);
			if ($val eq 'type') { $val='des'; }
			if ($dump{$xy}{$val}>=$amt) { $fail=1; }
		}
		@tmp=@great;
		while($#tmp>-1) {
			($val, $amt)=split(/ /, shift(@tmp),2);
			if ($val eq 'type') { $val='des'; }
			if ($dump{$xy}{$val}<=$amt) { $fail=1; }
		}
		if ($fail==0) {
			($mon, $mday, $hour, $min)=($dump{$xy}{'date'}=~
				/(\d+)\/(\d+) (\d+):(\d+)/);
			printf "%2d%4d,%-4d %1s %3s%%%4d %3s %4s %4s %6s %6s %6s %6s %3s %2d %02d:%02d\n",
				$dump{$xy}{'own'},
				$x, $y,
				$dump{$xy}{'des'},
				$dump{$xy}{'eff'},
				$dump{$xy}{'civ'},
				$dump{$xy}{'mil'},
				$dump{$xy}{'pet'},
				$dump{$xy}{'food'},
				$def{$xy, 'fort'},
				$def{$xy, 'ship'},
				$def{$xy, 'plane'},
				$def{$xy, 'land'},
				$main::monthname{$mon},
				$mday,
				$hour,
				$min;
			$sectcount++;
		}
	}
	print "$sectcount Sectors.\n";
}

$main::functionmap{'lstat'}='&tools_lstat';

sub tools_lstat {
	local(@switch, @equal, @less, @nequal, @great, @tmp, $amt, $val, $xy, $fail);
	local($mon, $mday, $hour, $min);
	if ($main::commandarg=~/\s*(\S+)\s*(.*)/) {
		$area=$1;
		$switches=$2 if $2;
	} else {
		print STDERR "lstat <AREA> (?switch)\n";
		return;
	}
	if ($area=~/#(\d+)/) {
		$area=$realm{$1};
	}
	$switches=~s/^\?//;
	local(@switch)=split(/&/, $switches);

	printf "%10s %4s %-20s %-9s %3s  %3s %-11s\n", 'own', 'unit', 'Type', 'at(near)', 'eff', 'tech', 'date';
	local($unitcount)=0;
	foreach $unit (keys %unitown) {
		$fail=0;
		next unless (&in_realm($area, $unitsect{$unit}) | &in_realm($area, $unitnear{$unit}));
;
		@tmp=@switch;
		while($tmp=shift(@tmp)) {
			($val, $op, $amt)=($tmp=~/^(\S+)([=\#<>])\"?(.+)\"?$/);
			if ($val eq 'eff') { $val=$land{$unit}{'eff'}; }
			elsif ($val eq 'tech') { $val=$unittech{$unit}; }
			elsif ($val eq 'own') { 
				$val=$land{$unit}{'own'};                #*# Untested
				if (!($amt=~/^\d+$/)) { $amt=$number{$amt}; }
			}
			elsif ($val eq 'type') { $val=substr($land{$unit}{'name'},0,length($amt)); }
			else {
				print "Invalid switch $tmp\n";
				return;
			}
			if ($op eq '=') {
				if ($val ne $amt) { $fail=1; }
			} elsif ($op eq '#') {
				if ($val eq $amt) { $fail=1; }
			} elsif ($op eq '<') {
				if ($val>$amt) { $fail=1; }
			} elsif ($op eq '>') {
				if ($val<$amt) { $fail=1; }
			}
		}
		if ($fail==0) {
			$unitcount++;
			($mon, $mday, $hour, $min)=($unitdate{$unit}=~
				/(\d+)\/(\d+) (\d+):(\d+)/);
			printf "%10s %4d %-20s %-9s %3s%% %3s %3s %2d %02d:%02d\n",
			$country{$land{$unit}{'own'}}?substr($country{$land{$unit}{'own'}},0,10):$land{$unit}{'own'},
			$unit,
			$land{$unit}{'name'},
			$unitsect{$unit} ? $unitsect{$unit} : "(" . $unitnear{$unit} . ")",
			$land{$unit}{'eff'},
			$unittech{$unit},
			$main::monthname{$mon},
			$mday,
			$hour,
			$min;
		}
	}
	print "$unitcount Units.\n";
}
	
$main::functionmap{'pstat'}='&tools_pstat';

sub tools_pstat {
	local(@switch, @equal, @less, @nequal, @great, @tmp, $amt, $val, $xy, $fail);
	if ($main::commandarg=~/\s*(\S+)\s*(.*)/) {
		$area=$1;
		$switches=$2 if $2;
	} else {
		print STDERR "pstat <AREA> (?switch)\n";
		return;
	}
	if ($area=~/#(\d+)/) {
		$area=$realm{$1};
	}
	$switches=~s/^\?//; 
	local(@switch)=split(/&/, $switches);

	printf "%10s %4s %-20s %-9s %3s  %3s %-11s\n", 'own', 'plane', 'Type', 'at(near)', 'eff', 'tech', 'date';
	local($planecount)=0;
	foreach $plane (keys %planeown) {
		$fail=0;
		next unless (&in_realm($area, $planesect{$plane}) | &in_realm($area, $planenear{$plane}));
		@tmp=@switch;
		while($tmp=shift(@tmp)) {
			($val, $op, $amt)=($tmp=~/^(\S+)([=\#<>])\"?(.+)\"?$/);
			if ($val eq 'eff') { $val=$plane{$plane}{'eff'}; }
			elsif ($val eq 'tech') { $val=$plane{$plane}{'tech'}; }
			elsif ($val eq 'own') {                 #*# Untested
				$val=$planeown{$plane}; 
				if (($amt=~/^\d+$/)) { $amt=$number{$amt}; }
			}
			elsif ($val eq 'type') { $val=substr($plane{$plane}{'type'},0,length($amt)); }
			else {
				print "Invalid switch $tmp\n";
				return;
			}
			if ($op eq '=') {
				if ($val ne $amt) { $fail=1; }
			} elsif ($op eq '#') {
				if ($val eq $amt) { $fail=1; }
			} elsif ($op eq '<') {
				if ($val>$amt) { $fail=1; }
			} elsif ($op eq '>') {
				if ($val<$amt) { $fail=1; }
			}
		}
		if ($fail==0) {
			$planecount++;
			printf "%10s %4d %-20s %-9s %3s%% %3s %-11s\n",
			$country{$planeown{$plane}}?substr($country{$planeown{$plane}},0,10):$planeown{$plane},
			$plane,
			$plane{$plane}{'type'},
			$planesect{$plane} ? $planesect{$plane} : "(" . $planenear{$plane} . ")",
			$plane{$plane}{'eff'},
			$plane{$plane}{'tech'},
			$planedate{$plane};
		}
	}
	print "$planecount Planes.\n";
}

$main::functionmap{'sstat'}='&tools_sstat';
sub tools_sstat {
	local(@switch, @equal, @less, @nequal, @great, @tmp, $amt, $val, $xy, $fail);
	local($mon, $mday, $hour, $min);
	if ($main::commandarg=~/\s*(\S+)\s*(.*)/) {
		$area=$1;
		$switches=$2 if $2;
	} else {
		print STDERR "sstat <AREA> (?switch)\n";
		return;
	}
	if ($area=~/#(\d+)/) {
		$area=$realm{$1};
	}
	$switches=~s/^\?//; 
	local(@switch)=split(/&/, $switches);

	printf "%10s %4s %-20s %-9s %3s  %3s %-11s\n", 'own', 'ship', 'Type', 'at(near)', 'eff', 'tech', 'date';
	local($shipcount)=0;
	foreach $ship (keys %shipown) {
		$fail=0;
		next unless (&in_realm($area, $shipsect{$ship}) | &in_realm($area, $shipnear{$ship}));
		@tmp=@switch;
		while($tmp=shift(@tmp)) {
			($val, $op, $amt)=($tmp=~/^(\S+)([=\#<>])\"?(.+)\"?$/);
			if ($val eq 'eff') { $val=$shipeff{$ship}; }
			elsif ($val eq 'tech') { $val=$shiptech{$ship}; }
			elsif ($val eq 'own') {                 #*# Untested
				$val=$shipown{$ship};
				if (!($amt=~/^\d+$/)) { $amt=$number{$amt}; }
			}
			elsif ($val eq 'type') { $val=substr($shipname{$ship},0,length($amt)); }
			else {
				print "Invalid switch $tmp\n";
				return;
			}
			if ($op eq '=') {
				if ($val ne $amt) { $fail=1; }
			} elsif ($op eq '#') {
				if ($val eq $amt) { $fail=1; }
			} elsif ($op eq '<') {
				if ($val>$amt) { $fail=1; }
			} elsif ($op eq '>') {
				if ($val<$amt) { $fail=1; }
			}
		}
		if ($fail==0) {
			$shipcount++;
			($mon, $mday, $hour, $min)=($shipdate{$ship}=~
				/(\d+)\/(\d+) (\d+):(\d+)/);
			printf "%10s %4d %-20s %-9s %3s%% %3s %3s %2d %02d:%02d\n",
			$country{$shipown{$ship}}?substr($country{$shipown{$ship}},0,10):$shipown{$ship},
			$ship,
			$shipname{$ship},
			$shipsect{$ship} ? $shipsect{$ship} : "(" . $shipnear{$ship} . ")",
			$shipeff{$ship},
			$shiptech{$ship},
			$main::monthname{$mon},
			$mday,
			$hour,
			$min;
		}
	}
	print "$shipcount Ships.\n";
}

# Makerealm returns a list of every sector in a realm.  Currently unused!!

sub makerealm {
	local($range)=@_;
	if ($range eq '*') { $range=join("","-$world{'width'}/2:",$world{'width'}/2-1,",-$world{'height'}/2:",$world{'height'}/2-1); }
	local($xrange, $yrange)=($range=~/(\S+)\,(\S+)/);
	local(@tmp)=split(/:/, $xrange);
	local($xmin)=shift(@tmp); local($xmax)=shift(@tmp);
	$xmax=$xmin unless $xmax;
	(@tmp)=split(/:/, $yrange);
	local($ymin)=shift(@tmp); local($ymax)=shift(@tmp);
	$ymax=$ymin unless $ymax;
	local($x, $y);
	$y=$ymin-1;
	do {
		$y++;
		$y=-1*$world{'height'}/2 if $y>=$world{'height'}/2;
		$x=$xmin-1;
		do {
			$x++;
			$x=-1*$world{'width'}/2 if $x>=$world{'width'}/2;
			push (@sects, "$x,$y") if $x%2==$y%2; 
		} until $x==$xmax;
	} until $y==$ymax;
	return @sects;
}

# todec converts 10K to 10000 and 10M to 10000000.  It is called in parse.pl,
# but I thought I should keep actual procedures out of parse.pl

sub todec {
	local($val)=@_;
	if ($val=~/(\d+\.?\d*)M/) {
		return $1*1000000;
	} elsif ($val=~/(\d+\.?\d*)K/) {
		return $1*1000;
	} else {
		return $val;
	} 
}

sub build_sect_target {
	local ($area) = @_;
	local ($x, $y);
	%target = ();

	$area = '*' unless $area;
	print STDERR "parsing dump $area...";
	print $main::S "dump $area\n";
	$main::command = 'dump';
	while (&getline) {
		@rec=split(/\s+/, $_);
		next if ($#rec<66);
		next if ("$rec[0]$rec[1]"!~/[0-9\-]+/);
		($x, $y)=($rec[0], $rec[1]);
		$target{"$x,$y"} = 1;
	}
	print STDERR "done\n";
}

sub build_ships_target {
	local ($ships) = @_;
	local ($id);
	%target = ();

	$ships = '*' unless $ships;
	print STDERR "parsing sdump $ships...";
	print $main::S "sdump $ships\n";
	$main::command = 'sdump';
	while (&getline) {
		next if (split(/\s+/, $_)<34);		# minimum elemetns in sdump output
		if (/^\s*(\d+)/) {
			($id)=$1;
			$target{$id} = 1;
		}
	}
	print STDERR "done\n";
}

sub build_lands_target {
	local ($lands) = @_;
	local ($id);
	%target = ();

	$lands = '*' unless $lands;
	print STDERR "parsing ldump $lands...";
	print $main::S "ldump $lands\n";
	$main::command = 'ldump';
	while (&getline) {
		next if (split(/\s+/, $_)<40);		# minimum elemetns in sdump output
		if (/^\s*(\d+)/) {
			($id)=$1;
			$target{$id} = 1;
		}
	}
	print STDERR "done\n";
}

sub print_n_parse {
	local ($line) = @_;
	print STDERR "parsing $line...";
	&main::parse_commandline($line.' >/dev/null');
	print STDERR "done\n";
}


 sub letter_init {
 # Put this in any init (such as find_country_number) or maybe I'll add 
 #  &deity_init for deity stuff.
 
	 # Adding in single letter country desig here, used in dmap
 
	 local(%used, @tmp);
	 local($done)=0;
	 (@tmp)=keys %country;
	 $y=0;
	 while(!$done) {
		 while($#tmp>-1) {
			 $x=pop(@tmp);
			 next if $deity{$x};
			 if ($y>length($country{$x})-1) {
				 push(@impossible, $x);
				 next;
			 }
			 $test=&toupper(substr($country{$x},$y,1));
			 if (!defined($used{$test})) {
				 $letter{$x}=$test;
				 $used{$test}=1;
			 } else {
				 if (!defined($used{&tolower(substr($country{$x},$y,1))})) {
					 $test=&tolower(substr($country{$x},$y,1));
					 if (!defined($used{$test})) {
						 $letter{$x}=$test;
						 $used{$test}=1;
					 }
				 } else {
					 push(@tmp2, $x); 
				 }
			 }
		 }
		 @tmp=@tmp2 unless $#tmp2==-1;
		 undef(@tmp2);
		 $done=1 unless $#tmp>-1;
		 $y++;
	 }
	 if ($#impossible>-1) {
		 local($every)="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
		 foreach $tmp (values %letter) {
			 $every=~s/$tmp//;
		 }
		 local(@every)=split(//, $every);
		 while($#impossible>-1) {
			 $tmp=shift(@impossible);
			 $letter{$tmp}=shift(@every);
		 } 
	 }
	 if (defined($mycounnum)) {
		 print STDERR "Your country number is $mycounnum\n";
		 $main::coun=$mycounnum;
		 return;
	 }
 }
 
 
 $main::functionmap{'cmap'}='&tools_cmap';
 
 sub tools_cmap {
	 local(@row, $pad, %onmap, $c, @list, $tmp, $line);
 
	 local ($area) = $main::commandarg;
	 &print_n_parse("realm");
	 if ($area =~ /#(\d{1,2})/) {
		 $area = $realm{$1};
	 } elsif ($area eq '*') {
		 $area=join('', "-", $world{'width'}/2, ":", $world{'width'}/2-1, ",-", $world{'height'}/2, ":", $world{'height'}/2-1);
	 } else {
		 $area = $realm{0};
	 }
	 &print_n_parse("bmap $area");
	 &print_n_parse("cen $area");
	 local($xrange, $yrange)=($area=~/(\S+),(\S+)/);
	 local(@tmp)=split(/:/, $xrange);
	 $xmin=shift(@tmp); $xmax=shift(@tmp);
	 $xmax=$xmin unless $xmax;
	 local(@tmp)=split(/:/, $yrange);
	 $ymin=shift(@tmp); $ymax=shift(@tmp);
	 $ymax=$ymin unless $ymax;
 
	 $pad=substr("          ",0,length($world{'height'}/2)+1);
	 $x=$xmin-1;
	 do {
		 $x++;
		 if ($x>$world{'width'}/2-1) { print "after right x\n"; $x=$world{'width'}/2*-1; }
		 $xx=join("",substr("        ",0,length($world{'width'}/2)+1-length($x)),$x);
		 for($w=length($world{'width'}/2)+1;$w>=0; $w--) {
			 $row[$w].=substr($xx,$w,1);
		 }
	 } until $x==$xmax;
	 for($w=0;$w<length($world{'width'}/2)+1; $w++) {
		 $row[$w]="$pad $row[$w]";
		 print "$row[$w]\n";
	 }
	 $y=$ymin-1;
	 do {
		 $y++;
		 $y=-1*$world{'height'}/2 if $y>$world{'height'}/2-1; 
		 $x=$xmin-1;
		 $pad=substr("         ",0,length($world{'height'}/2)+1-length($y));
		 do {
			 $x++;
			 $x=-1*$world{'width'}/2 if $x>$world{'width'}/2-1; 
			 if (defined($dump{$x, $y}{"des"})) {
				 if ($dump{$x, $y}{'own'}==0 || $dump{$x, $y}{'own'}==$main::coun) {
					 $line.=$dump{$x, $y}{"des"};
				 } else {
					 $line.=$letter{$dump{$x, $y}{'own'}};
					 $onmap{$dump{$x, $y}{'own'}}=1;
				 }
			 } else {
				 if (defined($dump{$x, $y}{'bdes'})) {
					 $line.=$dump{$x, $y}{'bdes'};
				 } else {
					 $line.=" ";
				 }
			 }
		 } until $x==$xmax;
		 print "$pad$y $line $y\n";
		 $pad=""; $line=""; 
	 } until $y==$ymax;
	 for($w=0;$w<length($world{'width'}/2)+1; $w++) {
		 print "$row[$w]\n";
	 }
	 foreach $c (keys %onmap) {
		 push(@list, sprintf("%15s=%s",$country{$c}, $letter{$c}));
	 }
	 while($#list>-1) {
		 $line= pop(@list) . pop(@list) . pop(@list) . pop(@list);
		 print "$line\n";
	 }
 
 }
	 
 $main::functionmap{'nmap'}='&tools_nmap';
 
 sub tools_nmap {
	 local(@row, $pad, %onmap, $c, @list, $tmp, $line);
 
	 local ($area) = $main::commandarg;
	 &print_n_parse("realm");
	 if ($area =~ /#(\d{1,2})/) {
		 $area = $realm{$1};
	 } elsif ($area eq '*') {
		 $area=join('', "-", $world{'width'}/2, ":", $world{'width'}/2-1, ",-", $world{'height'}/2, ":", $world{'height'}/2-1);
	 } else {
		 $area = $realm{0};
	 }
	 &print_n_parse("bmap $area");
	 &print_n_parse("cen $area");
	 &print_n_parse("dump $area");
	 local($xrange, $yrange)=($area=~/(\S+),(\S+)/);
	 local(@tmp)=split(/:/, $xrange);
	 $xmin=shift(@tmp); $xmax=shift(@tmp);
	 $xmax=$xmin unless $xmax;
	 local(@tmp)=split(/:/, $yrange);
	 $ymin=shift(@tmp); $ymax=shift(@tmp);
	 $ymax=$ymin unless $ymax;
 
	 $pad=substr("          ",0,length($world{'height'}/2)+1);
	 $x=$xmin-1;
	 do {
		 $x++;
		 if ($x>$world{'width'}/2-1) { print "after right x\n"; $x=$world{'width'}/2*-1; }
		 $xx=join("",substr("        ",0,length($world{'width'}/2)+1-length($x)),$x);
		 for($w=length($world{'width'}/2)+1;$w>=0; $w--) {
			 $row[$w].=substr($xx,$w,1);
		 }
	 } until $x==$xmax;
	 for($w=0;$w<length($world{'width'}/2)+1; $w++) {
		 $row[$w]="$pad $row[$w]";
		 print "$row[$w]\n";
	 }
	 $y=$ymin-1;
	 do {
		 $y++;
		 $y=-1*$world{'height'}/2 if $y>$world{'height'}/2-1; 
		 $x=$xmin-1;
		 $pad=substr("         ",0,length($world{'height'}/2)+1-length($y));
		 do {
			 $x++;
			 $x=-1*$world{'width'}/2 if $x>$world{'width'}/2-1; 
			 if (defined($dump{$x, $y}{"sdes"})) {
				 if ($dump{$x, $y}{'own'}==0 || $dump{$x, $y}{'own'}==$main::coun) {
					 if ($dump{$x, $y}{'sdes'} eq '_') {
						 $line .= $dump{$x, $y}{'des'};
					 } else {
							$line.=$dump{$x, $y}{"sdes"};
					 }
				 } else {
					 $line.=$letter{$dump{$x, $y}{'own'}};
					 $onmap{$dump{$x, $y}{'own'}}=1;
				 }
			 } else {
				 if (defined($dump{$x, $y}{'bdes'})) {
					 $line.=$dump{$x, $y}{'bdes'};
				 } else {
					 $line.=" ";
				 }
			 }
		 } until $x==$xmax;
		 print "$pad$y $line $y\n";
		 $pad=""; $line=""; 
	 } until $y==$ymax;
	 for($w=0;$w<length($world{'width'}/2)+1; $w++) {
		 print "$row[$w]\n";
	 }
	 foreach $c (keys %onmap) {
		 push(@list, sprintf("%15s=%s",$country{$c}, $letter{$c}));
	 }
	 while($#list>-1) {
		 $line= pop(@list) . pop(@list) . pop(@list) . pop(@list);
		 print "$line\n";
	 }
 
 }
	 
 sub tolower {
	 local($in)=@_;
	 local($out, $c, $x);
	 local(%alpha)=('A','a','B','b','C','c','D','d','E','e','F','f','G','g','H','h','I','i','J','j','K','k','L','l','M','m','N','n','O','o','P','p','Q','q','R','r','S','s','T','t','U','u','V','v','W','w','X','x','Y','y','Z','z','1','1','2','2','3','3','4','4','5','5','6','6','7','7','8','8','9','9','0','0');
	 $out="";
	 for($x=0;$x<length($in);$x++) {
		 $c=substr($in,$x,1);
		 if ($alpha{$c}) {
			 $out.=$alpha{$c};
		 } else {
			 $out.=$c;
		 }
	 }
	 return $out;
 }
 sub toupper {
	 local($in)=@_;
	 local($out, $c, $x);
	 local(%alpha)=('a','A','b','B','c','C','d','D','e','E','f','F','g','G','h','H','i','I','j','J','k','K','l','L','m','M','n','N','o','O','p','P','q','Q','r','R','s','S','t','T','u','U','v','V','w','W','x','X','y','Y','z','Z','1','1','2','2','3','3','4','4','5','5','6','6','7','7','8','8','9','9','0','0');
	 $out="";
	 for($x=0;$x<length($in);$x++) {
		 $c=substr($in,$x,1);
		 if ($alpha{$c}) {
			 $out.=$alpha{$c};
		 } else {
			 $out.=$c;
		 }
	 }
	 return $out;
 }
 

$main::tools_loaded = 1;
