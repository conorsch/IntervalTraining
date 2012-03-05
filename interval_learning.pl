#!/usr/bin/perl
#This script is designed to facilitate the learning of musical intervals.
#It plays (currently only) two intervals at random and asks the user to identify the interval by typing it in.
use strict;
use warnings;
#use diagnostics;
use Getopt::Std; #Allow for command line argument parsing;
use threads; #Necessary to allow playing of chords (multiple notes simultaneously);
use threads::shared; #Necessary to allow threads to inherit variables from elsewhere in script;
use Term::ReadKey;
no warnings 'threads'; #This doesn't seem to stop the threads warning from chord playing; probably a scoping issue;
use feature "switch";

my @dependencies = qw/sox/; #List out all package dependencies here, to check before running actual script;
my %Options=(); #Create hash for command-line options
getopts('hbvd:r:c:', \%Options); #See do_help for explanation of these flags;
my $chord = $Options{c} || 2; #Allow user to set number of notes to analyze; default is 2;
my $verbose = $Options{v} || 0; #Make the script give more feedback;
my $duration = $Options{d} || 1; #Choose how long individual tones are sounded for; default to 1 second 
my $range = $Options{r} || 1; #Determine how far apart notes can be, within a range of r octave(s);
my $help = $Options{h} || 0; #If -h flag is declared, show help info (which ends in exit);
my $debugging = $Options{b} || 0; #If -b flag is declared, enable debugging mode (more verbose);
$verbose = 1 if ($debugging == 1); #Maximum output for debugging, shouldn't have to type both -v and -b flags.

sub do_help { #Display usage information;
    print
"This script generates random musical tones and displays their pitch, in order to aid in memorizing intervals.
Options supported are as follows:

    -v      verbose mode, provides maximum feedback
    -h      display this help message
    -d      duration, choose how long notes ring (in seconds)
    -r      range, how far apart the notes can be, within a range of r octave(s)
    -c      chord, how many notes sound be sounded (defaults to 2)
    -b      debugging, extra verbose output for troubleshooting functionality
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
#system ("synergyc --yscroll 29 $connect_to"); #Run the connection, using the target machine grabbed as shift;
sub check_dependencies {
    print "Now entering check_dependencies subroutine...\n" if ($debugging == 1);
    foreach my $package (@dependencies) {
        my $result = system("which $package"); #Necessary to use system() rather than backticks so exit code is grabbed properly;
        if ($result == 0) { #Exit code of 0 means program is reported as installed;
            print "It appears that the package $package is installed! Continuing...\n" if ($verbose == 1);
            next; #Move onto checking next package in list of dependencies;
        }
        else {
            die "Unsatisfied dependency. Please make sure you have the $package package installed.\nExiting...\n";
        }
    }
}
my @letters = qw/C D E F G A B/; #Initialize array of standard musical notation letters, A through G
my @flats = qw/Db Eb Gb Ab Bb/; #Initialize array of flats, for use
#my @sharps = qw/A# C# D# F# G#/; #Not using quick qw/ declaration because use::strict warns about possible comments;
my @sharps = ("C#", "D#", "F#", "G#", "A#"); #Initialize array of sharp notations, for a little variety;
my @octaves = (2..6); #Select possible range of octaves for tone generation; "range" flag adjusts this
my @allnotes; #Could be useful to have an array of all possible notes and draw from that for generate_note;
push(@allnotes,@letters); #Stock our combined array to have the non-sharps;
push(@allnotes,@sharps); #Add to our combined array the sharp notes, bringing the total note count to 12 (one octave);
my @allnotes_sorted = sort {lc($a) cmp lc($b) } @allnotes; #We want to make sure the notes are arranged in sequential order;
my %allnotes = (
        "C" =>  0,
        "C#" =>  1,
        "D" =>  2,
        "D#" => 3,
        "E" => 4,
        "F"=> 5,
        "F#" => 6,
        "G" => 7,
        "G#" => 8,
        "A" => 9,
        "A#" => 10,
        "B" => 11,
        "C" => 12,
        );
my %intervals = (
        0 => "root",
        1 => "minor second",
        2 => "major second",
        3 => "minor third",
        4 => "major third",
        5 => "perfect fourth",
        6 => "tritone",
        7 => "perfect fifth",
        8 => "minor sixth",
        9 => "major sixth",
        10 => "minor seventh",
        11 => "major seventh",
        12 => "octave",
        );
sub generate_note {
    print "Now entering generate_note subroutine...\n" if ($debugging == 1);
    my $letter = $allnotes_sorted[int rand($#allnotes_sorted)]; #Find random letter by plugging in a random value no greater than array size
    my $octave = shift || $octaves[int rand($#octaves)]; #If octave declared, use it, else find random letter by plugging in a random value no greater than array size
    my $note = "$letter$octave"; #Stich letter and octave together to make a note to feed into play_note;
    return $note; #Pass generated note to whatever called it, for use in play_note;
}
sub play_note {
    my $note = shift; #Grab desired note from function call, name it accordingly;
    #Might later add functionality to customize the `play` command and allow choice of instruments, etc.
    `play -q -n synth $duration pluck $note`; #Play it by calling "play" shell command (requires sox);
}
sub determine_interval {
    print "Now entering determine_interval subroutine...\n" if ($debugging == 1);
    my @notes = @{(shift)}; #Wacky shift packaging necessary to handle array supplied during function call;
    my $total = scalar(@notes); #Store total number of notes;
    if ($total == 1) { #If only one note is to be played, no interval can be named;
        print "There was only one note sounded, therefore no interval can be defined. The note was @notes.\n";
        return;
   }
    elsif ($total == 2) {
        print "A total of $total notes will be played, specifically: @notes\n" if ($verbose == 1);
        my @notes_semitones; #Initialize array for storing of ordinal semitone values;
        foreach my $note (@notes) { #Necessary to declare parent subroutine for proper scope;
            my $letter = $1 if ($note =~ /(^.{1,2})(\d{1})$/i); #Grab first one or two characters (so A as well as A# is found);
            my $octave = $1 if ($note =~ /(\d{1}$)/); #Grab final number, which designates octave frequency
            my $semitone = $allnotes{$letter};# or die "IMPOSSIBLE TO DECLARE SEMITONE\n";
            push @notes_semitones,$semitone; #Store this so we can look at the values later;
        }
        my $tone1 = $notes_semitones[0]; #Grab the first note of the pair, find its distance in halfsteps from C;
        my $tone2 = $notes_semitones[1];#Grab the first note of the pair, find its distance in halfsteps from C;
        my $distance = abs($tone1 - $tone2); #Find absolute value of distance between these notes (doesn't work for root/octave...);
        my $direction; #Was the second interval lower or higher than the first? 
        if ($tone1 <  $tone2) { #If the second tone was higher;
           $direction = "higher"; #then set direction to "higher";
        }
        elsif ($tone1 > $tone2) { #If the second down was lower;
            $direction = "lower"; #then set direction to "lower";
        }
        elsif ($tone1 = $tone2) { #If the two notes were the same
            $direction = ""; #Do nothing. Might need to undef or 
        }
        else {
            print "Unsure how to parse interval. Exiting.\n"; #This shouldn't come up ever, but might help during debugging;
            return; #Get out of here;
        }
        my $interval = $intervals{$distance}; #Plug the distance (in half steps) into intervals hash, get name of interval;
        my $result = "$interval $direction"; #Stich together both the interval name and the direction, and that's our product;
        return $result; #Pass determined interval back to what called for it;
    }
    elsif ($total > 2) { #If there are more than two notes fed into determine_interval;
        print "Current this script does not support identifying chord shapes. Please try again with just 2 notes.\n";
        return; #Exit; more functionality should be added here in the future;
    }
    else { #As yet unforeseen corner case;
        print "Something went awry while determining the interval between these notes: @notes\n"; #This is just a backup; shouldn't ever be displayed;
    }
}
sub interval_test {
    print "Now entering interval_test subroutine...\n" if ($debugging == 1);
    my @chord; #Initialize array to store all notes we'll generate;
    my $octave = $octaves[int rand($#octaves)]; #Find random octave in our set; range flag will deviate from this value;
    print "Inside interval test, the randomly generated octave was: $octave\n" if ($debugging == 1);
    foreach my $note (1..$chord) { #Perhaps this $chord should be renamed to "$count" so as not to be confused with "@chord"?;
        $note = generate_note($octave); #Call the generate_note function, with designated octave (which will be the same for both);
        push @chord,$note; #Store generated note in our chord array;
    }
    my $interval = determine_interval(\@chord); #Pass list of generated notes to determine_interval, store the answer;
    print "The interval is a $interval\n" if ($verbose == 1); #Add a command line flag for hints? Verbose flag might not be best fit here;
    playnote: while (1) { #Loop indefinitely until user declares stop;
        foreach my $note (@chord) { #Look at all generated notes in our "chord" array;
            print "Playing single note $note...\n" if ($verbose == 1); #Add a command line flag for hints? Verbose flag might not be best fit here;
            play_note($note); #Play single note from chord;
        }
        if ($chord > 1) { #If number of notes is plural, then prepare to sound all notes simultaneously;
            print "Playing chord of all notes.. (@chord).\n" if ($verbose == 1);
            foreach my $note (@chord) {
                threads->create(\&play_note,$note); #Thread necessary to play different notes simultaneously; They aren't closing neatly, however;
            }
        }
        my $attempt = get_answer();
        print "The attempt and interval are: $attempt and $interval\n" if ($debugging == 1);
        given ($attempt) {
            when ($attempt = 0) {
                print "Playing the notes again.\n";
                next playnote; #Return to top of while loop;
            }
            when ($attempt =~ m/^$interval$/) {
                print "You are correct!\n";
            }
            default {
                print "Sorry, try again.\n";
                next playnote; #Return to top of while loop;
            }
        }
        last playnote; #Allow the program to exit cleanly (future versions should allow for more intervals);
    }
}
sub get_answer {
    print "Now entering get_keystrokes...\n" if ($debugging == 1);
    print "Please enter the interval now: "; #Instruct the user to enter an attempt at identifying the interval;
    chomp (my $answer = <STDIN>); #Grab input from command line;
    return $answer; #Pass user-specified response back to process that called for it;
}
check_dependencies; #Let's make sure the script can run;
interval_test; #Run the meat of the script to do the test;
