#!/usr/bin/perl
#
# Copyright (c) GB Tony Cabrera (firehammer047) 2015
#
use DBI();
use MP3::Info;
use strict;

my $db = "";
my $host = "localhost";
my $user = "";
my $passwd = "";

my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $passwd);

my $dir = $ARGV[0];
my @files = `ls $dir`;
chomp @files;

print "\n";

$dir = trim($dir);

foreach my $file (@files){
	print "Directory: $dir\n";
	print "File: ".$file."\n";
	
	my $path = $dir."/".$file;
	#print "Path: ".$path."\n";

	my $tag = get_mp3tag($path) or next;
	print "Title: ";
	my $title = $tag->{"TITLE"};
	print $title;
	print "\n";
	print "Artist: ";
	my $artist = $tag->{"ARTIST"};
	print $artist;
	print "\n";
	print "Album: ";
	my $album = $tag->{"ALBUM"};
	print $album;
	print "\n";
	print "Genre: ";
	my $genre = $tag->{"GENRE"};
	print $genre;
	print "\n\n";

	my $query = "INSERT INTO music(TITLE,ARTIST,ALBUM,GENRE,FORMAT,BASE_DIR,DIR,FILENAME)
				values (?,?,?,?,?,?,?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute("$title","$artist","$album","$genre",'mp3','/home/cinder/Music/mp3',"$dir","$file");
}

$dbh->disconnect();

sub trim { my $s = shift; $s =~ s/\\//g; return $s };
