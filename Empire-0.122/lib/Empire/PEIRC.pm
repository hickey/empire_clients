package Empire::PEIRC;

use strict;
use warnings;

use Carp;

our @FIELD = qw(game host port coun play gamedir);

our $NAME = 0;

our $PEIDIR = '/home/romm/EMP/PEI/';

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    my $peirc = shift;

    $peirc = $ENV{HOME} . '/.pei3rc' unless $peirc;
    bless $self,$class;
    $self->{games} = {};
    $self->readPEIrc($peirc);
    $self->{field} = [@FIELD];
    $self->{file} = $peirc;
    $self->{basedir} = $PEIDIR;
    return $self;
}
sub fields {

    my $self = shift;
    
    return $self->{field};
}
sub defvalue {

    my $self = shift;
    my $field = shift;
    my $newvalue = shift;

    if (defined $self->{default}->{$field}) {
	if ($newvalue) {
	    $self->{default}->{$field} = $newvalue;
	}
	return $self->{default}->{$field};
    }
}
sub readPEIrc {

    my $self = shift;
    my $file = shift;

    if (! open(PEIRC,$file)) {
	croak "The peirc file $file is not available. No games can be loaded.\n";
	return ();
    }
    while (<PEIRC>) {
	s/^\s+//;
	s/\s+$//;
	next unless (/\S/);
	next if (/^#/);
	if (/^\S+\s*=/) {
	    my ($var,$value) = split(/=/);
	    $var =~ s/\s//g;
	    $self->{var}->{$var} = eval($value);
	}
	elsif (/^game/) {
	    my (@game) = split(/\s+/);
	    shift @game;
	    my $name = $game[$NAME];
	    for my $field (@FIELD) {
		$self->{games}->{$name}->{$field} = shift @game;
	    }
	}
	elsif (/^alias/) {
	    my (@alias) = split(/\s+/);
	    shift @alias;
	    my $alias = shift @alias;
	    $self->{alias}->{$alias} = join ' ',@alias;
	}
    }
    close PEIRC;
}
sub basedir {

    my $self = shift;
    my $dir = shift;

    $self->{basedir} = $dir if $dir;
    return $self->{basedir};
}
sub games {

    my $self = shift;

    return keys %{$self->{games}};
}
sub getGame {

    my $self = shift;
    my $game = shift;

    if (defined $self->{games}->{$game}) {
	return $self->{games}->{$game};
    }
    else {
	return ();
    }
}
sub setGame {

    my $self = shift;
    my %param = @_;

    my $game;
    unless (defined $param{game}) {
	carp("You have to define a game name");
	return;
    }
    $game = $param{game} . '_' . $param{nick};
    unless (defined $param{gamedir}) {
	$param{gamedir} = $PEIDIR . $game . '/';
    }
    $self->{games}->{$game} = {%param};
}
sub peirc {

    my $self = shift;
    my $peirc = shift;

    if (defined $peirc) {
	$self->{file} = $peirc;
    }
    return $self->{file};
}
sub writePEIrc {

    my $self = shift;
    my $peirc = shift;

    $peirc = $self->peirc() unless $peirc;

    if (! open(PEIRC,">$peirc")) {
	croak "Couldn't write file $peirc: $!\n";
	return ();
    }
    select PEIRC;
    print "# This is .pei3rc file, auto-generated by pei3\n";
    my $time = localtime(time);
    print "# Written at $time\n";
    print "##############################################################\n\n";
    print "\n# Aliases\n############\n\n";
    for my $alias ($self->getAllAlias()) {
	print "alias $alias ".$self->getAlias($alias) ."\n";
    }
    print "\n# Variables\n############\n\n";
    for my $var ($self->getAllVar()) {
	print "$var = \"".$self->getVar($var) ."\"\n";
    }
    print "\n# Games\n############\n\n";
    for my $game ($self->games()) {
	print "game ";
	$self->showGame($game);
    }
    close PEIRC;
    select STDOUT;
    return;
}
sub deleteGame {

    my $self = shift;
    my $game = shift;

    if (defined $self->{games}->{$game}) {
	delete $self->{games}->{$game};
    }
    else {
	carp("No such game $game");
    }
}
sub game {

    my $self = shift;
    my $game = shift;
    my $name = shift;

    $self->{games}->{$game}->{game} = $name if defined $name;
    return $self->{games}->{$game}->{game};
}
sub coun {

    my $self = shift;
    my $game = shift;
    my $coun = shift;

    $self->{games}->{$game}->{coun} = $coun if defined $coun;
    return $self->{games}->{$game}->{coun};
}
sub play {

    my $self = shift;
    my $game = shift;
    my $play = shift;

    $self->{games}->{$game}->{play} = $play if defined $play;
    return $self->{games}->{$game}->{play};
}
sub port {

    my $self = shift;
    my $game = shift;
    my $port = shift;

    $self->{games}->{$game}->{port} = $port if defined $port;
    return $self->{games}->{$game}->{port};
}
sub host {

    my $self = shift;
    my $game = shift;
    my $host = shift;

    $self->{games}->{$game}->{host} = $host if defined $host;
    return $self->{games}->{$game}->{host};
}
sub gamedir {

    my $self = shift;
    my $game = shift;
    my $gamedir = shift;

    $self->{games}->{$game}->{gamedir} = $gamedir if defined $gamedir;
    return $self->{games}->{$game}->{gamedir};
}
sub getAllAlias {

    my $self = shift;

    return keys %{$self->{alias}};
}
sub getAlias {

    my $self = shift;
    my $alias = shift;

    return $self->{alias}->{$alias};
}
sub setAlias {

    my $self = shift;
    my @arg = @_;

    my $alias = shift @arg;
    $self->{alias}->{$alias} = join ' ',@arg;
}
sub alias {

    my $self = shift;
    my $command = shift;

    my @arg = split(/\s+/,$command);
    if ($#arg == -1) {
	print "Aliases:\n";
	print "--------\n";
	for my $alias ($self->getAllAlias()) {
	    print "$alias \t".$self->getAlias($alias) ."\n";
	}
    }
    elsif ($#arg == 0) {
	if ($self->getAlias($arg[0])) {
	    print "$arg[0] aliased to " . $self->getAlias($arg[0]) ."\n";
	}
	else {
	    print "Alias $arg[0] is not defined\n";
	}
    }
    else {
	if ($self->getAlias($arg[0])) {
	    print "Alias $arg[0] updated\n";
	}
	else {
	    print "Alias $arg[0] added\n";
	}
	$self->setAlias(@arg);
    }
    return;
}
sub expandAlias {

    my $self = shift;
    my $alias = shift;
    my (@arg) = @_;
    my $aliasline = '';
    my @expanded;

    my (@aliasarg) = split(/ /,$self->getAlias($alias));
    for my $aarg (@aliasarg) {
	if ($aarg =~ /^\$(\d+)/) {
	    my $aliasrep = $1 - 1;
	    if ($aliasrep > $#arg) {
		print "Alias $alias: $aarg not substituted - not enough arguments\n";
		$aarg = ' ';
	    }
	    else {
		$aarg = $arg[$aliasrep];
		$expanded[$aliasrep] = 1;
	    }
	}
	$aliasline .= $aarg . ' ';
    }
    for my $ai (0..$#arg) {
	if (!defined $expanded[$ai]) {
	    $aliasline .= $arg[$ai] . ' ';
	}
    }
    return $aliasline;
}
sub getAllVar {

    my $self = shift;

    return keys %{$self->{var}};
}
sub getVar {

    my $self = shift;
    my $var = shift;

    return $self->{var}->{$var};
}
sub setVar {

    my $self = shift;
    my $var = shift;
    my $val = shift;

    $self->{var}->{$var} = eval($val);
}
sub var {

    my $self = shift;

    print "Variables:\n";
    print "--------\n";
    for my $var ($self->getAllVar()) {
	print "$var = ".$self->getVar($var) ."\n";
    }
}
sub showGames {

    my $self = shift;
    my $args = shift;
    my @args = split(/\s+/,$args);

    if ($#args == -1) {
	print "Games:\n";
	print "======\n";
	for ($self->games()) {
	    $self->showGame($_);
	}
    }
    else {
	for my $i (0..$#args) {
	    if ($self->getGame($args[$i])) {
		$self->showGame($args[$i]);
	    }
	    else {
		print "game $args[$i] is not defined\n";
	    }
	}
    }
}
sub addGame {

    my $self = shift;
    my $arg = shift;
    my (@game) = split(/\s+/,$arg);

    if ($#game == $#FIELD) {
	my $name = $game[$NAME];
	for my $field (@FIELD) {
	    $self->{games}->{$name}->{$field} = shift @game;
	}
    }
    else {
	print "Insufficient number of parameters!\n";
    }
}
sub showGame {

    my $self = shift;
    my $game = shift;

    print join " ",($self->game($game),$self->host($game),$self->port($game),$self->coun($game),$self->play($game),$self->gamedir($game));
    print "\n";
}
1;
