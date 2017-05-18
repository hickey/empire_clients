# $Id: mail.pl,v 2.9.3.1 1997/06/08 20:09:50 root Exp root $
#                               mail.pl
#                      Perl Empire Interface Mailer
#
#                        Written by Ken Stevens
#
#
# DESCRIPTION:
# This module contains the following tools:
#
# mail,wmail   - mail-like interface for reading telegrams and announcements.
# tele,anno    - Use an editor to compose your telegram or announcement.
#
# The help for the mailer may be found at the bottom of this file.
# Just type '?' from within the mailer to get the help.
#
# INSTALLATION:
# You do not need to do anything to install mail.pl.  It will be automatically
# included into pei when you connect to a game.  Just make sure that it
# is in the same directory as pei when pei is run.  Or you can put mail.pl
# in the directory ~/perl and add the following line to your ~/.login file:
#   setenv PERLLIB ~/perl
#
# AUTHORS:
# Written by Ken Stevens
# tele, anno, forward, and reply based on ideas by Sam Tetherow
#
# BUG REPORTS:
# mail your bug-reports and comments to:
# tetherow@nol.org (Sam Tetherow)

#       --- Global variables ---
# @type   message type (PROD,BULL, or TELE)
# @mark   message mark (----,*, or author)
# @from   author
# @date   date message was written
# @lines  the number of lines in the message
# @subj   subject of message (money delta, attacker, or first line of tele)
# @status N=new, U=unread, r=replied to, D=deleted
# @header old header of the message
# @msg    the message body
#
#      --- Functions ---
#
# parse_header     parse the header of the telegram into type,mark,from,date
# read_mailfile    read and parse the entire mailfile
# print_headers    print the headers
# write_mailfile   save mail and status info to a file
# print_message    print an individual message
# process_delete   delete messages recursively
# save             save a telegram to a file
# create_tmp_file  create a file to edit that you're going to send
# post_it          chop and send the anno/tele to the server
# reply            reply to a tele/anno
# forward          post a reply to a tele/anno or forward to another user
# mail_prompt      print the prompt for the mailer
# reader           start up the mail/wmail reader
# mail_help        print help
# tele             use an editer to compose a tele/anno

package mail;

#########################  Mail parsing commands  #######################

$main'functionmap{'mail'}="&mail'reader";
$main'functionmap{'wmail'}="&mail'reader";

sub parse_header {
  if (/> Production Report\s+dated\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)/) {
    $type[$i] = 'PROD';
    $mark[$i] = '----';
    $from[$i] = 'Production';
    $date[$i] = "$1 $2 $3 $4";
  } elsif (/> BULLETIN\s+from\s+(\S+),\s+\(\#0\)\s+dated\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)/) {
    $type[$i] = 'BULL';
    $mark[$i] = '*';
    $from[$i] = $1;
    $date[$i] = "$2 $3 $4 $5";
  } elsif (/> Telegram\s+from\s+(\S+),\s+\((\#\d+)\)\s+dated\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)/) {
    $type[$i] = 'TELE';
    $mark[$i] = $2;
    $from[$i] = $1;
    $date[$i] = "$3 $4 $5 $6";
  } elsif (/>(.)Announcement\s+from\s+(\S+),\s+\((\#\d+)\)\s+dated\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)/) {
    $type[$i] = 'ANNO';
    $mark[$i] = $3;
    $from[$i] = $2;
    $date[$i] = "$4 $5 $6 $7";
    if ($1 eq '*') {
      $status[$i] = 'U';
    }
  } else {
    $type[$i] = 'UNKNOWN';
    $mark[$i] = 'UNKNOWN';
  }
  if (/\S $/) {		# message status is kept in trailing spaces
    $status[$i] = ' ';
  } elsif (/\S  $/) {
    $status[$i] = 'U';
    $current_message = $i if !$current_message && !$new_message;
  } elsif (/\S   $/) {
    $status[$i] = 'r';    
  } elsif (!$new_message) {
    $current_message = $i;
    $new_message = 1;
  }
  $header[$i] = $_;
  $header[$i] =~ s/ +$//; # remove trailing spaces
}

sub parse_line {
    next if /^read $/;
    next if /^y\n$/;
    next if /^You have a new telegram waiting ...$/;
    next if /^You have a new announcement waiting ...$/;
    next if /^Into the shredder, boss? y\n$/;
    next if /^No telegrams for you at the moment...$/;
    next if /^No announcements for you at the moment...$/;
    next if /^You lost your capital... better designate one$/;
    ++$lines[$i];
    $msg[$i] .= $_."\n";
    if ($type[$i] eq 'PROD') {
	if (/money delta was (\$-*\d+) for this update/) {
	    $subj[$i] = "money delta:  $1";
	}
    } elsif ($type[$i] eq 'BULL') {
	if (!$subj[$i]) {
	    if (/taking/ || /attacking/ || /assaulting/ || /\(\#\d+\)/) {
		$subj[$i] = substr($_,0,30);
	    }
	}
    } elsif (!$subj[$i]) {
	$subj[$i] = substr($_,0,30);
    }
}

sub reader {
  local($i,$new_message,$skip_message,$checked_mail,$n);
  local($current_message);
  local(@status,@type,@mark,@from,@date,@subj,@msg,@header,@lines);
  local($cnum);

  $cnum = " $main'coun" if $main'nstatus eq 'DEITY';
  if ($main'command eq "mail") { #'
    $ext="teles";
    $main'command = "read";
    if ($main'mailflag || $main'mailflag{$main'game}) { #JS
      print $main'S "read$cnum n\n"; #'
    } else {
      print $main'S "read$cnum y\n"; #'
    }
  } elsif ($main'command eq "wmail") { #'
    $ext="wires";
    $main'command = "wire";
    if ($main'mailflag || $main'mailflag{$main'game}) { #' #JS
      print $main'S "wire n\n"; #'
    } else {
      print $main'S "wire y\n"; #'
    }
  } else {
    print STDERR "Bad call to &reader\n";
    return;
  }

  open(MAILFILE, "< $main'game.$ext");	# open the mail file

  while (<MAILFILE>) {
    chop;
    if (/^>/) {  # line is a header
	++$i;
	&parse_header;
    } elsif ($i) {
	&parse_line;
    }
  }

  $current_message = 1 if !$current_message;
  close(MAILFILE);

  $checked_mail = $i;
  
  open(MAILFILE, ">> $main'game.$ext");
  $skip_message = 1;
  while(&getline()) {
      if (/^>/) {  # line is a header
	  $skip_message=0;
        if ($main'mailflag || $main'mailflag{$main'game}) #' #JS
	  {
	    for ($n=$checked_mail; $n > 0 && !$skip_message; $n--) {
	      $skip_message = ($header[$n] eq $_); # 
				# This for loop checks all the localy
				# stored message headers to see
				# if the newly read in
				# header is a duplicate.
	    }
	  }
	  if (!$skip_message) {
	      $i++;
	      $status[$i] = 'N';
	      &parse_header;
	  }
      } elsif ($i && !$skip_message) {
	  &parse_line;
      }
      if (!$skip_message) {
	  print MAILFILE "$_\n";
      }
  }
  close(MAILFILE);

  if (!@msg) {
    print "No ".($ext eq "teles"?"telegrams":"announcements").
      " for you at the moment...\n";
    return;
  }
  &print_headers($current_message);
  if (&mail_prompt) {
    print "Saving changes to ".
      ($ext eq "teles"?"telegrams":"announcements")."...\n";
    &write_mailfile("$main'game.$ext");
  }
}

#######################  Mail reading commands  #######################

sub print_headers {
  local ($current_message) = @_;
  local ($m,$headstart);

  if ($#msg <= 20) {
    $headstart = 1;
  } else {
    $headstart = $current_message - 10;
    $headstart = 1 if $headstart < 1;
  }
  for ($m = $headstart; $m <= $#msg && $m < $headstart + 20; ++$m) {
    printf "%3d %s%s %4s %-12s %19s %-30s\n",
    $m,
    $m == $current_message?'>':' ',
    $status[$m],
    $mark[$m],
    $from[$m],
    $date[$m],
    $subj[$m];
  }
}

sub write_mailfile {
  local ($m);
  open(MAILFILE, '>'.pop(@_));	# open the mail file

  for ($m = 1; $m <= $#msg; ++$m) {
    next if $status[$m] eq 'D';
    if ($status[$m] eq ' ') {
      print MAILFILE $header[$m].' ';
    } elsif ($status[$m] eq 'r') {
      print MAILFILE $header[$m].'   ';
    } else {
      print MAILFILE $header[$m].'  ';
    }
    print MAILFILE "\n".$msg[$m];
  }
  close(MAILFILE);
}

sub print_message {
  print "Message #$m ($lines[$m] lines)\n";
  print $header[$m]."\n";
  if ($lines[$m] < 23) {
    print $msg[$m];
  } else {
    local (*MORE);
    if (open(MORE, "|$main'PAGER")) {
      print MORE $msg[$m];
      close MORE;
    } else {
      print $msg[$m];
    }
  }
  $status[$m] = ' ';
}

sub process_delete {
  local($undelete) = @_;
  local(@del, $m);

  sub new_status {
    $status[$m] = $undelete?($status[$m] eq 'D')?'U':$status[$m]:'D';
  }

  s/^ +//;
  s/ +$//;
  if (/ /) {
    for (split) {
      &process_delete($undelete);
    }
    return;
  }
  if (/^(\d+)-(\d+)$/) {
    if ($1 > $2 || $1 < 1 || $2 > $#msg) {
      print "Bad range: $1-$2\n";
    } else {
      for ($m = $1; $m <= $2; ++$m) {
	&new_status;
      }
    }
  } elsif (/^(\d+)/) {
    if ($1 < 1 || $1 > $#msg) {
      print "Bad message number: $1\n";
    } else {
      $m = $1;
      &new_status;
    }
  } elsif ($_ eq 'b') {
    for ($m = 1; $m <= $#msg; ++$m) {
      if ($type[$m] eq 'BULL') {
	&new_status;
      }
    }
  } elsif ($_ eq 't') {
    for ($m = 1; $m <= $#msg; ++$m) {
      if ($type[$m] eq 'TELE') {
	&new_status;
      }
    }
  } elsif ($_ eq 'p') {
    for ($m = 1; $m <= $#msg; ++$m) {
      if ($type[$m] eq 'PROD') {
	&new_status;
      }
    }
  } elsif ($_ eq '*') {
    for ($m = 1; $m <= $#msg; ++$m) {
      &new_status;
    }
  } else {
    print "Bad arg to ".($undelete?"undelete":"delete").": \'$_\'\n";
  }
}

sub save {
  local ($filename);

  s/^ +//;
  s/ +$//;
  if (/^[\/\.\w]+$/) {
    $filename = $_;
  } elsif (/^(\d+)\s+([\/\.\w]+)$/) {
    if ($1 < 1 || $1 > $#msg) {
      print "Bad message number: $1\n";
      return;
    } else {
      $m = $1;
      $filename = $2;
    }
  } else {
    print "Bad mail save syntax (perhaps your filename is a bit strange)\n";
    return;
  }
  open(SAVEFILE, ">".$filename);
  print SAVEFILE $header[$m]."\n".$msg[$m];
  close(SAVEFILE);
}

sub create_tmp_file {
  open(TMPFILE,">$filename");
  print TMPFILE "} On $date[$m] $from[$m] wrote:\n";
  for (split(/\n/,$msg[$m])) {
    print TMPFILE "} $_\n";
  }
  print TMPFILE "}-- End of excerpt from $from[$m]\n\n";
  close(TMPFILE);
}

sub save_it {
  local ($thing) = @_;

  open(RECORD, ">>$main'game.record");
  print RECORD "> $thing, dated " . `date`;
  close RECORD;

  system("cat $filename >> $main'game.record");
}

sub post_it {
  local ($cmd,$thing) = @_;
  local ($textin,$size,$textout);
  
  system("$main'EDITOR $filename");
  $_ = &main'line_prompt("Are you sure you want to send the $thing? (y/n)"); #'
  if ($_ ne "y" && $_ ne "Y") {
    print "$thing aborted.\n";
    &save_it($thing);
    system("rm -f $filename");
    return 0;
  }
  open(TMPFILE,"<$filename");
  while (<TMPFILE>) {
    $textin .= $_;
  }
  close(TMPFILE);
  &save_it($thing);
  system("rm -f $filename");
  $textout = $cmd;
  for (split(/\n/, $textin)) {
    $size += 1 + length;
    if ($size > 1024) {
      $textout .= ".\n$cmd";
      $size = 0;
    }
    $textout .= "$_\n";
  }
  $textout .= ".\n";
  $| = 1;
  print "Sending $thing...";
  for (split(/\n/, $textout)) {
    print $main'S "$_\n";
    while (&getline) { #'
      if (/No such/) {
        print "$_\n";
      }
    }
  }
  print "done\n";
  $| = 0;
  1;
}

sub reply {
  local ($filename) = "tmp.reply.file";

  s/^ +//;
  s/ +$//;
  if ($_) {
    if (/^(\d+)$/) {
      if ($1 < 1 || $1 > $#msg) {
	print "Bad message number: $1\n";
	return;
      }
      $m = $1;
    } else {
      print "Bad reply syntax.\n";
    }
  }
  if ($type[$m] ne 'TELE' && $type[$m] ne 'ANNO' && $type[$m] ne 'BULL') {
    print "You may only reply to telegrams, announcements, and bulletins.\n";
    return;
  }

  &create_tmp_file;
  if (&post_it("tele $from[$m]\n", "telegram to $from[$m]")) {
    $status[$m] = 'r';
  }
}

sub forward {
  local ($filename) = "tmp.forward.file";
  local ($to);

  s/^ +//;
  s/ +$//;
  if ($_) {
    if (/^(\d+)$/) {
      if ($1 < 1 || $1 > $#msg) {
	print "Bad message number: $1\n";
	return;
      }
      $m = $1;
    } elsif (/^(\d+)\s+(\S+)$/) {
      if ($1 < 1 || $1 > $#msg) {
	print "Bad message number: $1\n";
	return;
      }
      $m = $1;
      $to = $2;
    } elsif (/^(\S+)$/) {
      $to = $1;
    } else {
      print "Bad forward/followup syntax.\n";
    }
  }
  &create_tmp_file;
  if ($to) {
    &post_it("tele $to\n", "telegram to \"$to\"");
  } else {
    &post_it("announce\n", "announcement");
  }
}

sub mail_prompt {
  local($m) = ($current_message);

  $m = $#msg if $m > $#msg;
  $_ = &main'line_prompt("($m/$#msg):"); #'
  s/ +$//;
  s/^ +//;
  while ($_ ne 'q' && $_ ne 'x') {
    if ($_ eq 'h') {
      &print_headers($m);
    } elsif (/^h\s+(\d+)$/) {
      $m = $1 + 10;
      $m = 1 if $m < 1;
      $m = $#msg if $m > $#msg;
      &print_headers($m);
    } elsif ($_ eq 'z') {
      if ($#msg - $m < 10) {
	print "On last screen full of messages.\n";
      } else {
	$m += 20;
	$m = $#msg - 9 if $m > $#msg;
	&print_headers($m);
      }
    } elsif ($_ eq 'Z') {
      if ($m <= 10) {
	print "On first screen full of messages.\n";
      } else {
	$m -= 20;
	$m = 10 if $m < 1;
	&print_headers($m);
      }
    } elsif (/^s/) {
      $_ = $';
      &save;
    } elsif (/^r/) {
      $_ = $';
      &reply;
    } elsif (/^f/) {
      $_ = $';
      &forward;
    } elsif ($_ eq 'd') {
      $status[$m] = 'D';
    } elsif (/^d/) {
      $_ = $';
      &process_delete(0);
    } elsif (/^u/) {
      $_ = $';
      &process_delete(1);
    } elsif (/^(\d+)$/) {
      if ($1 < 1 || $1 > $#msg) {
	print "Bad message number: $1\n";
      } else {
	$m = $1;
	&print_message;
      }
    } elsif (!$_) {
      if ($m == $#msg && $status[$m] ne 'U' && $status[$m] ne 'N') {
	print "No more messages.\n";
      } else {
	if ($status[$m] eq ' ' || $status[$m] eq 'D') {
	  ++$m;
	}
	&print_message;
      }
    } else {
      &mail_help;
    }
    print $main'S "ter 0,1\n"; #' Let the server know we're still here
    &main'suck;
    $_ = &main'line_prompt("($m/$#msg):"); #'
    s/ +$//;
    s/^ +//;
  }    
  $_ eq 'q';
}

sub mail_help {
  print <<'EOF';
Commands are:
  {<num>}               print message
  h {<num>}             print the list of headers {starting at <num>}
  r {<num>}             reply to message {<num>}
  f {<num>} <country>   forward message {<num>} to <country>
  f {<num>}             follow up announcement {<num>}
  s {<num>} <file>      save message {<num>} to a file called <file>
  d {<message list>}    delete {<message list>}
  u {<message list>}    undelete {<message list>}
  z                     next screen of headers
  Z                     previous screen of headers
  q                     quit and save changes
  x                     quit without saving changes
Arguments shown in {} brackets are optional.  Default {<num>} and
{<message list>} is current message.  <message list> may also be any of the following:
    <n>                 message number <n>
    <n>-<m>             messages <n> through <m>
    <n1> <n2> ... <nm>  messages <n1>, <n2>, ..., and <nm>
    p                   all Production Reports
    b                   all BULLETINS
    t                   all telegrams
    *                   all messages
  
  The meanings of the message markers are:
    N                   new
    U                   unread
    r                   replied to
    D                   deleted
EOF
}

$main'functionmap{'tele'}="&mail'tele";
$main'functionmap{'anno'}="&mail'tele";

sub tele {
  if ($main'command eq "anno") {
    $filename = "tmp.anno.file";
    &post_it("announce\n", "announcement");
  } elsif ($main'command eq "tele") {
    $filename = "tmp.tele.file";
    &post_it("tele $main'commandarg\n", "telegram to \"$main'commandarg\"");
  } else {
    print "Bad call to &tele.\n";
  }
}

#*# Warning this function is duplicated in tools.pl (for speed reasons)

package main;

sub mail'getline {
  $mode = -1;

  $_ = &sock'S_read($S, $TIMEOUT); #'
  return 0 if $status;

  ($mode, $_)=/^\s*(\S+) (.+)*$/;
  if(defined($parsemap{$command})) {
    eval('&'.$game."'".$parsemap{$command}); #'
  }
  if ($mode eq $C_FLUSH ||
      $mode eq $C_PROMPT) {
    return 0;
  }
  if ($mode ne $C_DATA) {
#   $mode = $C_DATA;
    $_ = "$mode $_";
    &parse_serverline;
  }
  $mail'_ = $_;
  return 1;
}

$mail_loaded = 1;
