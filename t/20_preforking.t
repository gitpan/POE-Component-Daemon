#!/usr/bin/perl -w
# $Id: 20_preforking.t 134 2006-09-14 18:28:46Z fil $

use strict;

#########################

use Test::More ( tests=>16 );

use Config;
use IO::Socket;

pass( "loaded" );

#########################
my $PORT=33140;
spawn_server('preforking', $PORT);

my $P1 = connect_server($PORT);
my $P2 = connect_server($PORT);


#########################
$/="\r\n";
$P1->print("PID\n");
my $PID1=$P1->getline();

chomp($PID1);
ok( ($PID1 =~ /^(\d+)$/), "Got the PID ($PID1)");
$PID1=$1;

$P1->print("PID\n");
my $PID2=$P1->getline();
chomp($PID2);
is( $PID2, $PID1, "Same PID");




#########################
$P1->print( "LOGFILE\n" );
my $file = $P1->getline();
chomp( $file );

ok( ($file and -f $file), "Created a logfile" );

my $file2 = "$file.OLD";

rename $file, $file2;

ok( (-f $file2), "Moved the log file" ) 
    or diag( "Unable to move $file to $file2: $!" );

kill 1, $PID1;
my_sleep( 1 );
ok( ($file and -f $file), "Created a new logfile" );



END { unlink $file if $file }
END { unlink $file2 if $file2 }



#########################
$P2->print("PID\n");
$PID2=$P2->getline();
chomp($PID2);

isnt( $PID2, $PID1, "Different PID ($PID2)" );

#########################
$P1->print("DONE\n");
$P2->print("DONE\n");

# Allow new processes to spawn
my_sleep( 2 );


#########################
$P1 = connect_server($PORT);
$P2 = connect_server($PORT);

foreach my $p ( $P1, $P2 ) {
    $p->print( "PID\n" );
    my $PID3 = $p->getline();
    chomp( $PID3 );
    ok( $PID3, "Got PID ($PID3)" );
    isnt( $PID3, $PID1, "Not PID1" );
    isnt( $PID3, $PID2, "Not PID2" );
}

#########################
$P1->print( "STATUS\n" );
my @status;
my $line;
while( defined( $line = $P1->getline() ) ) {
    chomp $line;
    last if $line eq 'DONE';
    push @status, $line;
}

is( $status[1], "    Pre-forking server, we are a child", "Preforking" )
    or warn "Line 2 = $status[1]";

ok( $status[4] =~ /Slots \[.*r.*r.*\]/, "2 slots in 'r'" );

# warn join "\n", @status;



#########################
$P1->print( "PEEK\n" );
my @peek;
while( defined( $line = $P1->getline() ) ) {
    chomp $line;
    last if $line eq 'DONE';
    push @peek, $line;
}

my $peek = join "\n", @peek;
ok( ( 4 < @peek and $peek =~ /session \d+ \(Daemon\)/ ), 
        "Peeked into kernel" );
# warn join "\n", @peek;


#########################
$P2->print("PARENT\n");
my $PID3 = $P2->getline();
chomp( $PID3 );

# warn "Parent is $PID3";
kill 15, $PID3 if $PID3;






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
#    local $ENV{PERL5LIB}=join ':', qw(blib/lib
#                            /home/fil/work/JAECA/JAAS/perl5lib/lib/perl5/site_p
#                            /home/fil/work/JAECA/JAAS/perl5lib/lib/site_perl   
#                            /home/fil/prive/perl5lib/lib/site_perl
#                            /home/fil/prive/lib), 
#                        ($ENV{PERL5LIB}||'~/honk');

    my $exec = $Config{perl5} || $Config{perlpath};
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
    my($port)=@_;
    $!=0;
    my $io=IO::Socket::INET->new(PeerAddr=>"localhost:$port");

    die "Can't connect to localhost:$port ($!) Maybe server startup failed?"
            unless $io;
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

