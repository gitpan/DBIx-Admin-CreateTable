#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use DBIx::Admin::CreateTable;

# --------------------------------------------------

$|					= 1;
my($vendor_type)	= 'oracle'; # mysql || oracle || postgres.
my(%db_param)		=
(
	mysql		=> ['dbi:ODBC:my-test', 'testuser', 'testpass', {PrintError => 0, RaiseError => 1}],
	oracle		=> ['dbi:ODBC:or-test', 'testuser', 'testpass', {PrintError => 0, RaiseError => 1}],
	postgres	=> ['dbi:ODBC:pg-test', 'testuser', 'testpass', {PrintError => 0, RaiseError => 1}],
);
my($dbh)				= DBI -> connect(@{$db_param{$vendor_type} });
my($creator)			= DBIx::Admin::CreateTable -> new(dbh => $dbh, verbose => 1);
my($db_vendor)			= $creator -> db_vendor();
my($table_name)			= 'test';
my($primary_index_name)	= $creator -> generate_primary_index_name($table_name);
my($primary_key_sql)	= $creator -> generate_primary_key_sql($table_name);

print "Db vendor: $db_vendor. \n";
print "Primary index name: $primary_index_name. \n";

$creator -> drop_table($table_name);
$creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key_sql,
data varchar(255)
)
SQL

print "\n";
print "Insert test data. \n";
print "\n";

my($sequence_name)	= $creator -> generate_primary_sequence_name($table_name);
my($sth)			= $db_vendor eq 'ORACLE'
				? $dbh -> prepare("insert into $table_name (id, data) values ($sequence_name.nextval, ?)")
				: $dbh -> prepare("insert into $table_name (data) values (?)");
my(@data)	= (qw/One Two Three Four Five/);

$sth -> execute($_) for (@data);

# Test overriding the auto-generated value for a primary key.

$sth = $dbh -> prepare("insert into $table_name (id, data) values (?, ?)");

$sth -> execute(9, 'Nine');
$sth -> finish();

print "Retrieve test data. \n";
print "\n";
print "Expecting: \n";
print "@{[$_ + 1]}. $data[$_]. \n" for (0 .. $#data);
print "9. Nine. \n";
print "\n";
print "Retrieved: \n";

$sth = $dbh -> prepare("select * from $table_name");

$sth -> execute();

my($data);

while ($data = $sth -> fetch() )
{
	print join('. ', @$data), ". \n";
}

print "\n";

#$creator -> drop_table($table_name);

