package OnCall;

use JSON;
use Any::Moose;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;

has 'token' => (
    is  => 'rw',
    isa => 'Str',
);

has 'url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://localhost:3000/add/',
);

has 'host' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { my $host = qx{hostname}; chomp($host); return $host });

has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 tell

This tells the monitoring server about a problem. high level function to
push stuff to the server. the message format is:
    
    {
        message => 'the error message', # mandatory
        prio    => [1-3],               # the priority, defaults to 1
        host    => 'FQDN',              # hostname, defaults to local
        ..      => ..                   # anything else, gets stored on
                                        # the server in the ticket
    }

The function returns 1 on success and 0 on error.

=cut

sub tell {
    my ($self, $message) = @_;

    $message->{host} = $self->host unless exists $message->{host};
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->post(
        $self->url . $self->token,
        Content_Type => 'form-data',
        Content      => { payload => to_json($message) });
    print Dumper($message, $self->url, $self->token)
        if $self->debug;
    if($res->is_success){
        return $res->content;
    } else {
        print $res->status_line ."\n" if $self->debug;
        return;
    }
}

__PACKAGE__->meta->make_immutable();
