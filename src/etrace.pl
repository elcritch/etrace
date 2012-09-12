#!/usr/bin/perl
#
# etrace.pl script
# Author: Victor Chudnovsky
# Date: March 8, 2004

use strict;
use warnings "all";

our $NM  = 'nm ';     # unix nm utility to get symbol names and addresses

# Output format
our $TAB1 = "|   ";            # indentation: function still on the stack   
our $TAB2 = "\\-- ";           # indentation: function just placed on the stack
our $UNDEFINED_SYMBOL = "???"; # when an offset cannot be mapped to a symbol

# Input format
our $FIFO_NAME = "TRACE";             # default FIFO name
our $REFERENCE_OFFSET = "REFERENCE:"; # marks a known symbol/object pair for dynamic libraries
our $FUNCTION_ENTRY = "enter";        # marks entry into a function
our $FUNCTION_EXIT  = "exit";         # marks exit from function
our $END_TRACE      = "EXIT";         # end of input
our $HEX_NUMBER = '0?x?[0-9a-fA-F]+'; # hex number
our $SYMBOL_NAME = '[\w@.]+';         # valid identifier characters

# Global identifiers
our %SYMBOLTABLE; # : a hash array from relative offsets to symbol names
our $IS_FIFO; # :     are we reading from a FIFO or a file?
#our CALL_DATA; # :    file handle to input file/FIFO

sub readObjects {
    my $objectFileName = shift;
    my $handleName;
    if (-x $objectFileName) {
	# Object code: extract symbol names via a pipe before parsing
	$handleName = $NM.$objectFileName.'|';
    } else {
	# A symbol table: simply parse the symbol names
	$handleName = '<'.$objectFileName;
    };
    open obj_file, $handleName or die "$0: cannot open $objectFileName";
    my $line;
    while ($line = <obj_file>) {
	$line =~  m/^($HEX_NUMBER)\s+.*\s+($SYMBOL_NAME)$/;
	my $hexLocation = $1;
	my $symbolName = $2;
	my $location = hex $hexLocation;
	$SYMBOLTABLE{$location} = $2
	}
    close obj_file;
}

sub writeSymbolTable {
    my $location, my $name;
    while ( ($location,$name) = each %SYMBOLTABLE) {
	print "[$location] => $name\n";
    }
}; 

sub establishInput {
    my $inputName = shift;
    if (!defined($inputName)) {
	$inputName = $FIFO_NAME;
    };
    if (-p $inputName) {
	# delete a previously existing FIFO
	unlink $inputName;
    };
    if (!-e $inputName) {
	# need to create a FIFO
	system('mknod', $inputName, 'p') && die "$0: could not create FIFO $inputName\n";
	$IS_FIFO = 1;
    } else {
	# assume input comes from a file
	die "$0: file $inputName is not readable" if (!-r $inputName);
	$IS_FIFO = 0;
    }
    $inputName; # return value
}

sub deleteFifo {
    if ($IS_FIFO) {
	my $inputName = shift;
	unlink $inputName or die "$0: could not unlink $inputName\n";
    };
};


sub processCallInfo {
    my $offsetLine = <CALL_DATA>;
    my $baseAddress;
    if ($offsetLine =~ m/^$REFERENCE_OFFSET\s+($SYMBOL_NAME)\s+($HEX_NUMBER)$/) {
	# This is a dynamic library; need to calculate the load offset
	my $offsetSymbol  = $1;
	my $offsetAddress = hex $2;

	my %offsetTable = reverse %SYMBOLTABLE;
	$baseAddress = $offsetTable{$offsetSymbol} - $offsetAddress;
	$offsetLine = <CALL_DATA>;
    } else {
	# This is static
	$baseAddress = 0;
    }
    
    my $level = 0;
    while (!($offsetLine =~/^$END_TRACE/)) {
	if ($offsetLine =~ m/^($FUNCTION_ENTRY|$FUNCTION_EXIT)\s+($HEX_NUMBER)$/) {
	    my $action = $1;
	    my $offset = hex $2;
	    my $address = $offset + $baseAddress;
	    if ($1=~m/$FUNCTION_ENTRY/) {
		my $thisSymbol = $SYMBOLTABLE{$offset+$baseAddress};
		if (! defined($thisSymbol)) {
		    $thisSymbol = $UNDEFINED_SYMBOL;
		};
		print $TAB1 x $level . $TAB2 . $thisSymbol . "\n";
		$level++;
	    } else {
		$level--;
	    }
	} else {
	    if ( (length $offsetLine) > 0 ) {
		chomp $offsetLine;
		print "Unrecognized line format: $offsetLine\n";
	    };
	}
    $offsetLine = <CALL_DATA>;	
    };
}



# Main function
if (@ARGV==0) {
    die "Usage: $0 OBJECT [TRACE]\n" .
	"       OBJECT is either the object code or the output of $NM\n" .
	"       TRACE is either the etrace output file or of a FIFO to connect to etrace.\n";
};

my $objectFile = shift @ARGV;
my $inputFile = shift @ARGV;

readObjects $objectFile;

$inputFile = establishInput $inputFile;

open CALL_DATA,"<$inputFile";
processCallInfo;
close CALL_DATA;

deleteFifo $inputFile;
