#!/usr/bin/perl
#script to facilitate learning of musical intervals. plays two intervals at random (within two octave range) and tests the user
use strict;
use warnings;
use Getopt::Std; #Allow for command line argument parsing;
use threads; #Necessary to allow playing of chords (multiple notes simultaneously);
use threads::shared; #Necessary to allow threads to inherit variables from elsewhere in script;

my @dependencies = qw/sox/; #List out all package dependencies here, to check before running actual script;
my %Options=(); #Create hash for command-line options
getopts('hvd:r:c:', \%Options); #See do_help for explanation of these flags;
my $chord = $Options{c} || 2; #Allow user to set number of notes to analyze; default is 2;
my $verbose = $Options{v} || 0; #Make the script give more feedback;
my $duration = $Options{d} || 1; #Choose how long individual tones are sounded for; default to 1 second 
my $range = $Options{r} || undef; #Determine how far apart notes can be, within a range of r octave(s);
my $help = $Options{h} || 0; #If -h flag is declared, show help info (which ends in exit);

sub do_help { #Display usage information;
    print
"This script generates random musical tones and displays their pitch, in order to aid in memorizing intervals.
Options supported are as follows:

    -v      verbose mode, provides maximum feedback
    -h      display this help message
    -d      duration, choose how long notes ring (in seconds)
    -r      range, how far apart the notes can be, within a range of r octave(s)
    -c      chord, how many notes sound be sounded (defaults to 2)
\n";
    die "Exiting...\n"; #Close out, so user can rerun script with desired functionality;
}
do_help if ($help == 1); #Catch help flag, run do_help (then exit);

if ($verbose == 1) { #If verbose is enabled, then provide feedback about other flags.
    print "Verbose option enabled, providing detailed information.\n";
    print "Notes will ring for $duration seconds.\n";
    print "Notes will be selected from a range of $range octaves.\n";
    print "Up to $chord notes will be sounded together simultaneously.\n";
}
sub check_dependencies {
    foreach my $package (@dependencies) {
        my $result = system("which $package"); #Necessary to use system() rather than backticks so exit code is grabbed properly;
        if ($result == 0) { #Exit code of 0 means program is reported as installed.
            print "It appears that the package $package is installed! Continuing...\n" if ($verbose == 1);
            next;
        }
        else {
            die "Unsatisfied dependency. Please make sure you have the $package package installed.\nExiting...\n";
        }
    }
}

my @letters = ("A".."G"); #Initialize array of standard musical notation letters, A through G
my @flats = qw/Bb Db Eb Gb Ab/;
#my @sharps = qw/A# C# D# F# G#/;
my @sharps = ("A#", "C#", "D#", "F#", "G#"); #Not using quick qw/ declaration because use::strict warns about possible comments;
my @octaves = (1..7); #Select possible range of octaves for tone generation; "range" flag adjusts this
my @allnotes; #Could be useful to have an array of all possible notes and draw from that for generate_note;

sub generate_note {
    my $letter = $letters[int rand($#letters)]; #Find random letter by plugging in a random value no greater than array size
    my $octave = shift || $octaves[int rand($#octaves)]; #If octave declared, use it, else find random letter by plugging in a random value no greater than array size
#    print "Inside gen_note, octave pulled from func call is $octave\n" if ($verbose == 1);
    my $note = "$letter$octave"; #Stich letter and octave together to make a note to feed into play_note;
    return $note; #Pass generated note to whatever called it, for use in play_note;
}
sub play_note {
    my $note = shift; #Grab desired note from function call, name it accordingly;
    `play -q -n synth $duration pluck $note`; #Play it by calling "play" shell command (requires sox);
}
sub interval_test {
    my @chord; #Initialize array to store all notes we'll generate;
    my $octave = $octaves[int rand($#octaves)]; #Find random octave in our set; range flag will deviate from this value;
#   print "Inside interval test, the randomly generated octave was: $octave\n";
    foreach my $note (1..$chord) {
        $note = generate_note($octave);
        push @chord,$note;
    }
    while (1) { #Loop indefinitely until user declares stop;
        foreach my $note (@chord) { #Look at all generated notes in our "chord" array;
            print "Playing single note $note...\n";
            play_note($note); #Play single note from chord;
        }
        if ($chord > 1) {
            print "Playing chord of all notes.. (@chord).\n";
            foreach my $note (@chord) {
                threads->create(\&play_note,$note); #Thread necessary to play different notes simultaneously;
            }
        }
        sleep 5; #Rest a moment before repeating;
    }
}
check_dependencies; #Let's make sure the script can run;
interval_test; #Run the meat of the script to do the test;
