package Mojolicious::Plugin::Notify::HipChat;

use 5.010;
use Mojo::Base 'Mojolicious::Plugin';
use LWP::UserAgent;

sub register {
    my ($self, $app, $params) = @_;

    $app->helper(
        notify_hipchat => sub {
            my ($self, $msg, $severity) = @_;

            my $color;
            given ($severity) {
                when (2) { $color = 'yellow'; }
                when (3) { $color = 'red'; }
                default  { $color = 'green'; }
            }
            $app->log->debug("notify via HipChat");
            my @tos = split(/\s*,\s*/, $params->{rooms});
            my $ua = LWP::UserAgent->new();
            my $url =
                'https://api.hipchat.com/v1/rooms/message?format=json&auth_token=' . $params->{token};
            foreach my $to (@tos) {
                $ua->post(
                    $url, {
                        room_id        => $to,
                        from           => 'On Call',
                        message        => $msg,
                        message_format => 'text',
                        notify         => 1,
                        color          => $color,
                    });
            }
        },
    );
}

1;
