#!/usr/bin/perl
#
# musicd-server.pl
# Copyright (c) GB Tony Cabrera (firehammer047) 2015
#
# Changelog
#
# 1.2.5
# added skip/remove from playlist functionality
# 1.2.4
# added filename query
# 1.2.3
# added volume control and other actions


my $DEBUG = 0;

my $HOST = '192.168.1.112'; #sasquatch
#my $HOST = '192.168.43.221'; 
#my $HOST = '127.0.0.1';

my $PORT = '6969';

my $VERSION = "1.2.5";
print "musicd-server v$VERSION \n";

use strict;
use IO::Socket::INET;
use DBI();

my $db = "";
my $host = "localhost";
my $user = "";
my $passwd = "";

my $dbh;
my $query;
my $sth;

#START SERVER
# creating a listening socket
my $socket = new IO::Socket::INET (
	LocalHost => $HOST,
	LocalPort => $PORT,
	Proto => 'tcp',
	Listen => 5,
	Reuse => 1
);
die "cannot create socket $!\n" unless $socket;
print "Listening on $HOST:$PORT\n";

open(my $pipe, ">", "pipe");

while(1){
	
	my $reply = "OK";

	# waiting for a new client connection
	my $client_socket = $socket->accept();
		
	# get information about a newly connected client
	my $client_address = $client_socket->peerhost();
	my $client_port = $client_socket->peerport();
	print "Connection from $client_address:$client_port\n";

	my $data = "";
	$client_socket->recv($data, 1024);

	my $command = substr($data,0,-2);
	
	if($command eq "exit"){
		last;
	}
	if($command eq "quit"){
		last;
	}
	if($command eq "q"){
		last;
	}
	
	select($pipe);
	# autoflush
	$| = 1;
	
	if($command eq "p"){
		print $pipe "pause\n";
		print STDOUT "==== PAUSE ====\n";
	}
	if($command eq "rr"){
		print $pipe "seek 0 2\n";
		print STDOUT "==== REWIND ====\n";
	}
	# Flag this song as skipped
	if($command eq "n"){
		open(my $fh, "<", "ipc.txt");
		(my $song_id, my $song_filename) = split(":",readline($fh));
		close($fh);
		$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $passwd);
		$query = "SELECT SKIP FROM music WHERE ID=$song_id";
		$sth = $dbh->prepare($query);
		$sth->execute();
		my $ref = $sth->fetchrow_hashref();
    	my $skips = $ref->{'SKIP'};
    	if ($DEBUG){print STDOUT "Song skipped '$ref->{'SKIP'}' times.\n";}
		$sth->finish();
		$dbh->disconnect();
		
		if ($skips < 2){
			print STDOUT "Flagging song $song_id as skipped.\n";
			$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $passwd);
			$query = "UPDATE music SET SKIP=SKIP+1 WHERE ID=$song_id";
			$sth = $dbh->prepare($query);
			$sth->execute();
			$sth->finish();
			$dbh->disconnect();
		}
		if ($skips == 2){
			print STDOUT "Removing song $song_id from playlist.\n";
			$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $passwd);
			$query = "UPDATE music SET ACTIVE=0 WHERE ID=$song_id";
			$sth = $dbh->prepare($query);
			$sth->execute();
			$sth->finish();
			$dbh->disconnect();
		
		}
		print $pipe "stop\n";
	}
	if($command eq ""){
		print $pipe "stop\n";
	}
	#######################
	if($command eq "x"){
		# Change file flag
		open(my $fh, "<", "ipc.txt");
		(my $song_id, my $song_filename) = split(":",readline($fh));
		close($fh);
		print STDOUT "Removing song $song_id from playlist.\n";
		$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $passwd);
		$query = "UPDATE music SET ACTIVE=0 WHERE ID=$song_id";
		$sth = $dbh->prepare($query);
		$sth->execute();
		$sth->finish();
		$dbh->disconnect();
		print $pipe "stop\n";
	}
	if($command eq "dd"){
		# Change file flag
		open(my $fh, "<", "ipc.txt");
		(my $song_id, my $song_filename) = split(":",readline($fh));
		close($fh);
		print STDOUT "Deleting song $song_id permenantly.\n";
		$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $passwd);
		$query = "DELETE FROM music WHERE ID=$song_id";
		$sth = $dbh->prepare($query);
		$sth->execute();
		$sth->finish();
		$dbh->disconnect();
		print $pipe "stop\n";
		my $out = `rm -v "$song_filename"`;
		print STDOUT $out;
	}
	if($command eq "b"){
		print STDOUT "==== PREVIOUS ====\n";
		open(my $fh, ">", "ipc.txt");
		print $fh "PREVIOUS";
		close($fh);
		print $pipe "stop\n";
	}
	if($command eq "vol70"){
		my $out = `amixer -D pulse sset Master 70%`;
		print STDOUT $out;
	}
	if($command eq "vol100"){
		my $out = `amixer -D pulse sset Master 100%`;
		print STDOUT $out;
	}
	if($command eq "filename"){
		# get filename
		open(my $fh, "<", "ipc.txt");
		(my $song_id, my $song_filename) = split(":",readline($fh));
		close($fh);
		
		my @path = split("/",$song_filename);
		my $s1 = $path[-1];
		my $s2 = $path[-2];
		$reply = $s2."/".$s1;
	}

	select(STDOUT);
	
	$client_socket->send($reply."\r\n");
	# notify client that response has been sent
	shutdown($client_socket, 1);
	print "Connection closed.\n";
}
$socket->close();
close($pipe);