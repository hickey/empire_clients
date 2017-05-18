# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Empire.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Empire') };
ok(&new_game(),'not connected');
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
sub new_game {

    my $host = 'blitz.wolfpackempire.com';
    my $port = 5678;

    #"The default testing server is $host:$port\n";
    #"Enter the new values in case you want to test against a different server\n";
    my $game = Empire->new(-full=>0,
			   -host=>$host,
			   -port=>$port,
			   -country=>'visitor',
			   -player=>'visitor',
			   -name=>'test');
    my %empstatus = $game->empstatus();
    return ($empstatus{EMPSTATUS} ne 'NOT CONNECTED');
}

