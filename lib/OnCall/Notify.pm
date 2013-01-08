package OnCall::Notify;

use 5.010;
use Any::Moose;
use OnCall::Incident;
use OnCall::Notify::Types;

has 'debug' => (is => 'rw', isa => 'Bool', default => 0);
has 'incidents' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'condvar' => (is => 'rw', isa => 'AnyEvent::CondVar');
has 'plan' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [ 'ignore_first', 'after_5_min' ] });
has 'on_recovery' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { ['notify_recovery'] });

=head1 NAME

OnCall::Notify - Notification Class for OnCall

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

ClassLongDesc

=head1 FUNCTIONS

=cut

=head2 notify

Handle a notification request. This handles the workflow defined for
this type of incident and falls back to a default plan. The default plan
is:
    ignore_first
    after_5_min # repeat till recovery

    # on recover:
    notify_recovery

=cut

sub notify {
    my ($self, $msg, $id) = @_;

    my $incident;
    $id = $msg->{id} unless $id;
    unless ($incident = $self->incidents->{ $id }) {
        $incident = OnCall::Incident->new(id => $msg->{id});
        $self->incidents->{ $msg->{id} } = $incident;
        $self->schedule($incident); # schedule retests
    }
    if ($incident->is_open) {
        my $notify = OnCall::Notify::Types->new();
        foreach my $wf (@{$self->plan}) {
            $notify->$wf($incident);
        }
    }
    else {
        $self->recover($incident);
    }
    return;
}

=head2 recover

Recover from an incident

=cut

sub recover {
    my ($self, $incident) = @_;
    my $notify = OnCall::Notify::Types->new();
    foreach my $wf (@{$self->on_recovery}) {
        $notify->$wf($incident);
    }

    # remove the incident from internal registry, this also lets the
    # condvar go out of scope and therefor removes all events attached
    # to it.
    delete $self->incidents->{$incident->id};
    return;
}

=head2 schedule

Schedule the next event for this incident after a defined timeout

=cut

sub schedule {
    my ($self, $incident) = @_;

    my $w = AnyEvent->timer(
        after    => $incident->timeout,
        interval => $incident->timeout,
        cb       => sub {
            $self->notify(undef, $incident->id);
            $self->condvar->send;
        });
    $incident->condvar($w);
    $self->incidents->{$incident->id} = $incident; # store condvar
    return;
}

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs through the web interface at
L<https://github.com/norbu09/githubName/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OnCall::Notify

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/githubName>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/githubName>

=item * Search CPAN

L<http://search.cpan.org/dist/githubName/>

=back


=head1 COPYRIGHT & LICENSE

Copyright © 2012 Lenz Gschendtner (springtimesoft LTD).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable();
