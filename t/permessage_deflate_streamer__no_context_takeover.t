#!/usr/bin/env perl

use Test::More;

plan tests => 3;

use Net::WebSocket::Message ();
use Net::WebSocket::PMCE::deflate ();
use Net::WebSocket::PMCE::deflate::Streamer::Server ();

my $deflate = Net::WebSocket::PMCE::deflate->new(
    'local_no_context_takeover' => 1,
);

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

TODO: {
    local $TODO = 'apparent bug in Compress::Raw::Zlib: appends extra empty/uncompressed block';

    is(
        $msg2->get_payload(),
        $msg->get_payload(),
        'with “local_no_context_takeover” two identical successive messages are the same',
    ) or do {
        diag( sprintf "%v.02x\n", $_ ) for map { $_->get_payload() } @frames, @frames2;
    };
}

is(
    sprintf( '%v.02x', substr( $frames[0]->get_payload(), 0, length $frames2[0]->get_payload() ) ),
    sprintf( '%v.02x', $frames2[0]->get_payload() ),
    'first message starts the same as the second (i.e., context is reset)',
) or do {
    diag( sprintf "%v.02x\n", $_ ) for map { $_->get_payload() } @frames, @frames2;
};