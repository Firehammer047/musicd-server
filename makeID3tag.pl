#!/usr/bin/perl
#
# Copyright (c) GB Tony Cabrera (firehammer047) 2015
#

use MP3::Info;
use strict;

my $filepath = $ARGV[0];
print "\n";
my $line;

(my $dir, my $file) = split("/",$filepath);

$file = trim($file);

(my $artist, my $title) = split("-",$file);
$title = substr($title,0,-4);
$artist = strip($artist);
$title = strip($title);

print "Artist: $artist:";
$line = <STDIN>;
if ($line ne "\n"){
	$artist = substr($line,0,-1);
}

print "Title: $title:";
$line = <STDIN>;
if ($line ne "\n"){
	$title = substr($line,0,-1);
}

my $album="";
print "Album:";
$line = <STDIN>;
if ($line ne "\n"){
	$album = substr($line,0,-1);
}

my $genre="";
print "Genre:";
$line = <STDIN>;
if ($line ne "\n"){
	$genre = substr($line,0,-1);
}

set_mp3tag($filepath,$title,$artist,$album,"","",$genre);
print "ID3 tag written. \n";

sub trim { my $s = shift; $s =~ s/\\//g; return $s };
sub strip { my $s = shift; $s =~ s/_/ /g; return $s };
