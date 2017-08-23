#!/usr/bin/perl

use strict;
use warnings;

use constant LOG_DIR    => '/var/log/gpdfand';
use constant LOG_FILE   => 'gpdfand.log';
use constant PIDDIR     => '/var/run';
use constant TEMPS      => 45;
use constant TEMPM      => 55;
use constant TEMPH      => 65;

use Proc::Daemon;
use Proc::PID::File;
use Log::Dispatch;
use Log::Dispatch::File;
use Date::Format;
use File::Spec;

our $HOSTNAME = `hostname`;
chomp $HOSTNAME;

my $log = new Log::Dispatch(
    callbacks => sub {
                my %h=@_;
                return Date::Format::time2str('%B %e %T', time)." ".$HOSTNAME." $0\[$$]: ".$h{message}."\n";
        }
);

$log->add(
        Log::Dispatch::File->new(
                name      => 'file1',
                min_level => 'warning',
                mode      => 'append',
                filename  => File::Spec->catfile(LOG_DIR, LOG_FILE),
        )
);

sub dienice ($);

sub getTemps {
        my @tmp;
        my @tmp_paths;
        my $corefh;
        my $tmp_int = 0;

        # Determine path
        @tmp_paths = glob "/sys/class/hwmon/hwmon*/temp{2,3,4,5}_input";

        foreach(@tmp_paths)
        {
          open($corefh, "<", $_);
          $tmp[$tmp_int] = <$corefh> / 1000;
          close($corefh);

          $tmp_int++;
        }
        return @tmp;
}

sub fanCtlOn {
        open(my $fhexp, ">", "/sys/class/gpio/export") or dienice("GPIO error.");
        print $fhexp "397";
          close($fhexp);
          open($fhexp, ">", "/sys/class/gpio/export") or dienice("GPIO error.");
        print $fhexp "398";
        close($fhexp);
}

sub fanSpd {
        my ($b1, $b2) = @_;
        open(my $fh397, ">", "/sys/class/gpio/gpio397/value") or dienice("GPIO error.");
        open(my $fh398, ">", "/sys/class/gpio/gpio398/value") or dienice("GPIO error.");
        print $fh397 $b1;
        print $fh398 $b2;
        close($fh397);
        close($fh398);
}

our $ME = $0; $ME =~ s|.*/||;
our $PIDFILE = PIDDIR."/$ME.pid";

fanCtlOn();

$log->warning("Starting gpdfand:  ".time());

Proc::Daemon::Init();

if(Proc::PID::File->running()) {
        dienice("Daemon already running.");
}

my $keep_going = 1;
my $sleep = 0;
$SIG{HUP}  = sub { $log->warning("Caught SIGHUP:  exiting gracefully"); $keep_going = 0; };
$SIG{INT}  = sub { $log->warning("Caught SIGINT:  exiting gracefully"); $keep_going = 0; };
$SIG{QUIT} = sub { $log->warning("Caught SIGQUIT:  exiting gracefully"); $keep_going = 0; };
$SIG{SIGUSR1} = sub {
    $log->warning("Caught SIGUSR1: stopping fans for suspend.");
    $sleep = 1;
    fanSpd(0,0);
};
$SIG{SIGUSR2} = sub {
    $log->warning("Caught SIGUSR2: waking from sleep, starting fan.");
    $sleep = 0;
    fanSpd(1,0);
};

while ($keep_going) {
        if($sleep) { sleep 10; next; }
        my @temps = getTemps();
        my $average = 0;
        my $counter = 0;

        #dirty, swapping to max single core temp instead of average for testing, will fix later    

        my $highest = (sort { $b <=> $a } @temps)[0];

        #foreach (@temps) {
        #    $average += $temps[$counter];
        #    $counter++;
        #}
        #$average = $average/$counter;
    
        $average = $highest;
        if( $average < TEMPS ) {
            fanSpd(0,0);
        } elsif ( $average > TEMPS && $average < TEMPM ){
            fanSpd(1,0);
        } elsif ( $average > TEMPM && $average < TEMPH ){
            fanSpd(0,1);
        } elsif ( $average > TEMPH ){
            fanSpd(1,1);
        } else {
            # Default to fast in case something is a broken.
            fanSpd(1,1);
        }
        sleep 1.0;
}

$log->warning("Stopping gpdfand:  ".time());

sub dienice ($) {
        my ($package, $filename, $line) = caller;
        $log->critical("$_[0] at line $line in $filename");
        die $_[0];
}
