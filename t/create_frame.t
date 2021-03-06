#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use Module::Runtime ();

use Net::WebSocket::Frame ();

my $NWF = 'Net::WebSocket::Frame';

my @tests = (
    [
        'bare ping',
        ['ping' ],
        "\x89\x00",
    ],
    [
        'ping with payload',
        [ 'ping', payload => 'Ping!' ],
        "\x89\x05Ping!",
    ],
    [
        'bare pong',
        [ 'pong' ],
        "\x8a\x00",
    ],
    [
        'pong with payload',
        [ 'pong', payload => 'Pong!' ],
        "\x8a\x05Pong!",
    ],
);

plan tests => 1 + @tests;

for my $t (@tests) {
    my ($type, @args) = @{ $t->[1] };
    my $class = "Net::WebSocket::Frame::$type";
    Module::Runtime::require_module($class);

    my $frame = $class->new( @args );

    is(
        $frame->to_bytes(),
        $t->[2],
        $t->[0],
    ) or diag explain [ $frame, $t->[2] ];
}
