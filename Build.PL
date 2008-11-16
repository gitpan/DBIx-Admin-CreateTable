use Module::Build;

print "The tests in t/2.syntax.error.t will only by run if \$DBI_DSN, \$DBI_USER and \$DBI_PASS are defined. \n";

Module::Build -> new
(
	module_name    => 'DBIx::Admin::CreateTable',
	license        => 'artistic',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
		Carp => 0,
	},
) -> create_build_script();

