package Mojolicious::Plugin::PlanetExpressShip;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON;
use Store::CouchDB;
use DateTime::Duration::Fuzzy qw(time_ago);
use DateTime;

sub register {
    my ($self, $app, $params) = @_;

    my $couch = Store::CouchDB->new(
        port  => $params->{port},
        db    => $params->{db},
    );

    $app->helper(
        get_name => sub {
            my ($self, $doc) = @_;

            return unless $doc;
            my $ret = $couch->get_doc({ id => $doc });
            return $ret->{name} // undef;
        },
    );

    $app->helper(
        format_time => sub {
            my ($self, $time) = @_;

            my $dt = DateTime->from_epoch( epoch => $time );
            return time_ago($dt);
        }
    );
}

1;
