#$Id: Scoreboard.pm,v 1.3 2006/09/14 18:28:46 fil Exp $
########################################################
package POE::Component::Daemon::Scoreboard;

use 5.00405;
use strict;

use vars qw($VERSION $UNIQUE);

use IPC::SysV qw(IPC_PRIVATE S_IRWXU IPC_CREAT SEM_UNDO);
use Carp;

$VERSION = '0.01';

sub DEBUG () { 0 }

########################################################
sub new
{
    my($package, $N)=@_;
    if($UNIQUE) {
        warn "This should be only one $package.  Reusing previous one.";
        return $UNIQUE;
    }

    my $self=bless {N=>$N}, $package;

    $self->{mem}=shmget(IPC_PRIVATE, $N, S_IRWXU);
    die "$$: Unable to create shared memory: $!\n" unless $self->{mem};

    $self->{slots}=[reverse 0..($N-1)];

    my $blank=' ' x $N;
    shmwrite($self->{mem}, $blank, 0, $N);

    $UNIQUE=$self;

    return $self;
}

########################################################
sub read_all
{
    my($self)=@_;

    my $str=" " x $self->{N};
    shmread($self->{mem}, $str, 0, $self->{N})
        or die "Unable to read shared memory: $!\n";

    my $ret=[split //, $str];
    return $ret;
}

########################################################
sub add
{
    my($self, $value)=@_;
    return unless @{$self->{slots}};
    my $slot=pop @{$self->{slots}};
    DEBUG and warn "Adding slot $slot";
    $self->write($slot, $value);
    return $slot;
}

########################################################
sub drop
{
    my($self, $slot)=@_;
    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }
    $self->write($slot, '.');
    DEBUG and warn "Dropped slot $slot";
    push @{$self->{slots}}, $slot;
    return;
}

########################################################
sub write
{
    my($self, $slot, $value)=@_;
    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }

    $value=substr($value, 0, 1);
    DEBUG and warn "Setting slot $slot to $value";

    shmwrite($self->{mem}, $value, $slot, 1)
        or warn "Writing shared memory slot $slot: $!";

    return;
}

########################################################
sub read
{
    my($self, $slot)=@_;
    return unless defined $slot;

    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }
    DEBUG and warn "Reading value $slot";

    my $value=" ";
    shmread($self->{mem}, $value, $slot, 1)
        or warn "Reading shared memory slot $slot: $!";
    return $value;
}

########################################################
sub status
{
    my($self)=@_;
    my @ret;

    my $n=$self->read_all();
    push @ret, ref($self);
    push @ret, "$self->{N} slots in the scoreboard";
    push @ret, join '', "Slots [", @$n, "]";
    push @ret, (0+@{$self->{slots}})." slots free";

    return join "\n    ", @ret;
}

1;

__DATA__

$Log: Scoreboard.pm,v $
Revision 1.3  2006/09/14 18:28:46  fil
Added foreign_child()
Added HUP and TERM support
Moved signal sending to inform_others() and expedite_signal()
expedite_signal by-passes POE's queue, by sending signals directly to
    watchers via ->call();

Added ->peek()
Many tweaks for preforking child
Coverage and tests

Revision 1.2  2004/10/21 03:06:19  fil
Fixed KR_RUN_CALLED call for 5.004_05
Improved debug output
added daemon_accept signal

Revision 1.1.1.1  2004/04/13 19:01:42  fil
Honk

