use ExtUtils::MakeMaker;

print "The tests in t/2.syntax.error.t will only by run if \$DBI_DSN, \$DBI_USER and \$DBI_PASS are defined. \n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Create and drop tables, primary indexes, and sequences',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Admin-CreateTable-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'DBIx-Admin-CreateTable',
	NAME      => 'DBIx::Admin::CreateTable',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Carp       => 0,
		DBI        => 0,
		Test::More=> 0,
#		Test::Pod  => 1.45, # Make it optional. See t/pod.t
	},
	VERSION_FROM => 'lib/DBIx/Admin/CreateTable.pm',
);

