# simu.pl was written by Drake Diedrich, and automatically converted to work
# with pei using $Id: simu.pl,v 2.9.3.1 1997/06/08 20:09:50 root Exp root $

$main'functionmap{'simu'}='&tools_simu'; #'
# $Id: simu.pl,v 2.9.3.1 1997/06/08 20:09:50 root Exp root $
#
# Update simulator for hpc/pei
#


# order as per global/item.c.

sub tools_simu {
  local($area);
  $area = $main'commandarg; #'
  $area = '*' unless $area;
  &build_sect_target($area);
  &print_n_parse("dump *") unless $area eq '*';
  &print_n_parse("prod *");
  &print_n_parse("neweff *");
  &print_n_parse("ship *");
  &print_n_parse("plane *");
  &print_n_parse("land *");

  local (%dump) = %dump;
  local (%uniteff) = %uniteff;
  local (%shipeff) = %shipeff;
  local (%planeeff) = %planeeff;

  local (%imported,%exported,%start,%produce,%consume,%delta,%net);


  local (@sectorder,@tmp);
  foreach $sect (keys %own) {
    if ($own{$sect}==$coun) {
      push(@tmp,$sect);
    }
  }
  @sectorder = sort sortsect @tmp;

  foreach $comm (keys %weight) {
    foreach $sect (@sectorder) {
      if ($dump{$sect,$comm}>0) {
        $start{$comm} += $dump{$sect,$comm};
      }
    }
  }
  $start{"tech"} = $tech{$coun} if ($tech{$coun}>0);
  $start{"medic"} = $res{$coun} if ($res{$coun}>0);
  $start{"edu"} = $edu{$coun} if ($edu{$coun}>0);
  $start{"happy"} = $hap{$coun} if ($hap{$coun}>0);

  &unitupdate;
  &shipupdate;
  &planeupdate;
  &sectupdate;

  &distexport;
  &distimport;

  foreach $comm (keys %produce) {
    if ($produce{$comm}>0) {
      $start{$comm}=0 unless defined($start{$comm});
    }
  }
  foreach $comm (keys %consume) {
    if ($consume{$comm}) {
      $start{$comm}=0 unless defined($start{$comm});
    }
  }

  $consume{"tech"} = $start{"tech"} * $level_decay_rate;
  $consume{"medic"} = $start{"medic"} * $level_decay_rate;

  foreach $comm (keys %start) {
    $delta{$comm} = $produce{$comm} - $consume{$comm};
    $net{$comm} = $start{$comm} + $produce{$comm} - $consume{$comm};
  }

  if ($produce{"tech"} > $easytech) {
    $delta{"tech"} = $easytech + 
      log($produce{"tech"}-$easytech+1)/log($logtech);
    $net{"tech"} = $start{"tech"} + $delta{"tech"} - $consume{"tech"};;
  }

  if ($produce{"medic"} > 0.75) {
    $delta{"medic"} = 0.75 + 
      log($produce{"medic"}-0.75+1)/log(2.0);
    $net{"medic"} = $start{"medic"} + $delta{"medic"} - $consume{"medic"};;
  }

  if ($produce{"edu"}) {
    $delta{"edu"} = $produce{"edu"} * 4000 * int($etu/12) / $start{"civ"};
    if ($delta{"edu"}>5) {
      $delta{"edu"} = ($delta{"edu"}-5)/(log(1+$delta{"edu"})/log(4)) + 5;
    }
    $net{"edu"} = ($start{"edu"}*(192-$etu) + $delta{"edu"} * $etu)/192;
  }

  if ($produce{"happy"}) {
    $delta{"happy"} = $produce{"happy"} * 5000 * int($etu/12) / $start{"civ"};
    if ($delta{"happy"}>5) {
      $delta{"happy"} = ($delta{"happy"}-5)/(log(1+$delta{"happy"})/log(6)) + 5;
    }
    $net{"happy"} = ($start{"happy"}*(192-$etu) + $delta{"happy"} * $etu)/192;
  }



  print "  sect des eff mob make  imports        exports        commodities\n";
  foreach $sect (@sectorder) {
  
next if !$target{$sect};
    printf("%3d,%-3d %s %3d%% %3d",
           $dump{$sect,"x"},$dump{$sect,"y"},
           $dump{$sect,"des"},$dump{$sect,"eff"},$dump{$sect,"mob"});
  
    if (defined($will{$sect})) {
      printf(" %4s",$will{$sect} . substr($make{$sect},0,1));
      printf(" ") if (length($will{$sect} . "a") < 5);
    } elsif ($dump{$sect,"avail"}>0) {
      printf(" %3da ",$dump{$sect,"avail"});
    } else {
      print "      ";
    }
  
    $impstr="";
    foreach $comm (keys %weight) {
      if ($imported{$sect,$comm}>0) {
        $impstr .= sprintf(" %d%s",$imported{$sect,$comm},substr($comm,0,1));
      }
    }
    printf("%-14s ",$impstr);
     
    $expstr="";
    foreach $comm (keys %weight) {
      if ($exported{$sect,$comm}>0) {
          $expstr .= sprintf(" %d%s",$exported{$sect,$comm},substr($comm,0,1));
      }
    }
    printf("%-14s ",$expstr);
      
    {
      local ($thresh);
      foreach $comm (keys %weight) {
        if ($dump{$sect,$comm}>0) {
          printf(" %d%s",$dump{$sect,$comm},substr($comm,0,1));
          $thresh = $dump{$sect,substr($comm,0,1) . "_dist"};
          if ($thresh>0) {
            print "+" if $dump{$sect,$comm} > $thresh;
            print "-" if $dump{$sect,$comm} < $thresh;
          }
        }
      }
    }
    print "\n";
  }




}


sub sortsect {
  local (@a, @b);
  @a = split(',',$a);
  @b = split(',',$b);
  ($a[1] <=> $b[1]) || ($a[0] <=> $b[0]);
}

sub sectupdate {

  foreach $sect (@sectorder) {
    if (!defined($option{"NOFOOD"})) {
      $eat = ($dump{$sect,"civ"}+$dump{$sect,"mil"}+$dump{$sect,"uw"}) * $etu * $eatrate;
      $eat += 2*($dump{$sect,"civ"}*$obrate + $dump{$sect,"uw"}*$uwbrate) * $etu * $babyeat;
      $dump{$sect,"food"} -= int($eat);
      $consume{"food"} += $eat;
    }
    if ($dump{$sect,"food"} < -1) {
      printf("** Warning: need %d more food in %s **\n",-$dump{$sect,"food"},$sect) if $verbose;
      $dump{$sect,"work"}=0;
      if (defined($option{"NEW_STARVE"})) {
        local ($starve);
        $starve = -$dump{$sect,"food"} / $etu / $eatrate;
        if ($starve * 2 >
            $dump{$sect,"uw"} + $dump{$sect,"civ"} + $dump{$sect,"mil"}) {
          $starve = int(($dump{$sect,"uw"} + $dump{$sect,"civ"} +
                         $dump{$sect,"mil"})/2);
        }
        if ($starve <= $dump{$sect,"uw"}) {
          $dump{$sect,"uw"} -= $starve;
          $consume{"uw"} += $starve;
        } else {
          $starve -= $dump{$sect,"uw"};
          $consume{"uw"} += $dump{$sect,"uw"};
          $dump{$sect,"uw"}=0;
          if ($starve <= $dump{$sect,"civ"}) {
            $dump{$sect,"civ"} -= $starve;
            $consume{"civ"} += $starve;
          } else {
            $starve -= $dump{$sect,"civ"};
            $consume{"civ"} += $dump{$sect,"civ"};
            $dump{$sect,"civ"} = 0;
            $consume{"mil"} += $starve;
            $dump{$sect,"mil"} -= $starve;
          }
        }
      } else {
        $consume{"civ"} += $dump{$sect,"civ"}/2;
        $consume{"mil"} += $dump{$sect,"mil"}/2;
        $consume{"uw"} += $dump{$sect,"uw"}/2;
        $dump{$sect,"civ"} /= 2;
        $dump{$sect,"mil"} /= 2;
        $dump{$sect,"uw"} /= 2;
      }
    } else {
      $produce{"civ"} -= $dump{$sect,"civ"};
      $produce{"uw"} -= $dump{$sect,"uw"};
      $dump{$sect,"civ"} += int($dump{$sect,"civ"} * $etu * $obrate);
      $dump{$sect,"uw"} += int($dump{$sect,"uw"} * $etu * $uwbrate);
      $dump{$sect,"civ"} = $maxpop if ($dump{$sect,"civ"} > $maxpop);
      $dump{$sect,"uw"} = $maxpop if ($dump{$sect,"uw"} > $maxpop);
      $produce{"civ"} += $dump{$sect,"civ"};
      $produce{"uw"} += $dump{$sect,"uw"};
    }
  }


  foreach $sect (@sectorder) {
    $dump{$sect,'avail'} = ($dump{$sect,'civ'} * $dump{$sect,'work'}/100 + $dump{$sect,'uw'} + $dump{$sect,'mil'} * 0.4) * $etu / 100;
  }

  foreach $sect (keys %neweff) {
    if ($dump{$sect,'des'} ne $newdes{$sect}) {
      $dump{$sect,'avail'} -= $neweff{$sect}+$dump{$sect,'eff'}/4;
    } else {
      $dump{$sect,'avail'} -= $neweff{$sect}-$dump{$sect,'eff'};
    }
    $dump{$sect,"des"} = $newdes{$sect};
    $dump{$sect,"eff"} = $neweff{$sect};
  }
  foreach $sect (keys %will) {
    if ($will{$sect}+$dump{$sect,$make{$sect}} > 999) {
      $produce{$make{$sect}} += 999-$dump{$sect,$make{$sect}};
      $dump{$sect,$make{$sect}} = 999;
    } else {
      $produce{$make{$sect}} += $will{$sect};
      $dump{$sect,$make{$sect}} += $will{$sect};
    }
  }

  foreach $sect (keys %use1) {
    $consume{$comm1{$sect}} += $use1{$sect};
    $dump{$sect,$comm1{$sect}} -= $use1{$sect};
  }
  foreach $sect (keys %use2) {
    $consume{$comm2{$sect}} += $use2{$sect};
    $dump{$sect,$comm2{$sect}} -= $use2{$sect};
  }
  foreach $sect (keys %use3) {
    $consume{$comm3{$sect}} += $use3{$sect};
    $dump{$sect,$comm3{$sect}} -= $use3{$sect};
  }


}


sub unitupdate {
  local ($sect,$bcost,$lcm,$hcm,$mil,$gun,$shell,$avail);
  foreach $n (sort { $a <=> $b } keys %unitname) {
    $sect = $unitsect{$n};
    if ($dump{$sect, 'des'} eq '!') {
      $bcost = 100 - $uniteff{$n};
      if ($bcost > $uniteff) {
        $bcost = $uniteff;
      }

      $lcm = $bcost * $buildlcm{$unitname{$n}} / 100;
      if ($lcm > $dump{$sect,"lcm"}) {
        $bcost = 100 * $dump{$sect,'lcm'} / $buildlcm{$unitname{$n}}
      }

      $hcm = $bcost * $buildhcm{$unitname{$n}} / 100;
      if ($hcm > $dump{$sect,"hcm"}) {
        $bcost = 100 * $dump{$sect,'hcm'} / $buildhcm{$unitname{$n}}
      }

      $mil = $bcost * $buildmil{$unitname{$n}} / 100;
      if ($mil > $dump{$sect,"mil"}) {
        $bcost = 100 * $dump{$sect,'mil'} / $buildmil{$unitname{$n}}
      }

      $gun = $bcost * $buildgun{$unitname{$n}} / 100;
      if ($gun > $dump{$sect,"gun"}) {
        $bcost = 100 * $dump{$sect,'gun'} / $buildgun{$unitname{$n}}
      }

      $shell = $bcost * $buildshell{$unitname{$n}} / 100;
      if ($shell > $dump{$sect,"shell"}) {
        $bcost = 100 * $dump{$sect,'shell'} / $buildshell{$unitname{$n}}
      }

      $avail = $bcost * (20 + $buildlcm{$unitname{$n}} + 2 * $buildhcm{$unitname{$n}}) / 100;
      if ($avail > $dump{$sect,"avail"}) {
        $bcost = 100 * $dump{$sect,'avail'} /
          (20 + $buildlcm{$unitname{$n}} + 2 * $buildhcm{$unitname{$n}});
      }
      
      $dump{$sect,"lcm"} -= $bcost * $buildlcm{$unitname{$n}} / 100;
      $dump{$sect,"hcm"} -= $bcost * $buildhcm{$unitname{$n}} / 100;
      $dump{$sect,"mil"} -= $bcost * $buildmil{$unitname{$n}} / 100;
      $dump{$sect,"gun"} -= $bcost * $buildgun{$unitname{$n}} / 100;
      $dump{$sect,"shell"} -= $bcost * $buildshell{$unitname{$n}} / 100;
      $dump{$sect,"avail"} -= $bcost * (20 + $buildlcm{$unitname{$n}} +
                                        2 * $buildhcm{$unitname{$n}}) / 100;

      $consume{"lcm"} += $bcost * $buildlcm{$unitname{$n}} / 100;
      $consume{"hcm"} += $bcost * $buildhcm{$unitname{$n}} / 100;
      $consume{"mil"} += $bcost * $buildmil{$unitname{$n}} / 100;
      $consume{"gun"} += $bcost * $buildgun{$unitname{$n}} / 100;
      $consume{"shell"} += $bcost * $buildshell{$unitname{$n}} / 100;

      $uniteff{$n} += $bcost;

    }
  }
}

sub shipupdate {
  local ($sect,$bcost,$lcm,$hcm,$mil,$gun,$shell,$avail);
  foreach $n (sort keys %shipname) {
    $sect = $shipsect{$n};
    if ($dump{$sect, 'des'} eq 'h') {
      $bcost = 100 - $shipeff{$n};
      if ($bcost > $maxshipeff) {
        $bcost = $maxshipeff;
      }

      $lcm = $bcost * $buildlcm{$shipname{$n}} / 100;
      if ($lcm > $dump{$sect,"lcm"}) {
        $bcost = 100 * $dump{$sect,'lcm'} / $buildlcm{$shipname{$n}}
      }

      $hcm = $bcost * $buildhcm{$shipname{$n}} / 100;
      if ($hcm > $dump{$sect,"hcm"}) {
        $bcost = 100 * $dump{$sect,'hcm'} / $buildhcm{$shipname{$n}}
      }

      $mil = $bcost * $buildmil{$shipname{$n}} / 100;
      if ($mil > $dump{$sect,"mil"}) {
        $bcost = 100 * $dump{$sect,'mil'} / $buildmil{$shipname{$n}}
      }

      $gun = $bcost * $buildgun{$shipname{$n}} / 100;
      if ($gun > $dump{$sect,"gun"}) {
        $bcost = 100 * $dump{$sect,'gun'} / $buildgun{$shipname{$n}}
      }

      $shell = $bcost * $buildshell{$shipname{$n}} / 100;
      if ($shell > $dump{$sect,"shell"}) {
        $bcost = 100 * $dump{$sect,'shell'} / $buildshell{$shipname{$n}}
      }

      $avail = $bcost * (20 + $buildlcm{$shipname{$n}} + 
                         2 * $buildhcm{$shipname{$n}}) / 100;
      if ($avail > $dump{$sect,"avail"}) {
        $bcost = 100 * $dump{$sect,'avail'} /
          (20 + $buildlcm{$shipname{$n}} + 2 * $buildhcm{$shipname{$n}});
      }

      $dump{$sect,"lcm"} -= $bcost * $buildlcm{$shipname{$n}} / 100;
      $dump{$sect,"hcm"} -= $bcost * $buildhcm{$shipname{$n}} / 100;
      $dump{$sect,"mil"} -= $bcost * $buildmil{$shipname{$n}} / 100;
      $dump{$sect,"gun"} -= $bcost * $buildgun{$shipname{$n}} / 100;
      $dump{$sect,"shell"} -= $bcost * $buildshell{$shipname{$n}} / 100;
      $dump{$sect,"avail"} -= $bcost * (20 + $buildlcm{$shipname{$n}} +
                                        2 * $buildhcm{$shipname{$n}}) / 100;

      $consume{"lcm"} += $bcost * $buildlcm{$shipname{$n}} / 100;
      $consume{"hcm"} += $bcost * $buildhcm{$shipname{$n}} / 100;
      $consume{"mil"} += $bcost * $buildmil{$shipname{$n}} / 100;
      $consume{"gun"} += $bcost * $buildgun{$shipname{$n}} / 100;
      $consume{"shell"} += $bcost * $buildshell{$shipname{$n}} / 100;

      $shipeff{$n} += $bcost;

    }
  }
}

# doesn't check for carrier work yet. 
sub planeupdate {
  local ($sect,$bcost,$lcm,$hcm,$mil,$gun,$shell,$avail);
  foreach $n (sort keys %planename) {
    $sect = $planesect{$n};
    if ($dump{$sect, 'des'} eq '*') {
      $bcost = 100 - $planeeff{$n};
      if ($bcost > $planeeff) {
        $bcost = $planeeff;
      }

      $lcm = $bcost * $buildlcm{$planename{$n}} / 100;
      if ($lcm > $dump{$sect,"lcm"}) {
        $bcost = 100 * $dump{$sect,'lcm'} / $buildlcm{$planename{$n}}
      }

      $hcm = $bcost * $buildhcm{$planename{$n}} / 100;
      if ($hcm > $dump{$sect,"hcm"}) {
        $bcost = 100 * $dump{$sect,'hcm'} / $buildhcm{$planename{$n}}
      }

      $mil = $bcost * $buildmil{$planename{$n}} / 100;
      if ($mil > $dump{$sect,"mil"}) {
        $bcost = 100 * $dump{$sect,'mil'} / $buildmil{$planename{$n}}
      }

      $gun = $bcost * $buildgun{$planename{$n}} / 100;
      if ($gun > $dump{$sect,"gun"}) {
        $bcost = 100 * $dump{$sect,'gun'} / $buildgun{$planename{$n}}
      }

      $shell = $bcost * $buildshell{$planename{$n}} / 100;
      if ($shell > $dump{$sect,"shell"}) {
        $bcost = 100 * $dump{$sect,'shell'} / $buildshell{$planename{$n}}
      }

      $avail = $bcost * (20 + $buildlcm{$planename{$n}} +
                         2 * $buildhcm{$planename{$n}}) / 100;
      if ($avail > $dump{$sect,"avail"}) {
        $bcost = 100 * $dump{$sect,'avail'} /
          (20 + $buildlcm{$planename{$n}} + 2 * $buildhcm{$planename{$n}});
      }

      $dump{$sect,"lcm"} -= $bcost * $buildlcm{$planename{$n}} / 100;
      $dump{$sect,"hcm"} -= $bcost * $buildhcm{$planename{$n}} / 100;
      $dump{$sect,"mil"} -= $bcost * $buildmil{$planename{$n}} / 100;
      $dump{$sect,"gun"} -= $bcost * $buildgun{$planename{$n}} / 100;
      $dump{$sect,"shell"} -= $bcost * $buildshell{$planename{$n}} / 100;
      $dump{$sect,"avail"} -= $bcost * (20 + $buildlcm{$planename{$n}} +
                                        2 * $buildhcm{$planename{$n}}) / 100;

      $consume{"lcm"} += $bcost * $buildlcm{$planename{$n}} / 100;
      $consume{"hcm"} += $bcost * $buildhcm{$planename{$n}} / 100;
      $consume{"mil"} += $bcost * $buildmil{$planename{$n}} / 100;
      $consume{"gun"} += $bcost * $buildgun{$planename{$n}} / 100;
      $consume{"shell"} += $bcost * $buildshell{$planename{$n}} / 100;

      $planeeff{$n} += $bcost;

    }
  }
}

sub distexport {
  local ($cost,$com,$lev);
  foreach $source (@sectorder) {
    $dest = $dump{$source,'dist_x'} . "," . $dump{$source,'dist_y'};
    $cost = &pathcost($source,$dest);
    if ($cost>1000) {
      print "Unable to find path from $source to $dest\n";
      next;
    }
    next if ($source eq $dest);
    foreach $c (@commo) {
      $comm=$dump{$source,$commstr{$c}};
      $lev=$dump{$source,$c . "_dist"};
      if ($lev>0 && $comm>$lev) {
        $move=$comm-$lev;
        $tmp = 9990-$dump{$dest,$commstr{$c}};
        if ($tmp<$move) { $move = $tmp; }

        $mcost = $cost * $move/4;
        if (($dump{$dest,'des'} eq 'w' && $dump{$dest,"eff"}>=60) ||
            ($dump{$source,'des'} eq 'w' && $dump{$source,"eff"}>=60)) {
          $mcost /= $packing{$commstr{$c}};
        } elsif ($dump{$source,'des'} eq 'b' && $dump{$source,"eff"}>=60 &&
                 $c eq 'b') {
          $mcost /= 4;
        }

        if ($mcost > $dump{$source,"mob"}) {
          $move *= $dump{$source,"mob"}/$mcost;
          $mcost = $dump{$source,"mob"};
        }

        if ($move>0) {
          $dump{$source,$commstr{$c}} -= $move;
          $dump{$source,"mob"} -= $mcost;
          $dump{$dest,$commstr{$c}} += $move;
          $exported{$source,$commstr{$c}} += $move;
          $imported{$dest,$commstr{$c}} += $move;
        }
      }
    }
  }
}

sub distimport {
  local ($cost,$com,$lev);
  foreach $dest (@sectorder) {
    $source = $dump{$dest,'dist_x'} . "," . $dump{$dest,'dist_y'};
    $cost = &pathcost($source,$dest);
    if ($cost>1000) {
      print "Unable to find path from $source to $dest\n";
      next;
    }
    next if ($source eq $dest);
    foreach $c (@commo) {
      $comm=$dump{$dest,$commstr{$c}};
      $lev=$dump{$dest,$c . "_dist"};
      if ($lev>0 && $lev>$comm) {
        $move=$lev-$comm;
        $tmp = $dump{$source,$commstr{$c}};
        if ($tmp<$move) { $move = $tmp; }

        $mcost = $cost * $move/4;
        if (($dump{$dest,'des'} eq 'w' && $dump{$dest,"eff"}>=60) ||
            ($dump{$source,'des'} eq 'w' && $dump{$source,"eff"}>=60)) {
          $mcost /= $packing{$commstr{$c}};
        } elsif ($dump{$source,'des'} eq 'b' && $dump{$source,"eff"}>=60 &&
                 $c eq 'b') {
          $mcost /= 4;
        }

        if ($mcost > $dump{$source,"mob"}) {
          $move *= $dump{$source,"mob"}/$mcost;
          $mcost = $dump{$source,"mob"};
        }

        if ($move>0) {
          $dump{$source,$commstr{$c}} -= $move;
          $dump{$source,"mob"} -= $mcost;
          $dump{$dest,$commstr{$c}} += $move;
          $exported{$source,$commstr{$c}} += $move;
          $imported{$dest,$commstr{$c}} += $move;
        }
      }
    }
  }
}



sub pathcost {
    local($from, $to) = @_;
    local(%cost,%marked);


    $cost{$from} = 0;
    while (!(defined $cost{$to}) && &buildcost(*cost, *marked)) {
        ;
    }
    if (defined $cost{$to}) {
        return $cost{$to};
    }
    else {
        return 1e9;
    }
    9999;
}

print "Loaded simu.pl\n" if $verbose;
1;
$main'simu_loaded = 1
