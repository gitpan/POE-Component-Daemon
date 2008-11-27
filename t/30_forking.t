#!/usr/bin/perl -w
# $Id: 30_forking.t 336 2008-11-27 03:16:15Z fil $

use strict;

#########################

use Test::More ( tests => 14 );

use Config;
use IO::Socket;
# use Religion::Package qw(1 1);


pass( 'loaded' );

#########################
my $PORT=33140;
spawn_server('forking', $PORT);
my $P1=connect_server($PORT);

#########################
$/="\r\n";
$P1->print("DONGS!!\n");
my $rep=$P1->getline();
chomp($rep);

is( $rep, '???', "Got confused answer" );

#########################
$P1->print("PING\n");
$rep=$P1->getline();
chomp($rep);
is( $rep, 'PONG', "PING-PONG" );


#########################
$P1->print("PID\n");
my $PID1=$P1->getline();
chomp($PID1);

ok( ($PID1 =~ /^(\d+)$/), "Got PID" );
$PID1=$1;

$P1->print("PID\n");
my $PID2=$P1->getline();
chomp($PID2);
is( $PID1, $PID1, "Got the same PID");

$P1->print("KERNEL\n");
my $KID1=$P1->getline();
chomp($KID1);
ok( $KID1, "Got kernel ID from first server" );

#########################
my $P2=connect_server($PORT);

#########################
$P2->print("PING\n");
$rep=$P2->getline();
chomp($rep);
is( $rep, 'PONG', "PING-PONG" );

$P2->print("PID\n");
$PID2=$P2->getline();
chomp($PID2);

isnt( $PID2, $PID1, "Different PID" );


$P2->print("KERNEL\n");
my $KID2=$P2->getline();
chomp($KID2);
ok( $KID2, "Got kernel ID from second server" );

isnt( $KID2, $KID1, "Different Kernel IDs" );

#########################
$P1->print( "LOGFILE\n" );
my $file = $P1->getline();
chomp( $file );

ok( ($file and -f $file), "Created a logfile" ) or warn $file;
END { unlink $file if $file }



#########################
$P1->print("DONE\n");

$P1=connect_server($PORT);
$P1->print("PID\n");
my $PID3=$P1->getline();
chomp($PID3);

ok( !( $PID3 == $PID2 or $PID3 == $PID1 ), "All different PIDs");

$P1->print("PARENT\n");
my  $PID4 = $P1->getline();
chomp( $PID4 );
# warn "Parent is $PID4";



#########################
my $P3 = connect_server( $PORT, 1 );
my_sleep( 3 );

my $alarm;
my $P4;
eval {
    local $SIG{ALRM} = sub { $alarm=1; die "ALARM"; };
    alarm( 5 );
    $P1 = connect_server( $PORT, 1 );
    alarm( 0 );
};
warn $@ if $@;
ok( (! $P4), "Max 3 children" );

#########################
$P1->print("DONE\n");
my_sleep( 3 );

$alarm = 0;
eval {
    local $SIG{ALRM} = sub { $alarm=1; die "ALARM"; };
    alarm( 5 );
    $P1 = connect_server( $PORT, 1 );
    alarm( 0 );
};
warn $@ if $@;
ok( $P1, "Max 3 children" );


#########################
$P2->print("DONE\n");

# warn "Parent is $PID4";
kill 15, $PID4 if $PID4;
# system("killall forking");

#########################################
sub my_sleep
{
    my( $seconds ) = @_;
    if( $ENV{HARNESS_PERL_SWITCHES} ) {
        $seconds *= 10;
    }
    diag( "sleep $seconds" );
    sleep $seconds;
}

#########################################
sub spawn_server
{
    my ($server, @args)=@_;
    foreach my $dir ('../jaeca', '.') {
        next unless -x "$dir/$server";
        $server="$dir/$server";
        last;
    }
    my $exec = $^X || $Config{perl5} || $Config{perlpath};
#    local $ENV{PERL5LIB}=join ':', @INC;
#    $exec .= " ".join " ", map { "-I\Q$_" } @INC;
    $exec .= " -Iblib/lib"; 
    if( $ENV{HARNESS_PERL_SWITCHES} ) {
        $exec .= " $ENV{HARNESS_PERL_SWITCHES}";
    }

    $exec .= join ' ', '', $server, @args;

    system( $exec )==0
        or die "Unable to launch $exec: $?\n";

    my_sleep( 2 );
}

#########################################
sub connect_server
{
    my($port, $failure_ok)=@_;
    $!=0;
    my $io=IO::Socket::INET->new( PeerAddr => "localhost:$port" );

    die "Can't connect to localhost:$port ($!) Maybe server startup failed?"
            unless $io or $failure_ok;
    return $io;
}

__END__

$Log$
Revision 1.1  2006/09/14 18:28:46  fil
Added foreign_child()
Added HUP and TERM support
Moved signal sending to inform_others() and expedite_signal()
expedite_signal by-passes POE's queue, by sending signals directly to
    watchers via ->call();

Added ->peek()
Many tweaks for preforking child
Coverage and tests

