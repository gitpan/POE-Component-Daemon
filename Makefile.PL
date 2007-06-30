use 5.00405;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval "use ExtUtils::MakeMaker::Coverage;";


WriteMakefile(
    'NAME'		=> 'POE::Component::Daemon',
    'VERSION_FROM'	=> 'Daemon.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        POE=>0.3202,
        POE::API::Peek=>1        
    },
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},
);
