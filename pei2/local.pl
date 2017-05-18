# $Id: local.pl,v 2.9.3.1 1997/06/08 20:09:50 root Exp root $
#
#                       Perl Empire Interface Local Commands
#
#                           Written by Ken Stevens
#
# DESCRIPTION:
# This perl module contains all of the functions which process pei commands
# that the user is allowed to type at the Local% prompt (i.e. when they have
# not yet connected to a game).
#
# INSTALLATION:
# You do not need to do anything to install local.pl.  It will be automatically
# included into pei when you connect to a game.  Just make sure that it
# is in the same directory as pei when pei is run.  Or you can put local.pl
# in the directory ~/perl and add the following line to your ~/.login file:
#   setenv PERLLIB ~/perl
#
# Type "help local" from within pei for the syntax of local commands,
# or read the file help.local that comes with pei.
#
# BUG REPORTS:
# mail your bug-reports and comments to:
# Sam Tetherow <tetherow@nol.org>
#
#       --- Global variables ---
#
# $alias{"command"} User-defined aliases
# $lcommand{"command"} = "&function"
#                   When player types local "command" call &function.
# @expanded         Expanded aliases (prevents infinite recursion)
# $quiet            Don't print commands read from files (set to 1 for .peirc)
# $terse            Run tools with terse output?
# *UNTERSEOUT       Where to send output when not running a tool.
# $proxyhost        Name of the proxy server
# $proxyport        Port to connect to on the proxy server
# $proxyprompt      Prompt that triggers us to send address of server
# $firewall         Boolean Flag Used to Indicate if Firewall Exists.

#     --- Functions ---
# For a description of what the various functions in this module do,
# type "help local" from within pei, or read the file "help.local".
#
# local_init        Set the %lcommand associative array.
# print_alias       Print an alias.
# get_country       Get a country name and representative.

sub local_init {
  $lcommand{'help'} = '&help';
  $lcommand{'addgame'} = '&addgame';
  $lcommand{'games'} = '&games';
  $lcommand{'try'} = '&try';
  $lcommand{'kill'} = '&kill';
  $lcommand{'trykill'} = '&kill';
  $lcommand{'echo'} = '&echo';
  $lcommand{'alias'} = '&alias';
  $lcommand{'unalias'} = '&unalias';
  $lcommand{'terse'} = '&terse';
  $lcommand{'quiet'} = '&quiet';
  $lcommand{'firewall'} = '&firewall';
  $lcommand{'exit'} = '&do_exit';
  $lcommand{'bye'} = '&do_exit';
  $lcommand{'reload'} = '&load_tools';
}

sub help {
  local (*MORE, *HELPFILE);

  if ($commandarg ne "pei" &&
      $commandarg ne "tools" &&
      $commandarg ne "local") {
    print <<'EOF';
  Help is available for the following subjects:
    help pei      - pei syntax
    help local    - local commands
    help tools    - pei tools
EOF
  return;
  }
  
  if (!open(MORE, "|$PAGER")) {
    print STDERR "Unable to run your PAGER \"$PAGER\".\n";
    return;
  }
  if (!open(HELPFILE, "<$PEIPATH/help.$commandarg")) {
    print STDERR "Unable to open \"$PEIPATH/help.$commandarg\" for input.\n";
    return;
  }
  while (<HELPFILE>) { print MORE; }
  close HELPFILE;
  close MORE;
}

sub addgame {
  local ($name, $rest) = split(/\s+/, $commandarg, 2);
  if ($name =~ /^\w+$/) {
    $lcommand{$name} = "\&set_game(\"$name\")";
    $games{$name} = eval(''.&quotify($rest));
  } else {
    print STDERR "Invalid game name: \"$name\"\n";
  }
} 

# print a list of games they can connect to
sub games {
  local ($dir, @_);

  printf "%8s %-14s %-10s %20s %6s %-14s\n", "name", "country", "password",
  "host", "port", "directory";
  print "-----------------------------------------------------------------------------\n";
  for $g (sort keys %games) {
    my($c, $r, $h, $p, $d) = split(/\s+/, $games{$g}); # values of %games are separated by whitespace
    $dir = eval(''.&quotify($d));
    $dir =~ s/^$ENV{'HOME'}/~/; # replace home directory with ~
    if (length($dir) > 14) {
      $dir = "..." . substr($dir,-11);
    }
    printf "%8s %-14s %-10s %20s %6s %-14s\n",$g,
    $c, $r, eval(''.&quotify($h)), eval(''.&quotify($p)), $dir;
  }
}

sub try {
  &set_game($commandarg);
  &get_country;		# ask user for country name and password
  $game = $commandarg."_".$country;
}

sub kill {
  local ($gamesav);

  if ($games{$commandarg}) {	# if the second word is a game name
    $gamesav = $game;
    &set_game($commandarg, 1);	# chdir and set coun, rep, host, port
    if ($command eq "trykill") {
      &get_country;	# ask user for country name and password
    }
  } else {
    print "No such game: $commandarg\n";
    return;
  }

  if ($S = $socket{$game}) {
    print "Sending quit to $game\n";
    print $S "quit\n";
    &close_connection(1);
  } else {
    if (&connect_to_server) {	# login to the host
      print $S "kill\n";	# kill our process
      $mode = -1;
      $_ = &sock'S_read($S, $TIMEOUT);
      print;
    } else {
      print STDERR "Connection failed.\n";
    }
    &close_connection;
  }
  &set_game($gamesav);
}

# This function is used by the "try" and "trykill" functions.  It reads a
# country name and password from the user.
sub get_country {
  $country = &line_prompt("Country:");
  $representative = &line_prompt("Representative:");
}

# Print text to the terminal.
sub echo {
  print eval(''.&quotify($commandarg)) . "\n";
}

# Either set an alias, show an alias, or show all aliases
sub alias {
# Either set $name and $val, just $name, or nothing depending on $commandarg
  local ($name,$val) = ($commandarg =~ /^(\S*)\s*((\S+(\s+\S+)*)*)/);
  if ($val) {
    $val =~ s/\$([0-9]+)/\@_[$1]/g;           # convert $1 to @_[1]
    $val =~ s/\${([0-9]+)}/\@{_[$1]}/g;       # convert ${1} to @{_[1]}
    $alias{$name} = $val;
  }
  elsif ($name) {	# if only name is specified, show the alias
    if ($alias{$name}) {
      &print_alias($name);
    } else {
      print "$name undefined.\n";
    }
  }
  else {
    foreach $name (sort(keys %alias)) { # show all aliases
      &print_alias($name);
    }
  }
}

# Print one alias.  This function converts aliases back into what they
# would have looked like when the user typed them in.
sub print_alias {
  local($name) = @_;
  local($val) = $alias{$name};
  $val =~ s/\@_\[([0-9]*)\]/\$$1/g;             # convert @_[1] to $1
  $val =~ s/\@{_\[([0-9]*)\]}/\${$1}/g;         # convert @_{[1]} to ${1}
  print "alias $name " . &quotify($val) . "\n"; # \ escape quotes
}

# Remove an alias
sub unalias {
  if ($alias{$commandarg}) {
    delete $alias{$commandarg};
    print "Alias \'$commandarg\' deleted.\n";
  } else {
    print "Alias \'$commandarg\' not found.\n";
  }
}

sub terse {
  $terse = !$terse;
  print "Terse mode ".($terse?"on":"off")."\n";
  if ($terse) {
    if (!open(DEVNULL,">/dev/null")) {
      die "Unable to open /dev/null for output.\n";
    }
  }
}

sub quiet {
  $quiet = !$quiet;
  print "Quiet mode ".($quiet?"on":"off")."\n";
}

sub firewall {
  print STDERR "Entering Firewall Mode!\n\n";
  $firewall = 1;
  ($proxyhost,$proxyport,$proxyprompt)=split(/\s+/,$commandarg,3);
  $proxyprompt =~ s/.*"(.*)".*/"$1"/e; #Only keep what's between the quotes.
}

$local_loaded = 1;
