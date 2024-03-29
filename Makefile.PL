#!/usr/bin/perl
use strict;
use warnings;
use 5.00405;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval "use ExtUtils::MakeMaker::Coverage;";

# Make sure shmget works properly
eval {
    require "IPC/SysV.pm";
    my $mem = shmget(IPC::SysV::IPC_PRIVATE(), 32, IPC::SysV::S_IRWXU())
                        ||
              shmget(IPC::SysV::IPC_PRIVATE(), 32, IPC::SysV::S_IRWXU());
    $mem or die "shmget failed: $!";
    if( $mem ) {
        shmctl( $mem, IPC::SysV::IPC_RMID(), 0 )
            or die "shmctl failed: $!";
    }
};
if( $@ ) {
    warn "Shared memory not available on $^O: $@\n";
    exit 0;
}

WriteMakefile(
    'AUTHOR'         => 'Philip Gwyn <gwyn -at- cpan.org>',
    'NAME'	    	=> 'POE::Component::Daemon',
    'VERSION_FROM'	=> 'Daemon.pm', # finds $VERSION
    'LICENSE'       => 'perl',
    'PREREQ_PM'		=> {
        'IPC::SysV'        => 1,
        'POE'              => 1,
        'File::Basename'   => 1,
        'File::Copy'       => 1,
        # 'POE::API::Peek'  => 1        
    },
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},
);
