#!/usr/bin/perl
#

use 5.010;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;

my $key = 'da860dcc8ab87f28a50282bbe800136d';
my $url = 'http://127.0.0.1:3000/add/';
my $content = to_json({message => "Test message from On Call"});
say "JSON: $content";
my $ua = LWP::UserAgent->new;
my $res = $ua->post($url.$key, Content_Type => 'form-data', Content => {payload => $content} );
say "Response: ". $res->content;
