package DBIx::Admin::CreateTable;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

use Carp;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Admin::CreateTable ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '2.00';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_db_vendor => '',
		_dbh       => '',
		_verbose   => 0,
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}

} # End of encapsulated class data.

# --------------------------------------------------

sub create_table
{
	my($self, $sql, $arg) = @_;
	my($table_name)       = $sql;
	$table_name           =~ s/^\s*create\s+table\s+([a-z_]+).+$/$1/is;

	$arg = {}                             if (! defined $arg);
	$$arg{$table_name} = {}               if (! defined $$arg{$table_name});
	$$arg{$table_name}{'no_sequence'} = 0 if (! defined $$arg{$table_name}{'no_sequence'});

	if (! $$arg{$table_name}{'no_sequence'})
	{
		my($sequence_name) = $self -> generate_primary_sequence_name($table_name);

		if ($sequence_name)
		{
			my($sql) = "create sequence $sequence_name";

			$$self{'_dbh'} -> do($sql);

			print STDERR __PACKAGE__, ". SQL: $sql. \n" if ($$self{'_verbose'});

			if ($$self{'_dbh'} -> errstr() )
			{
				return $$self{'_dbh'} -> errstr(); # Failure.
			}

			print STDERR __PACKAGE__, ". Created sequence '$sequence_name'. \n" if ($$self{'_verbose'});
		}
	}

	$$self{'_dbh'} -> do($sql);

	print STDERR __PACKAGE__, ". SQL: $sql. \n" if ($$self{'_verbose'});

	if ($$self{'_dbh'} -> errstr() )
	{
		return $$self{'_dbh'} -> errstr(); # Failure.
	}

	print STDERR __PACKAGE__, ". Created table '$table_name'. \n" if ($$self{'_verbose'});

	return ''; # Success.

} # End of create_table.

# --------------------------------------------------

sub db_vendor
{
	my($self) = @_;

	return $$self{'_db_vendor'};

} # End of db_vendor.

# --------------------------------------------------

sub drop_table
{
	my($self, $table_name, $arg) = @_;
	my($sequence_name)           = $self -> generate_primary_sequence_name($table_name);

	# Turn off RaiseError so we don't error if the sequence and table being deleted do not exist.

	local $$self{'_dbh'}{'RaiseError'};

	$arg = {}                             if (! defined $arg);
	$$arg{$table_name} = {}               if (! defined $$arg{$table_name});
	$$arg{$table_name}{'no_sequence'} = 0 if (! defined $$arg{$table_name}{'no_sequence'});

	my($sql);

	# For Oracle, drop the sequence before dropping the table.

	if ( ($$self{'_db_vendor'} eq 'ORACLE') && ! $$arg{$table_name}{'no_sequence'})
	{
		$sql = "drop sequence $sequence_name";

		$$self{'_dbh'} -> do($sql);

		print STDERR __PACKAGE__, ". SQL: $sql. \n" if ($$self{'_verbose'});
		print STDERR __PACKAGE__, ". Dropped sequence '$sequence_name'. \n" if ($$self{'_verbose'});
	}

	$sql = "drop table $table_name";

	$$self{'_dbh'} -> do($sql);

	print STDERR __PACKAGE__, ". SQL: $sql. \n" if ($$self{'_verbose'});
	print STDERR __PACKAGE__, ". Dropped table '$table_name'. \n" if ($$self{'_verbose'});

	# For Postgres, drop the sequence after dropping the table.

	if ( ($$self{'_db_vendor'} eq 'POSTGRESQL') && ! $$arg{$table_name}{'no_sequence'})
	{
		$sql = "drop sequence $sequence_name";

		$$self{'_dbh'} -> do($sql);

		print STDERR __PACKAGE__, ". SQL: $sql. \n" if ($$self{'_verbose'});
		print STDERR __PACKAGE__, ". Dropped sequence '$sequence_name'. \n" if ($$self{'_verbose'});
	}

	return '';

} # End of drop_table.

# --------------------------------------------------

sub generate_primary_index_name
{
	my($self, $table_name)                     = @_;
	$$self{'_primary_index_name'}{$table_name} ||=
	$$self{'_db_vendor'} eq 'POSTGRESQL'
	? "${table_name}_pkey"
	: ''; # MySQL, Oracle.

	return $$self{'_primary_index_name'}{$table_name};

} # End of generate_primary_index_name.

# --------------------------------------------------

sub generate_primary_key_sql
{
	my($self, $table_name) = @_;
	my($sequence_name)     = $self -> generate_primary_sequence_name($table_name);
	my($primary_key)       =
	$$self{'_db_vendor'} eq 'MYSQL'
	? 'integer auto_increment primary key'
	: $$self{'_db_vendor'} eq 'ORACLE'
	? 'integer primary key'
	: "integer primary key default nextval('$sequence_name')"; # Postgres.

	return $primary_key;

} # End of generate_primary_key_sql.

# --------------------------------------------------

sub generate_primary_sequence_name
{
	my($self, $table_name)                = @_;
	$$self{'_sequence_name'}{$table_name} ||=
	$$self{'_db_vendor'} eq 'MYSQL'
	? ''
	: "${table_name}_id_seq"; # Oracle, Postgres.

	return $$self{'_sequence_name'}{$table_name};

} # End of generate_primary_sequence_name.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	Carp::croak("You must supply a value for the 'dbh' parameter") if (! $$self{'_dbh'});

	$$self{'_db_vendor'}          = uc $$self{'_dbh'} -> get_info(17); # SQL_DBMS_NAME.
	$$self{'_primary_index_name'} = {};
	$$self{'_sequence_name'}      = {};

	print STDERR __PACKAGE__, ". Db vendor '$$self{'_db_vendor'}'. \n" if ($$self{'_verbose'});

	return $self;

} # End of new.

# -----------------------------------------------
# Assumption: This code is only called in the case
# of Oracle and Postgres, and after importing data
# for all tables from a XML file (say).
# The mechanism used to import from XML does not
# activate the sequences because the primary keys
# are included in the data being imported.
# So, we have to reset the current values of the
# sequences up from their default values of 1 to
# the number of records in the corresponding table.
# If not, then the next call to nextval() would
# return a value of 2, which is already in use.

sub reset_all_sequences
{
	my($self, $arg) = @_;

	if ($$self{'_db_vendor'} ne 'MYSQL')
	{
		$self -> reset_sequence($_, $arg) for keys %{$$self{'_sequence_name'} };
	}

} # End of reset_all_sequences.

# -----------------------------------------------

sub reset_sequence
{
	my($self, $table_name, $arg) = @_;

	$arg = {}                             if (! defined $arg);
	$$arg{$table_name} = {}               if (! defined $$arg{$table_name});
	$$arg{$table_name}{'no_sequence'} = 0 if (! defined $$arg{$table_name}{'no_sequence'});

	if (! $$arg{$table_name}{'no_sequence'})
	{
		my($sequence_name) = $self -> generate_primary_sequence_name($table_name);
		my($sth)           = $$self{'_dbh'} -> prepare("select count(*) from $table_name");

		$sth -> execute();

		my($max) = $sth -> fetch();
		$max     = $$max[0] || 0;
		my($sql) = "select setval('$sequence_name', $max)";

		$sth -> finish();
		$$self{'_dbh'} -> do($sql);

		print STDERR __PACKAGE__, ". SQL: $sql. \n" if ($$self{'_verbose'});
		print STDERR __PACKAGE__, ". Reset table '$table_name', sequence '$sequence_name' to $max. \n" if ($$self{'_verbose'});
	}

} # End of reset_sequence.

# --------------------------------------------------

1;

=head1 NAME

C<DBIx::Admin::CreateTable> - A module for creating and dropping tables and sequences

=head1 Synopsis

	#!/usr/bin/perl

	use strict;
	use warnings;

	use DBI;
	use DBIx::Admin::CreateTable;

	# ----------------

	my($dbh)        = DBI -> connect(...);
	my($creator)    = DBIx::Admin::CreateTable -> new(dbh => $dbh, verbose => 1);
	my($table_name) = 'test';

	$creator -> drop_table($table_name);

	my($primary_key) = $creator -> generate_primary_key_sql($table_name);

	$creator -> create_table(<<SQL);
	create table $table_name
	(
		id $primary_key,
		data varchar(255)
	)
	SQL

=head1 Description

C<DBIx::Admin::CreateTable> is a pure Perl module.

Database vendors supported: MySQL, Oracle, Postgres.

Assumptions:

=over 4

=item Every table has a primary key

=item The primary key is a unique, non-null, integer

=item The primary key is a single column

=item The primary key column is called 'id'

=item If a primary key has a corresponding auto-created index, the index is called 't_pkey'

This is true for Postgres, where declaring a column as a primary key automatically results in the creation
of an associated index for that column. The index is named after the table, not after the column.

=item If a table 't' (with primary key 'id') has an associated sequence, the sequence is called 't_id_seq'

This is true for both Oracle and Postgres, which use sequences to populate primary key columns. The sequences
are named after both the table and the column.

=back

=head1 Constructor and initialization

new(...) returns an object of type C<DBIx::Admin::CreateTable>.

This is the class's contructor.

Usage: DBIx::Admin::CreateTable -> new().

This method takes a set of parameters. Only the dbh parameter is mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item dbh

This is a database handle, returned from DBI's connect() call.

This parameter is mandatory.

There is no default.

=item verbose

This is 0 or 1, to turn off or on printing of progress statements to STDERR.

This parameter is optional.

The default is 0.

=back

=head1 Method: create_table($sql, $arg)

Returns '' (empty string) if successful and DBI's errstr() if there is an error.

$sql is the SQL to create the table.

$arg is an optional hash ref of options per table.

The keys are table names. The only sub-key at the moment is...

=over 4

=item no_sequence

	$arg = {$table_name_1 => {no_sequence => 1}, $table_name_2 => {no_sequence => 1} };

can be used to tell create_table not to create a sequence for the given table.

You would use this on a CGI::Session-type table called 'sessions', for example,
when using Oracle or Postgres. With MySQL there would be no sequence anyway.

You would also normally use this on a table called 'log'.

The reason for this syntax is so you can use the same hash ref in a call to reset_all_sequences.

=back

Usage with CGI::Session:

	my($creator)    = DBIx::Admin::CreateTable -> new(dbh => $dbh, verbose => 1);
	my($table_name) = 'sessions';
	my($type)       = $creator -> db_vendor() eq 'ORACLE' ? 'long' : 'text';

	$creator -> drop_table($table_name);
	$creator -> create_table(<<SQL, {$table_name => {no_sequence => 1} });
	create table $table_name
	(
		id char(32) primary key,
		a_session $type not null
	)
	SQL

Typical usage:

	my($creator)     = DBIx::Admin::CreateTable -> new(dbh => $dbh, verbose => 1);
	my($table_name)  = 'test';
	my($primary_key) = $creator -> generate_primary_key_sql($table_name);

	$creator -> drop_table($table_name);
	$creator -> create_table(<<SQL);
	create table $table_name
	(
		id $primary_key,
		data varchar(255)
	)
	SQL

The SQL generated by this call to create_table() is spelled-out in the (SQL) table below.

Action:

	Method:   create_table($table_name, $arg).
	Comment:  Creation of tables and sequences.
	Sequence: See generate_primary_sequence_name($table_name).
	+----------|---------------------------------------------------+
	|          |            Action for $$arg{$table_name}          |
	|  Vendor  |      {no_sequence => 0}      | {no_sequence => 1} |
	+----------|------------------------------|--------------------+
	|  MySQL   |        Create table          |    Create table    |
	+----------|------------------------------|--------------------+
	|  Oracle  | Create sequence before table |    Create table    |
	+----------|------------------------------|--------------------+
	| Postgres | Create sequence before table |    Create table    |
	+----------|------------------------------|--------------------+

SQL:

	Method:   create_table($table_name, $arg).
	Comment:  SQL generated.
	Sequence: See generate_primary_sequence_name($table_name).
	+----------|-------------------------------------------------------------------------------------+
	|          |                            SQL for $$arg{$table_name}                               |
	|  Vendor  |              {no_sequence => 0}          |            {no_sequence => 1}            |
	+----------|------------------------------------------|------------------------------------------+
	|  MySQL   |         create table $table_name         |         create table $table_name         |
	|          |        (id integer auto_increment        |        (id integer auto_increment        |
	|          |              primary key,                |              primary key,                |
	|          |           data varchar(255) )            |           data varchar(255) )            |
	+----------|------------------------------------------|------------------------------------------+
	|  Oracle  |  create sequence ${table_name}_id_seq &  |                                          |
	|          |        create table $table_name          |        create table $table_name          |
	|          |        (id integer primary key,          |        (id integer primary key,          |
	|          |           data varchar(255) )            |           data varchar(255) )            |
	+----------|------------------------------------------|------------------------------------------+
	| Postgres |  create sequence ${table_name}_id_seq &  |                                          |
	|          |         create table $table_name         |         create table $table_name         |
	|          |         (id integer primary key          |         (id integer primary key          |
	|          | default nextval("${table_name}_id_seq"), | default nextval("${table_name}_id_seq"), |
	|          |            data varchar(255) )           |            data varchar(255) )           |
	+----------|------------------------------------------|------------------------------------------+

=head1 Method: db_vendor()

Returns an upper-case string identifying the database vendor.

Return string:

	Method:   db_vendor(db_vendor).
	Comment:  Value returned.
	+----------|------------+
	|  Vendor  |   String   |
	+----------|------------+
	|  MySQL   |   MYSQL    |
	+----------|------------+
	|  Oracle  |   ORACLE   |
	+----------|------------+
	| Postgres | POSTGRESQL |
	+----------|------------+

=head1 Method: drop_table($table_name, $arg)

Returns '' (empty string).

$table_name is the name of the table to drop.

$arg is an optional hash ref of options, the same as for C<create_table()>.

Action:

	Method:  drop_table($table_name, $arg).
	Comment: Deletion of tables and sequences.
	Sequence: See generate_primary_sequence_name($table_name).
	+----------|-------------------------------------------------+
	|          |          Action for $$arg{$table_name}          |
	|  Vendor  |    {no_sequence => 0}      | {no_sequence => 1} |
	+----------|----------------------------|--------------------+
	|  MySQL   |         Drop table         |     Drop table     |
	+----------|----------------------------|--------------------+
	|  Oracle  | Drop sequence before table |     Drop table     |
	+----------|----------------------------|--------------------+
	| Postgres | Drop sequence after table  |     Drop table     |
	+----------|----------------------------|--------------------+

SQL:

	Method:   drop_table($table_name, $arg).
	Comment:  SQL generated.
	Sequence: See generate_primary_sequence_name($table_name).
	+----------|---------------------------------------------------------------+
	|          |                        SQL for $$arg{$table_name}             |
	|  Vendor  |          {no_sequence => 0}          |   {no_sequence => 1}   |
	+----------|--------------------------------------|------------------------+
	|  MySQL   |        drop table $table_name        | drop table $table_name |
	+----------|--------------------------------------|------------------------+
	|  Oracle  | drop sequence ${table_name}_id_seq & |                        |
	|          |        drop table $table_name        | drop table $table_name |
	+----------|--------------------------------------|------------------------+
	| Postgres |       drop table $table_name &       | drop table $table_name |
	|          |  drop sequence ${table_name}_id_seq  |                        |
	+----------|--------------------------------------|------------------------+

Note: drop_table() turns off RaiseError so we don't error if the sequence and table being deleted do not exist.
This is new in V 2.00.

=head1 Method: generate_primary_index_name($table_name)

Returns the name of the index corresponding to the primary key for the given table.

The module does not call this method.

SQL:

	Method:  generate_primary_index_name($table_name).
	Comment: Generation of name of the index for the primary key.
	+----------|--------------------+
	|  Vendor  |        SQL         |
	+----------|--------------------+
	|  MySQL   |                    |
	+----------|--------------------+
	|  Oracle  |                    |
	+----------|--------------------+
	| Postgres | ${table_name}_pkey |
	+----------|--------------------+

=head1 Method: generate_primary_key_sql($table_name)

Returns partial SQL for declaring the primary key for the given table.

See the Synopsis for how to use this method.

SQL:

	Method:   generate_primary_key_sql($table_name).
	Comment:  Generation of partial SQL for primary key.
	Sequence: See generate_primary_sequence_name($table_name).
	+----------|-----------------------------------------------------+
	|  Vendor  |                       SQL                           |
	+----------|-----------------------------------------------------+
	|  MySQL   |     integer auto_increment not null primary key     |
	+----------|-----------------------------------------------------+
	|  Oracle  |               integer primary key                   |
	+----------|-----------------------------------------------------+
	| Postgres | integer primary key default nextval($sequence_name) |
	+----------|-----------------------------------------------------+

=head1 Method: generate_primary_sequence_name($table_name)

Returns the name of the sequence used to populate the primary key of the given table.

SQL:

	Method:  generate_primary_sequence_name($table_name).
	Comment: Generation of name for sequence.
	+----------|----------------------+
	|  Vendor  |         SQL          |
	+----------|----------------------+
	|  MySQL   |                      |
	+----------|----------------------+
	|  Oracle  | ${table_name}_id_seq |
	+----------|----------------------+
	| Postgres | ${table_name}_id_seq |
	+----------|----------------------+

=head1 Method: reset_all_sequences($arg)

Returns nothing.

Resets the primary key sequence for all tables, except those marked by $arg as not having a sequence.

Note: This method only works if called against an object which knows the names of all tables and sequences.
This means you must have called at least one of these, for each table:

=over

=item create_table

=item drop_table

=item generate_primary_key_sql

=item generate_primary_sequence_name

=back

$arg is an optional hash ref of options, the same as for C<create_table()>.

Summary:

	Method:  reset_all_sequences($arg).
	Comment: Reset all sequences.
	+----------|-------------------------------------------------------+
	|  Vendor  |                      Action                           |
	+----------|-------------------------------------------------------+
	|  MySQL   |                    Do nothing                         |
	+----------|-------------------------------------------------------+
	|  Oracle  | Call reset_sequence($table_name, $arg) for all tables |
	+----------|-------------------------------------------------------+
	| Postgres | Call reset_sequence($table_name, $arg) for all tables |
	+----------|-------------------------------------------------------+

=head1 Method: reset_sequence($table_name, $arg)

Returns nothing.

Resets the primary key sequence for the given table, except if it's marked by $arg as not having a sequence.

$arg is an optional hash ref of options, the same as for C<create_table()>.

Summary:

	Method:   reset_sequence($table_name, $arg).
	Comment:  Reset one sequence.
	Sequence: The value of the sequence is set to the number of records in the table.
	+----------|-----------------------------------------+
	|          |      Action for $$arg{$table_name}      |
	|  Vendor  | {no_sequence => 0} | {no_sequence => 1} |
	+----------|--------------------|--------------------+
	|  MySQL   |    Do nothing      |     Do nothing     |
	+----------|--------------------|--------------------+
	|  Oracle  | Set sequence value |     Do nothing     |
	+----------|--------------------|--------------------+
	| Postgres | Set sequence value |     Do nothing     |
	+----------|--------------------|--------------------+

=head1 FAQ

Q: Do I include the name of an auto-populated column in an insert statement?

A: Depends on the server. Some databases, e.g. Postgres, do I<not> want the name of the primary key
in the insert statement if the server is to generate a value for a column.

SQL for insert:

	Comment: SQL for insertion of rows containing auto-populated values.
	Sequence: See generate_primary_sequence_name($table_name).
	+----------|-----------------------------------------------------------------------+
	|  Vendor  |                                   SQL                                 |
	+----------|-----------------------------------------------------------------------+
	|  MySQL   |               insert into $table_name (data) values (?)               |
	+----------|-----------------------------------------------------------------------+
	|  Oracle  | insert into $table_name (id, data) values ($sequence_name.nextval, ?) |
	+----------|-----------------------------------------------------------------------+
	| Postgres |               insert into $table_name (data) values (?)               |
	+----------|-----------------------------------------------------------------------+

Q: Do I have to use a sequence to populate a primary key?

A: Well, no, actually. See next question.

Q: How to I override the auto-populated value for a primary key column?

A: By including the name and the value in the insert statement.

SQL for insert:

	Comment: SQL for insertion of rows overriding auto-populated values.
	+----------|--------------------------------------------------+
	|  Vendor  |                     SQL                          |
	+----------|--------------------------------------------------+
	|  MySQL   | insert into $table_name (id, data) values (?, ?) |
	+----------|--------------------------------------------------+
	|  Oracle  | insert into $table_name (id, data) values (?, ?) |
	+----------|--------------------------------------------------+
	| Postgres | insert into $table_name (id, data) values (?, ?) |
	+----------|--------------------------------------------------+

Q: Are primary keys always not null and unique?

A: Yes. All servers document primary key as meaning both non null and unique.

Q: Which versions of the servers did you test?

A: It matters?

	Comment: Versions.
	+----------|------------+
	|  Vendor  |     V      |
	+----------|------------+
	|  MySQL   |   5.0.45   |
	+----------|------------+
	|  Oracle  | 10.2.0.1.0 |
	+----------|------------+
	| Postgres |  8.2.4-1   |
	+----------|------------+

=head1 Required Modules

=over 4

=item Carp

=back

=head1 Author

C<DBIx::Admin::CreateTable> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2006.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2006, Ron Savage. All rights reserved.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
