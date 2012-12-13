package Mojolicious::Plugin::OnCall;

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
        debug => 1
    );

    $app->helper(
        get_notify_sources => sub {
            my ($self) = @_;

            return $couch->get_view({
                    view => 'sources/all',
                    opts => { include_docs => 'true' } });
        },
    );

    $app->helper(
        is_valid_source => sub {
            my ($self, $id) = @_;

            my $doc;
            eval { $doc = $couch->get_doc({ id => $id }) };
            return unless $doc && $doc->{type} eq 'source';
            return 1;
        },
    );

    $app->helper(
        create_notify_source => sub {
            my ($self, $params) = @_;

            $params->{type} = 'source';
            return $couch->put_doc({ doc => $params });
        });

    $app->helper(
        add_notify => sub {
            my ($self, $params) = @_;

            $params->{type}    = 'notification';
            $params->{recv_at} = time;
            return $couch->put_doc({ doc => $params });
        });

    $app->helper(
        get_notifies => sub {
            my ($self, $limit) = @_;

            my $view = {
                view => 'notify/by_time',
                opts => { include_docs => 'true' } };
            $view->{opts}->{limit} = $limit if $limit;
            return $couch->get_array_view($view);
        });
    $app->helper(
        get_name => sub {
            my ($self, $doc) = @_;

            return unless $doc;
            my $ret = $couch->get_doc({ id => $doc });
            return $ret->{name} // undef;
        },
    );

    $app->helper(
        notify_eventually => sub {
            my ($self, $message) = @_;

            my $mappings = $couch->get_array_view({
                    view => 'notify/mappings',
                    opts => {
                        include_docs => 'true',
                        key          => $message->{source} } });
            foreach my $mapping (@{$mappings}) {
                my $method = $mapping->{mapping};
                $app->log->debug("calling " . $method);
                $self->$method($mapping, $message);
            }
        },
    );

    $app->helper(
        one_to_one => sub {
            my ($self, $mapping, $message) = @_;

            my $method = $mapping->{destination};
            $app->log->debug("calling " . $method);
            $self->$method($message->{message});
        });

    $app->helper(
        format_time => sub {
            my ($self, $time) = @_;

            my $dt = DateTime->from_epoch( epoch => $time );
            return time_ago($dt);
        }
    );
}

1;
