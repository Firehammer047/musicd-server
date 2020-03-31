#!/usr/bin/perl
#
# musicd.pl
# Copyright (c) GB Tony Cabrer (firehammer047) 2015
#
my $DEBUG = 0;

my $VERSION = "1.2.3";
print "musicd v$VERSION \n";

use strict;
use DBI();

my $db = "";
my $host = "localhost";
my $user = "";
my $passwd = "";


my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $passwd);

my $field = $ARGV[0];
my $like = $ARGV[1];

my $query = "SELECT * FROM music WHERE ACTIVE=1";
if ($field ne ""){
    $query .= " AND $field LIKE '%$like%'";
}
my $sth = $dbh->prepare($query);

$sth->execute();

my @songs;
my $count=0;

while (my $ref = $sth->fetchrow_hashref()){
    if ($DEBUG){print "Found song '$ref->{'TITLE'}'\n";}
    push(@songs,$ref);
    $count++;
}
$sth->finish();
$dbh->disconnect();

#RANDOMIZE
my $id = int(rand($count));

my @pl;
my @flags = (0) x $count;

for(my $i=0; $i<$count; $i++){
    my $tries = 0;
    while($flags[$id]){
        if($DEBUG){print "ID: $id\n";}
        $id = int(rand($count));
        $tries++;
        if($tries == 10000){
            print "We died!!!!!!!\n";
            exit();
        }
    }
    $flags[$id] = 1;
    $pl[$i] = $id;
    if($DEBUG){print "##########################\n";}
}

system("mplayer -quiet -slave -idle 1>/dev/null 2>/dev/null < pipe &");
open(my $pipe, ">", "pipe");
print $pipe "quit\n";

for(my $i=0;$i<$count;$i++){
	open(my $fh, "<", "ipc.txt");
	my $command = readline($fh);
	close($fh);
	if($command eq "PREVIOUS"){
		$i = $i-2;
		if($i<0){$i = 0;}
	}
    $id = $pl[$i];
    my $hash = $songs[$id];
	my $song_id = $hash->{'ID'};
    my $song = $hash->{'BASE_DIR'}."/".$hash->{'DIR'}."/".$hash->{'FILENAME'};
	open(my $fh, ">", "ipc.txt");
	print $fh $song_id.":".$song;
	close($fh);
    print "Playing $song \n";

    my $out = `mplayer -quiet -slave \"$song\" 1>/dev/null 2>/dev/null < pipe`;
}
close($pipe);
print "Done.\n"

