#/usr/local/bin/perl
package sock;

;# USAGE:
;# ======
;#
;# To open a connection to a socket:
;#
;#      $handle = &sock'open($hostname, $port) || die $!;
;#      # hostname & port can each be either a name or a number
;#
;# Read and write the same as with any other file handle:
;#
;#      print $handle "hello, socket\n";
;#      $response = <$handle>;
;#
;# To close cleanly:
;#
;#      &sock'close($handle);
;#
;# To close all open sockets, in case of an emergency exit:
;#
;#      &sock'close_all;
;#
;# AUTHOR:      David Noble (dnoble@ufo.jpl.nasa.gov)
;# DATE:        11 Feb 1993
;#
;# Modify and use as you see fit, but please leave my name on
;# it as long as it still resembles the original code.
;#
;# Modified for Socket.pm and pei by Sam Tetherow (tetherow@nol.org)
;# Will probably clean it up at some point, but I ain't holding my breathe
;#
;#############################################################################

use Socket;

;# Seed the generation of names for file handles.
$latest_handle = 'sock0000000001';

sub open {
  local ($remote_host, $remote_port) = @_;
  if (!$remote_port) {
    $! = "bad arguments to sock'open()";
    return 0;
  }
  $sock = ++$latest_handle;


  ;# Make the socket filehandle.
	$proto=getprotobyname('tcp');
  socket($sock, AF_INET, SOCK_STREAM, $proto) || return 0;

  ;# Look up the port if it was specified by name instead of by number.
  if ($remote_port =~ /\D/o) {
		$remote_port=getservbyname($remote_port, 'tcp');
  }

  ;# Make the socket structures.
	$remote_sock=Socket::sockaddr_in($remote_port, Socket::inet_aton($remote_host));

  ;# Set up the port so it's freed as soon as we're done.
  setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, 1);

  ;# Call up the remote socket.
  connect($sock, $remote_sock) || return 0;

  $handles{$sock} = 1;
  $oldfh = select($sock); $| = 1; select($oldfh);
  return "sock'" . $sock;
}

sub close {
  local ($sock) = shift(@_) || return 0;
  shutdown ($sock, 2);
  delete $handles{$sock};
}

sub close_all {
  for $sock (keys %handles) {
    shutdown ($sock, 2);
    delete $handles{$sock};
  }
}

# USAGE:
# ======
#
# $line = &S_read($handle, $timeout);
#
# INPUTS:
#
# $handle      - regular file handle returned by opening the socket
# $timeout     - number of seconds to wait before returning empty-handed
#
# RETURN VALUE:
#
# Returns data from the socket after removing the garbage from telnet
# handshaking.
# Only one line at a time is returned. The remaining lines are buffered,
# and will be used to satisfy further requests for data until
# the buffer is empty again. A partial line may be returned if the timeout
# was reached before a newline.
#
# Returns the empty string on EOF or timeout.
# To decide which it was, use these variables:
#
#      if (!$main'status) {
#        &data_received;
#      } elsif ($main'status & $main'S_EOF) {
#        &outta_here;	# server EOF
#      } elsif ($main'status & $main'S_TIMEOUT) {
#        &whatever;     # read timed out
#      }
#
# AUTHOR:      David Noble (dnoble@ufo.jpl.nasa.gov)
# DATE:        11 Feb 1993
# Modified for use by pei by Ken Stevens 14 June 95
#
# Modify and use as you see fit, but please leave my name on
# it as long as it still resembles the original code.
#
#############################################################################

sub S_read {
  local ($handle, $endtime) = @_;
  local ($rmask, $nfound, $nread, $thisbuf, $buf);

  $main'status &= ~($main'S_EOF | $main'S_TIMEOUT);

  if ($TelnetBuffer{$handle} =~ m/\n/) {
    $TelnetBuffer{$handle} =~ s/^(.*\n)//;
    $buf = $1;
  } else {
    $endtime += time;
    $* = 1;
  get_data:
    while ($endtime > time) {
      $rmask = "";
      $thisbuf = "";
      vec($rmask, fileno($handle), 1) = 1;
      ($nfound, $rmask) = select($rmask, undef, undef, $endtime - time);
      if ($nfound) {
	$nread = sysread($handle, $thisbuf, 1024);
	if ($nread > 0) {
	  $TelnetBuffer{$handle} .= $thisbuf;
	  last get_data if &_preprocess($handle);
	}
	else {
	  $main'status |= $main'S_EOF;
	  $* = 0;
	  return ''; # connection closed
	}
      }
      else {
	$main'status |= $main'S_TIMEOUT;
	last get_data;
      }
    }
    $* = 0;
    if ($TelnetBuffer{$handle} =~ m/\n/) {
      $TelnetBuffer{$handle} =~ s/^(.*\n)//;
      $buf = $1;
    } else {
      $main'status |= $main'S_TIMEOUT;
    }
  }
  $buf;
}

sub _preprocess {
    local ($handle) = @_;
    local ($_) = $TelnetBuffer{$handle};

    s/\015\012/\012/go; # combine (CR NL) into NL

    while (m/\377/) {
        # respond to "IAC DO x" or "IAC DON'T x" with "IAC WON'T x"
        if (s/([^\377])?\377[\375\376](.|\n)/\1/)
            { print $handle "\377\374$2"; }

        # ignore "IAC WILL x" or "IAC WON'T x"
        elsif (s/([^\377])?\377[\373\374](.|\n)/\1/) {;}

        # respond to "IAC AYT" (are you there)
        elsif (s/([^\377])?\377\366/\1/)
            { print $handle "nobody here but us pigeons\n"; }

        else { last; }
    }
    s/\377\377/\377/go; # handle escaped IAC characters

    $TelnetBuffer{$handle} = $_;
    m/\n/; # return value: whether there is a full line or not
}
