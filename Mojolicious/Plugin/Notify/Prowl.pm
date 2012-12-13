package Mojolicious::Plugin::Notify::Prowl;

use 5.010;
use Mojo::Base 'Mojolicious::Plugin';
use LWP::UserAgent;
use URI::Escape;

sub register {
    my ($self, $app, $params) = @_;

    $app->helper(
        notify_prowl => sub {
            my ($self, $msg) = @_;

            my $prio;
            given ($msg->{prio}) {
                when (2) { $prio = 1; }
                when (3) { $prio = 2; }
                default  { $prio = 0; }
            }
            my $on_duty = $self->find_on_duty_guy($msg);
            $app->log->debug("notify via Prowl");
            my $ua = LWP::UserAgent->new();
            my $url = 'https://prowl.weks.net/publicapi/';

            my @req;
            push( @req, 'apikey=' . $on_duty->{prowl} );
            push( @req, 'description=' . uri_escape( $msg->{message} ) );
            push( @req, 'event=alert' );
            push( @req, 'priority=' . $prio );
            push( @req, 'application=On%20Call:[' . $msg->{host} .']' );
            $url .= 'add?' . join( '&', @req );
            $app->log->debug("Prowl URL: $url");

            my $res = $ua->get($url);
            return ($res->is_success ? 0 : 1);
        },
    );
}

1;
