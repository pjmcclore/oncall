package Mojolicious::Plugin::Zmq;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_PUB);

sub register {
    my ($self, $app, $params) = @_;


    my $context = zmq_init();
    my $publisher = zmq_socket($context, ZMQ_PUB);
    zmq_bind($publisher, 'tcp://*:5556');

    $app->helper(
        zmq_send => sub {
            my ($self, $message) = @_;

            my $json  = Mojo::JSON->new;
            return zmq_send( $publisher, 'json '. $json->encode($message) );
        },
    );
}

1;
