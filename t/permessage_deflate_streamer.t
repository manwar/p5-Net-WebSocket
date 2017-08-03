#!/usr/bin/env perl

use Test::More;

plan tests => 2;

use Net::WebSocket::Message ();
use Net::WebSocket::PMCE::deflate ();
use Net::WebSocket::PMCE::deflate::Streamer::Server ();

my $deflate = Net::WebSocket::PMCE::deflate->new();

my $streamer = Net::WebSocket::PMCE::deflate::Streamer::Server->new('text', $deflate);

my @frames = (
    $streamer->create_chunk('Hello'),
    $streamer->create_final('Hello'),
);

#----------------------------------------------------------------------

my $msg = Net::WebSocket::Message::create_from_frames(@frames);

my $round_trip = $deflate->decompress( $msg->get_payload() );

is( $round_trip, 'HelloHello', 'round-trip single message' ) or do {
    diag( sprintf "%v.02x\n", $_ ) for map { $_->to_bytes() } @frames;
};

my $streamer2 = Net::WebSocket::PMCE::deflate::Streamer::Server->new('text', $deflate);

my @frames2 = (
    $streamer2->create_chunk('Hello'),
    $streamer2->create_final('Hello'),
);

my $msg2 = Net::WebSocket::Message::create_from_frames(@frames2);

isnt(
    substr( $msg->get_payload(), 0, length $msg2->get_payload() ),
    $msg2->get_payload(),
    'messages start differently (i.e., context preserved between messages)',
);