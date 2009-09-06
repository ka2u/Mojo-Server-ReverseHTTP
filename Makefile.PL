use inc::Module::Install;
name 'Mojo-Server-Reversehttp';
all_from 'lib/Mojo/Server/Reversehttp.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
