#!/usr/bin/perl -w

use Doc::Kadoc;
use Doc::Kadoc::Josef;

use strict;
use warnings;
use 5.010;

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

use constant HEADER => "===============================\n            KADOC           \n===============================\n\n";

my %options=();
getopts("hvo:", \%options);

if ( $options{h} )
{
    print HEADER;
    print "KADOC is a Karel documentation generator.\n";
    print "Input a file\n";
    print "kadoc.pl <karelfilepath> -o output\n";
    print "options:\n";
    print "\n";
}

if ( $options{v} ){
    print HEADER;
    print "VERSION: ", $Doc::Kadoc::VERSION, "\n\n";
}

my $output_path;
if ( $options{o} ) {
    $output_path = $options{o};
} else {
    use Cwd qw(cwd getcwd);
    $output_path = getcwd;
}

my $inputfile = "";
if( defined $ARGV[0] ) {
    print HEADER;
    $inputfile = $ARGV[0];
}

#
# start building kadoc
if($inputfile){

    print "\nread file: ", $inputfile, "\n";

    # open the input file
    open FILE, $inputfile or die $!;
    # copy the lines into an array
    my @lines = <FILE>;
    # close the file
    close( FILE );

    print "start parser\n";
    my ($routine_tmp, $program_tmp) = Doc::Kadoc::Josef::parser(@lines);

    my @routines = @{$routine_tmp};
    my %program = %{$program_tmp};

    print "start template system\n";
    # after having colleectred all data
    use Template;
    
    print "set output path to: ", $output_path, "\n";
    my %ttopt = (INCLUDE_PATH => './template',
                 OUTPUT_PATH  => $output_path);

    my $tt = Template->new(\%ttopt);

    my @prog_authors = @{ $program{"authors"} };
    my @prog_todos = @{ $program{"todos"} };
    my @ttroutines;

    ## build routine
    for (my $i = 0; $i <= $#routines; $i++) {
        my %tmp = %{ $routines[$i] };
        my %tmp_ret = %{ $tmp{"return"} };
        my @tmp_authors = @{ $tmp{"authors"} };
        my @tmp_todo = @{ $tmp{"todos"} };
        my @tmp_params = @{ $tmp{"params"} };

        push @ttroutines, {
            title => $tmp{"title"},
            brief => $tmp{"brief"},
            description => $tmp{"discription"},
            date => $tmp{"date"},
            ret => { datatype => $tmp_ret{"datatype"},
                     datavalue => $tmp_ret{"datavalue"}, },
            authors => \@tmp_authors,
            params => \@tmp_params,
            todos => \@tmp_todo,
        };
    }

    my %ttvars = (
        title        => $program{"title"},
        brief        => $program{"brief"},
        todos        => \@prog_todos,
        comment      => $program{"discription"},
        license      => $program{"license"},
        file_name    => $program{"filename"},
        authors      => \@prog_authors,
        copyright    => $program{"copyright"},
        date         => $program{"date"},
        first_author => $prog_authors[0],
        routines     => \@ttroutines,);

    print "build index.html\n";
    $tt->process("index.tt", \%ttvars, "index.html") or die $tt->error;
    print "finish\n";
}
