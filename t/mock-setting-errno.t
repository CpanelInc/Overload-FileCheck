#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck qw{unmock_all_file_checks};
use Errno ();

{
    note "no mocks at this point";

    ok -e q[/tmp],           "/tmp/exits";
    ok !-e q[/do/not/exist], "/do/not/exist";

    my ( $check, $errno_int, $errno_str );

    $check     = -e q[/do/not/exist];
    $errno_str = "$!";
    $errno_int = int($!);

    ok !$check, "file does not exist";
    like $errno_str, qr{No such file or directory}, q[ERRNO set to "No such file or directory"];
    is $errno_int, Errno::ENOENT(), "ERRNO int value set";

    $check     = -e $^X;
    $errno_int = int($!);

    ok $check, q[$^X exists];
    is $errno_int, Errno::ENOENT(), "ERRNO was not reset";
}

{
    local $! = 0;

    my $existing_file = q[/there];
    my $missing_file  = q[/not-there];

    Overload::FileCheck::mock_file_check(
        '-e' => sub {
            my $f = shift;
            return 0 if $f eq $missing_file;
            return 1 if $f eq $existing_file;

            # we do not know and let perl check it for us
            return -1;

        }
    );

    my ( $check, $errno_int, $errno_str );

    is int($!), 0, 'errno=0 at startup';

    note "check existing file";
    $check     = -e $existing_file;
    $errno_int = int($!);

    ok $check, 'existing_file is there';
    is $errno_int, 0, '$! is not set';

    note "check missing file";
    $check     = -e $missing_file;
    $errno_int = int($!);

    ok !$check, 'missing_file not there';
    is $errno_int, Errno::ENOENT(), '$! is set to the default value';

    note "check existing file again";
    $check     = -e $existing_file;
    $errno_int = int($!);

    ok $check, 'existing_file is there';
    is $errno_int, Errno::ENOENT(), '$! was not reset';

    ok -e $^X, q[$^X exists];
    is int($!), Errno::ENOENT(), '$! was not reset when fallback to original OP';

    unmock_all_file_checks();
}

{
    note "User provide its own ERRNO error";
    local $! = 0;

    note "we are mocking -e => 1";
    Overload::FileCheck::mock_file_check(
        '-e' => sub {
            my $f = shift;
            note "mocked -e called....";

            $! = Errno::EINTR();    # set errno

            return 0;
        }
    );

    my $check     = -e q[/tmp];
    my $errno_str = "$!";
    my $errno_int = int($!);

    ok !$check, "/tmp does not exist";
    like $errno_str, qr{Interrupted system call}, q[ERRNO set to "Interrupted system call"];
    is $errno_int, Errno::EINTR(), "ERRNO int value set to Errno::EINTR()";

    unmock_all_file_checks();
}

done_testing;