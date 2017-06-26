#!/usr/bin/perl

use strict;
use warnings;

use constant LOG_DIR    => '/var/log/gpdfand';
use constant LOG_FILE   => 'gpdfand.log';
use constant PIDDIR     => '/var/run';
use constant TEMPS      => 40;
use constant TEMPM      => 50;
use constant TEMPH      => 60;

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
        my $corefh;
        open($corefh, "<", "/sys/class/hwmon/hwmon4/temp2_input");
        $tmp[0] = <$corefh> / 1000;
        close($corefh);
        open($corefh, "<", "/sys/class/hwmon/hwmon4/temp3_input");
        $tmp[1] = <$corefh> / 1000;
        close($corefh);
        open($corefh, "<", "/sys/class/hwmon/hwmon4/temp4_input");
        $tmp[2] = <$corefh> / 1000;
        close($corefh);
        open($corefh, "<", "/sys/class/hwmon/hwmon4/temp5_input");
        $tmp[3] = <$corefh> / 1000;
        close($corefh);
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

        if( $temps[0] < TEMPS && $temps[1] < TEMPS && $temps[2] < TEMPS && $temps[3] < TEMPS ) {
                fanSpd(1,0);
        }
        elsif ( $temps[0] < TEMPM && $temps[1] < TEMPM && $temps[2] < TEMPM && $temps[3] < TEMPM ) {
                fanSpd(0,1);
        }
        elsif ( $temps[0] < TEMPH && $temps[1] < TEMPH && $temps[2] < TEMPH && $temps[3] < TEMPH ) {
                fanSpd(1,1);
        }
        else {
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
