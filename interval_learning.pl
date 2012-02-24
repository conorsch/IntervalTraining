#!/usr/bin/perl
#script to facilitate learning of musical intervals. plays two intervals at random (within two octave range) and tests the user
#use strict;
use warnings;
use Getopt::Std;
use threads;
use threads::shared;

my %Options=(); #Create scalar for command-line options

getopts('hvd:r:c:', \%Options); #This style of grabbing doesn't support flag arguments, just flags
my $chord = $Options{c} || 2;
my $verbose = $Options{v} || 0; #Make the script give more feedback;
my $duration = $Options{d} || 1; #Choose how long individual tones are sounded for; default to 1 second 
my $range = $Options{r} || undef; #Determine how far apart notes can be, within a range of r octave(s);
my $help = $Options{h} || 0; 

sub do_help {
    print
"This script generates random musical tones and displays their pitch, in order to aid in memorizing intervals.
Options supported are as follows:

    -v      verbose mode, provides maximum feedback
    -h      display this help message
    -d      duration, choose how long notes ring (in seconds)
    -r      range, how far apart the notes can be, within a range of r octave(s)
    -c      chord, how many notes sound be sounded (defaults to 2)
\n";
    die "Exiting...\n";
}

do_help if ($help == 1);

if ($verbose == 1) {
    print "Verbose option enabled, providing detailed information.\n";
    print "Notes will ring for $duration seconds.\n";
    print "Notes will be selected from a range of $range octaves.\n";
    print "Up to $chord notes will be sounded together simultaneously.\n";
}
my @letters = (A..G);
my @octaves = (1..7);
my @allnotes;

sub generate_note {
    my $letter = $letters[int rand($#letters)]; 
    my $octave = shift || $octaves[int rand($#octaves)] ;
#    print "Inside gen_note, octave pulled from func call is $octave\n" if ($verbose == 1);
    my $note = "$letter$octave"; 
    return $note;
}
sub play_note {
    my $note = shift;
    `play -q -n synth $duration pluck $note`;
}
sub interval_test {
    my @chord;
    my $octave = $octaves[int rand($#octaves)];
#   print "Inside interval test, the randomly generated octave was: $octave\n";
    foreach my $note (1..$chord) {
        $note = generate_note($octave);
        push @chord,$note;
    }
    while (1) {
        foreach my $note (@chord) {
            print "Playing single note $note...\n";
            play_note($note);
        }
        if ($chord > 1) {
            print "Playing chord of all notes.. (@chord).\n";
            foreach my $note (@chord) {
                threads->create(\&play_note,$note);
            }
        }
        sleep 5;
    }
}
interval_test;
