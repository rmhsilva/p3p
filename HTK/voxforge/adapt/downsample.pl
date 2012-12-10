#!/usr/bin/env perl -w
####################################################################
###
### script name : downsample.pl
### version: 0.2.1
### modified by: Ken MacLean
### mail: kmaclean@voxforge.org
### Date: 2007.12.27
### Command: ./downsample.pl FilesToBeDownsampled filetype(raw/wav) original_sampling_rate targetrate 
###
### Copyright (C) 2006 Ken MacLean
###
### This program is free software; you can redistribute it and/or
### modify it under the terms of the GNU General Public License
### as published by the Free Software Foundation; either version 2
### of the License, or (at your option) any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###                                                                 
####################################################################

use strict;
use File::Spec;

my ($targetrate, $codetrain, $command, $line,  $file, $directories, $volume);
my ($original_file_type, @filename, $original_sampling_rate);

# check usage
if (@ARGV != 4) {
  print "Wrong number of arguments ... usage: $0 FilesToBeDownsampled filetype(raw/wav) original_sampling_rate(Hz) targetrate(Hz)\n\n"; 
  exit (0);
}

# read in command line arguments
($codetrain, $original_file_type, $original_sampling_rate, $targetrate) = @ARGV;

# open files
open (FILEIN,"$codetrain") || die ("Unable to open codetrain $codetrain file for reading");

# process each prompt one at a time
while ($line = <FILEIN>) {
  chomp ($line);
  ($volume,$directories,$file) = File::Spec->splitpath( $line );
  print "downsampling:$file\n";
  
if ($original_file_type eq "wav") {
    $command = ("sox $line -r $targetrate -b 16 \./wav/$file"); system($command) == 0 or die "system $command failed: $?"; 
    } 
    elsif ($original_file_type eq "raw") {
      @filename=split(/./, $file);
      $file=shift (@filename);    	
      $command = ("sox -r $original_sampling_rate -s -b 16 $line -r $targetrate -b 16 \./wav/$file"); system($command) == 0 or die "system $command failed: $?"; 
    } 
    else {
      die ("Error: wrong file type (only \'wav\' or \'raw\' permitted)");
}

} #end of while loop

close(FILEIN);

