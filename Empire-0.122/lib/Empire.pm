package Empire;

use 5.006;
use strict;
use warnings;

our $VERSION;

use Socket 1.3;
use Carp;
use IO::Socket;
use Net::Cmd;
use Lingua::EN::Numericalize;
use Exporter;

$VERSION = '0.122';

our @ISA = qw(Net::Cmd IO::Socket::INET Empire::Commands Exporter);
our @EXPORT_OK = qw($C_CMDOK $C_DATA $C_INIT $C_EXIT
		    $C_FLUSH $C_NOECHO $C_PROMPT $C_ABORT
		    $C_REDIR $C_PIPE $C_CMDERR $C_BADCMD
		    $C_EXECUTE $C_FLASH $C_INFORM $C_SYNC);
our $C_CMDOK   = '0';
our $C_DATA    = '1';
our $C_INIT    = '2';
our $C_EXIT    = '3';
our $C_FLUSH   = '4';
our $C_NOECHO  = '5';
our $C_PROMPT  = '6';
our $C_ABORT   = '7';
our $C_REDIR   = '8';
our $C_PIPE    = '9';
our $C_CMDERR  = 'a';
our $C_BADCMD  = 'b';
our $C_EXECUTE = 'c';
our $C_FLASH   = 'd';
our $C_INFORM  = 'e';
our $C_SYNC    = 'f';


# Preloaded methods go here.
sub new {

    my $self = shift;
    my $class = ref($self) || $self;
    my %param = @_;
    my $emp = {};

    if (! $param{-user}) {
	$param{-user} = $ENV{USER};
    }
    if (defined $param{-full} && $param{-full}) {
	use Empire::Commands;
	$emp = new Empire::Commands;
	use Empire::Ship;
	use Empire::Sector;
	use Empire::SectorType;
	use Empire::ProductType;
	use Empire::Nation;
	use Empire::Unit;
	use Empire::Plane;
	use Empire::EConfig;
    }
    else {
	$emp = {};
    }
    print "Using Empire.pm v$VERSION\n";
    $emp->{HOST} = $param{-host};
    $emp->{PORT} = $param{-port};
    if ($param{-country} && $param{-player}) {
	if ($param{-player}) {
	    $emp->{COUNTRY} = $param{-country};
	    $emp->{PLAYER} = $param{-player};
	}
    }
    else {
	$emp->{COUNTRY} = 'visitor';
	$emp->{PLAYER} = 'visitor';
	carp "No country name supplied, logging as visitor\n";
    }
    if ($param{-user}) {
	 $emp->{USER} = $param{-user};
    }
    if ($param{-kill}) {
	$emp->{KILL} = $param{-kill};
    }
    else {
	$emp->{KILL} = 'ask';
    }
    if ($param{-name}) {
        $emp->{NAME} = $param{-name};
    }
    else {
        $emp->{NAME} = 'Empire';
    }
    bless $emp,$class;
    $emp->empconnect($class);
}
sub empconnect {

    my $emp = shift;
    my $class = shift;
    $emp->{SOCKET} = $class->SUPER::new(PeerAddr => $emp->{HOST},
					PeerPort => $emp->{PORT},
					Proto    => 'tcp',
					Timeout  => 120,
				      );
    unless (defined $emp->{SOCKET}) {
	$emp->{RESPONSE} = "Failed to Connect to $emp->{HOST} port $emp->{PORT}\n";
	$emp->{EMPSTATUS}   = 'NOT CONNECTED';
	return $emp;
    }
    my $welcome = $emp->{SOCKET}->getline;
    my ($proto,$response) = ($welcome =~ /^(\S)\s+(\S.*)$/);
    if ($proto != $C_INIT) {
	carp "Mysterious server welcome!\n";
	$emp->{SOCKET}->close;
	$emp->{RESPONSE} = 'Mysterious server welcome';
	$emp->{EMPSTATUS}   = 'NOT CONNECTED';
	return $emp;
    }
    unless ($emp->login()) {
	carp "Login failed!\n";
	$emp->{SOCKET}->close;
	$emp->{EMPSTATUS} = 'NOT CONNECTED';
	return $emp;
    }
}
sub login {

    my $emp = shift;

    my ($proto,$response);
    ($proto,$response) = $emp->coun($emp->{COUNTRY});
    if ($proto ne $C_CMDOK) {
	$emp->{SOCKET}->close;
	$emp->{EMPSTATUS} = 'NOT CONNECTED';
	$emp->{RESPONSE} = $response;
	return 0;
    }
    ($proto,$response) = $emp->pass($emp->{PLAYER});
    if ($proto ne $C_CMDOK) {
	$emp->{SOCKET}->close;
	$emp->{RESPONSE} = $response;
	$emp->{EMPSTATUS} = 'NOT CONNECTED';
	return 0;
    }
    if ($emp->{USER}) {
	($proto,$response) = $emp->user($emp->{USER});
	if ($proto ne $C_CMDOK) {
	    $emp->{SOCKET}->close;
	    $emp->{RESPONSE} = "$response";
	    $emp->{EMPSTATUS}   = 'NOT CONNECTED';
	    return 0;
	}
    }
    ($proto,$response) = $emp->play();
    if ($proto eq $C_EXIT) {
	my $kill_resp;
	if ($emp->{KILL} eq 'no') {
	    $emp->{RESPONSE} = $response;
	    $emp->{EMPSTATUS} = 'NOT CONNECTED';
	    return 0;
	}
	elsif ($emp->{KILL} eq 'yes') {
	    $emp->killit();
	}
	else {
	    print "Country in use! Kill? (y/n)";
	    $kill_resp = <STDIN>; chomp $kill_resp;
	    if ($kill_resp eq 'y') {
		$emp->killit();
	    }
	    else {
		$emp->{SOCKET}->close;
		$emp->{RESPONSE} = "Exit requested by user";
		$emp->{EMPSTATUS} = 'NOT CONNECTED';
		print "Exit requested by user!\n";
		return 0;
	    }
	}
    }
    if ($proto ne $C_INIT) {
	carp "Mysterious welcome\n";
	$emp->{SOCKET}->close;
	$emp->{RESPONSE} = $response;
	$emp->{EMPSTATUS} = 'NOT CONNECTED';
	return 0;
    }
    $emp->{BUFFER} = '';
    $emp->{ECHO} = 1;
    $emp->{RESPONSE} = 'Logged in';
    $emp->{EMPSTATUS}   = 'CONNECTED';
    $emp->{MAP} = {};
    $emp->{FLASH} = '';
    $emp->{INFORM} = '';
    $emp->{ANNO} = 0;
    $emp->{TELE} = 0;
    ($proto,$response) = $emp->empreadline('init');
    return $emp;
}
sub coun {

    my $emp = shift;
    my $coun = shift;
    my $cmd = "coun $coun";

    $emp->empcmd($cmd);
    if ($emp->{SOCKET}) {
	$_ = $emp->{SOCKET}->getline();
	s/\r//g;
	/^(\S)\s+(\S.*)$/;
	return ($1,$2);
    }
}
sub pass {

    my $emp = shift;
    my $play = shift;
    my $cmd = "pass $play";

    $emp->empcmd($cmd);
    if ($emp->{SOCKET}) {
	$_ = $emp->{SOCKET}->getline();
	s/\r//g;
	/^(\S)\s+(\S.*)$/;
	return ($1,$2);
    }
}
sub user {

    my $emp = shift;
    my $user = shift;
    my $cmd = "user $user";

    $emp->empcmd($cmd);
    if ($emp->{SOCKET}) {
	$_ = $emp->{SOCKET}->getline();
	s/\r//g;
	/^(\S)\s+(\S.*)$/;
	return ($1,$2);
    }

}
sub play {

    my $emp = shift;
    my $cmd = "play";

    $emp->empcmd($cmd);
    if ($emp->{SOCKET}) {
	$_ = $emp->{SOCKET}->getline();
	s/\r//g;
	/^(\S)\s+(\S.*)$/;
	return ($1,$2);
    }
}
sub empkill {

    my $emp = shift;
    my $cmd = "kill";

    $emp->empcmd($cmd);
    if ($emp->{SOCKET}) {
	$_ = $emp->{SOCKET}->getline();
	s/\r//g;
	/^(\S)\s+(\.*)$/;
	return ($1,$2);
    }
}
sub killit {

    my $emp = shift;

    my ($proto,$response) = $emp->empkill();
    if ($proto == $C_EXIT) {
	($proto,$response) = $emp->play();
	if ($proto == $C_EXIT) {
	    $emp->{SOCKET}->close;
	    carp "Country still in use! Alert the deity!";
	    $emp->{RESPONSE} = $response;
	    $emp->{EMPSTATUS} = 'NOT CONNECTED';
	    return 0;
	}
    }
    else {
	$emp->{SOCKET}->close;
	carp "Unknown kill error!";
	$emp->{RESPONSE} = $response;
	$emp->{EMPSTATUS} = 'NOT CONNECTED';
	return 0;
    }
}
sub empstatus {

    my $emp = shift;
    my %empstatus;

    $empstatus{EMPSTATUS} = $emp->{EMPSTATUS};
    $empstatus{RESPONSE} = $emp->{RESPONSE};
    return %empstatus;
}
sub empreadline {

    my $emp = shift;
    my $cmd = shift;
    my $response;
    my $data = '';
    my $annos;
    my $teles;

    $response = $emp->{SOCKET}->getline();
    $response =~ s/\r//;
    ($emp->{EMPSTATUS},$emp->{RESPONSE}) = ($response =~ /^(\S) (.*)/);
    if ($cmd eq 'void') {
	if ($emp->{EMPSTATUS} eq $C_FLASH) {
	    if ($emp->{RESPONSE} eq 'Server shutting down...') {
		$emp->{EMPSTATUS} = $C_EXIT;
	    }
	    else {
		$emp->{FLASH} .= $emp->{RESPONSE} . "\n";
	    }
	}
	elsif ($emp->{EMPSTATUS} eq $C_INFORM) {
	    $emp->{INFORM} .= $emp->{RESPONSE};
	    chomp $emp->{INFORM};
	}
	return($emp->{EMPSTATUS},'');
    }
    while ($emp->{EMPSTATUS} ne $C_PROMPT &&
	   $emp->{EMPSTATUS} ne $C_FLUSH &&
	   $emp->{EMPSTATUS} ne $C_EXIT) {
	if ($emp->{EMPSTATUS} eq $C_DATA) {
	    if ($emp->{RESPONSE} =~ /You have (.*) new announcement/) {
		$emp->{ANNO} = $emp->{RESPONSE};
	    }
	    elsif ($emp->{RESPONSE} =~ /You have (.*) new telegram/) {
		$emp->{TELE} = $emp->{RESPONSE};
	    }
	    else {
		$data .= $emp->{RESPONSE} ."\n";
	    }
	}
	elsif ($emp->{EMPSTATUS} eq $C_FLASH) {
	    $emp->{FLASH} .= $emp->{RESPONSE} . "\n";
	}
	elsif ($emp->{EMPSTATUS} eq $C_INFORM) {
	    $emp->{INFORM} .= $emp->{RESPONSE};
	    chomp $emp->{INFORM};
	}
	$response = $emp->{SOCKET}->getline;
	$response =~ s/\r//;
	chomp $response;
	($emp->{EMPSTATUS},$emp->{RESPONSE}) = ($response =~ /^(\S) (.*)/);
    }
    $emp->{DATA}->{$cmd} = $data;
    if ($cmd eq 'init') {
	print "$emp->{DATA}->{$cmd}\n";
    }
    if ($emp->{EMPSTATUS} eq $C_PROMPT) {
	my($min,$btu) = ($emp->{RESPONSE} =~ /(\d+)\s+(\d+)/);
	$emp->{BTU} = $btu;
	$emp->{MINUTES} = $min;
    }
    elsif ($emp->{EMPSTATUS} eq $C_FLUSH) {
	$emp->{SUBPROMPT} = $emp->{RESPONSE};
    }
    elsif ($emp->{EMPSTATUS} eq $C_EXIT) {
	$emp->{DATA}->{$cmd} .= $emp->{RESPONSE};
	close $emp->{SOCKET};
    }
    return ($emp->{EMPSTATUS},$emp->{DATA}->{$cmd});
}
sub empcmd {

    my $emp = shift;
    my $cmd = shift;

    chomp $cmd;
    $emp->{SOCKET}->datasend($cmd . "\n");

    return;
}
sub empbuffer {

    my $emp = shift;
    my $cont = shift;

    if (!defined $cont) {
	return $emp->{BUFFER};
    }
    elsif ($cont eq 'VOID') {
	$emp->{BUFFER} = '';
    }
    else {
	$emp->{BUFFER} = $cont;
    }
}
sub country {

    my $self = shift;
    my $coun = shift;

    $self->{COUNTRY} = $coun if defined $coun;
    return $self->{COUNTRY};
}
sub player {

    my $self = shift;
    my $play = shift;

    $self->{PLAYER} = $play if defined $play;
    return $self->{PLAYER};
}
sub port {

    my $self = shift;
    my $port = shift;

    $self->{PORT} = $port if defined $port;
    return $self->{HOST};
}
sub host {

    my $self = shift;
    my $host = shift;

    $self->{HOST} = $host if defined $host;
    return $self->{HOST};
}
sub name {

    my $self = shift;
    my $name = shift;

    $self->{NAME} = $name if defined $name;
    return $self->{NAME};
}
sub minutes {

    my $self = shift;

    return $self->{MINUTES};
}
sub btu {

    my $self = shift;
    return $self->{BTU};
}
sub hasflash {

    my $self = shift;
    return $self->{FLASH};
}
sub clearflash {

    my $self = shift;

    $self->{FLASH} = '';
}
sub hasinform {

    my $self = shift;
    return $self->{INFORM};
}
sub clearinform {

    my $self = shift;

    $self->{INFORM} = '';
}
sub hastele {

    my $self = shift;

    return $self->{TELE};
}
sub cleartele {

    my $self = shift;

    $self->{TELE} = 0;
}
sub hasanno {

    my $self = shift;

    return $self->{ANNO};
}
sub clearanno {

    my $self = shift;

    $self->{ANNO} = 0;
}
sub subprompt {

    my $self = shift;

    return $self->{SUBPROMPT};
}
sub disconnect {

    my $self = shift;

    $self->{SOCKET}->close();
    delete $self->{SOCKET};
}
1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Empire - an interface for the Empire game L<http://www.wolfpackempire.com>

=head1 SYNOPSIS

  use Empire;
  my $empire = Empire(-full=>1, # or 0
                      -host=>$host,
                      -port=>$port,
                      -country=>$coun,
                      -player=>$play,
                      -name=>$name,
                      -user=>$user);
  if ($empire->{SOCKET}) {
      $empire->empcmd($cmd);
      my ($status,$data) = $empire->empreadline();
  }

=head1 DESCRIPTION

This is a module that provides a connection interface to the Wolfpack
Empire server. The constructor reads the server and the login data and
creates a socket to the server. Then the following main methods become
available:

=over

=item C<Constructor>

new Empire(%args).

The arguments as shown in synopsis are quite self-explainable. The -full
argument indicates that the additional utility modules (Ship, Sector, Plane
etc. - which are not fully ready yet) should also be loaded.

=item C<empcmd>

$empire->empcmd($cmd);

This one just sends a command to the server

=item C<empreadline>

$empire->empreadline($cmd);

This reads lines from the server until a prompt or a connection close
protocol response is received. The inform, flash and data responses are
consumed into three different variables to be manipulated correctly by
the implementing program. A special treatment for notifying telegrams
and announcements also exists.

=item C<coun pass user empkill killit play>

$empire->coun($coun) et al.

These are methods used by the login procedure including killing the
connection.

=item C<empstatus>

%empstatus = $empire->empstatus();

This method returns a hash containing the field EMPSTATUS which is
the last protocol response the server sent and the textual string
accompanying it.

=item C<empbuffer>

$empire->empbuffer(?cont)

This method is implemented for future use to serve as an information
exchange buffer.

=item C<host port country player name>

$empire->host() et al.

These methods serve the clients to find out information about the
current connection in the $empire object.

=item C<minutes btu>

$empire->btu()

$empire->minutes()

These methods provide information about the BTU (Bureaucratic Time
Units) and the time used in the game by the player as presented in
the main game prompt.

=item C<hasflash hasinform hastele hasanno
        clearflash clearinform cleartele clearanno>

$empire->hasflash() et al.

These methods manipulate the received flash, inform, telexes and
announcements as read by the empreadline method.

=item C<disconnect>

$empire->disconnect()

Obvoious.
=back

=head1 EXPORT

The protocol numbers of the Empire server are being exported.



=head1 SEE ALSO

The Wolfpack Empire site

L<http://www.wolfpackempire.com>

The Wolfpack Empire Server project

L<http://sourceforge.net/projects/empserver>

Programs based on this module:

L<http://empire.tau.ac.il/~romm/emp/>

=head1 AUTHOR

Roman M. Parparov, E<lt>romm@empire.tau.ac.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Roman M. Parparov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
