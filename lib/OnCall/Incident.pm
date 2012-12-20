package OnCall::Incident;

use 5.010;
use Any::Moose;

has 'debug' => (is => 'rw', isa => 'Bool', default => 0);
has 'id' => (is => 'rw', isa => 'Str');
has 'condvar'          => (is => 'rw', isa => 'AnyEvent::CondVar');
has 'timeout'          => (is => 'rw', isa => 'int', defaut => 600);
has 'escalation_level' => (is => 'rw', isa => 'Int', default => 0);
has 'sequence'         => (is => 'rw', isa => 'Int', default => 0);
has 'last_notify'      => (is => 'rw', isa => 'Int', default => 0);
has 'last_seen'        => (is => 'rw', isa => 'Int', default => sub { time });

=head1 NAME

OnCall::Incident - Incident class for a OnCall Incident

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

ClassLongDesc

=head1 FUNCTIONS

=cut

=head2 ignore_first

Ignore first message - we only want to report errors that are actual
errors, not just a glitch in the matrix.
Returns 0 if it should not be ignored, returns 1 if the should;

=cut

sub ignore_first {
    my $self = shift;

    if ($self->sequence == 0) {
        $self->update_sequence;
        return;
    }
    return 1;
}

=head2 update_sequence

Convenience method to update the sequence number

=cut

sub update_sequence {
    my $self = shift;

    $self->last_seen(time);
    return $self->sequence($self->sequence + 1);
}

=head2 after_5_min

Check if the last notify was more than 5 min ago
Returns 0 if no notify should be sent, 1 if we should trigger one.

=cut

sub after_5_min {
    my $self = shift;

    if (($self->last_notify + 300) < time) {
        return 1;
    }
    $self->update_sequence;
    return;
}

=head2 after_1_hour

Check if the last notify was more than 60 min ago
Returns 0 if no notify should be sent, 1 if we should trigger one.

=cut

sub after_1_hour {
    my $self = shift;

    if (($self->last_notify + 3600) < time) {
        return 1;
    }
    $self->update_sequence;
    return;
}

=head2 escalate

Escalate a issue to the next level

=cut

sub escalate {
    my $self = shift;

    return $self->escalation_level($self->escalation_level + 1);
}

=head2 persist

Persist an incident

=cut

sub persist {
    my ($self, $incident) = @_;

    # store it somewhere
    return;
}

=head2 retrieve

Retrieve a message from the persistent store

=cut

sub retrieve {
    my $self = shift;

    # get_incident($self->id);
    my $incident = {};
    return $incident;
}

=head2 is_open

Check if the incident is still open. This is determined by the default
timeout or a parameter passed as argument. Parameter is in seconds.
returns 1 if the incident is not timed out yet, 0 otherwise.

=cut

sub is_open {
    my ($self, $timeout) = @_;

    $timeout = $self->timeout unless $timeout;
    if (($self->last_seen + $timeout) > time) {
        return 1;
    }
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

    perldoc OnCall::Incident

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
