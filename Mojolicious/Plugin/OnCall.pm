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
                opts => { include_docs => 'true', descending => 'true' } };
            $view->{opts}->{limit} = $limit if $limit;
            return $couch->get_array_view($view);
        });
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
                $self->$method($mapping, $message)
                    unless $self->is_downtimed($message);
            }
        },
    );

    $app->helper(
        one_to_one => sub {
            my ($self, $mapping, $message) = @_;

            my $method = $mapping->{destination};
            $app->log->debug("calling " . $method);
            $self->$method($message);
        });
    
    $app->helper(
        is_downtimed => sub {
            my ($self, $message) = @_;

            my $downtimes = $couch->get_array_view({
                    view => 'sources/downtimes',
                    opts => { include_docs => 'true',}
                });
            foreach my $down (@{$downtimes}){
                next unless exists $message->{$down->{key}};
                my $re = $down->{match};
                return 1 if($message->{$down->{key}} =~ m{$re});
            }
            return;
        },
    );

    $app->helper(
        get_user_list => sub {
            my ($self) = @_;

            return $couch->get_array_view({ view => 'site/user', opts => {include_docs => 'true'}});
        },
    );

    $app->helper(
        find_on_duty_guy => sub {
            my ($self, $message) = @_;

            return $self->check_timezones($message) ||
            $self->check_on_duty_plan($message) ||
            $self->check_escalation_level($message);
        }
    );

    $app->helper(
        check_timezones => sub {
            my ($self, $message) = @_;
            return;
        },
    );
    $app->helper(
        check_on_duty_plan => sub {
            my ($self, $message) = @_;
            return;
        },
    );
    $app->helper(
        check_escalation_level => sub {
            my ($self, $message) = @_;
            # FIXME - needs a real lookup
            # fake code to only notify me - only for testing in the moment
            return $couch->get_doc({id => 'da860dcc8ab87f28a50282bbe8000ad8'});
        }
    );

}

1;
