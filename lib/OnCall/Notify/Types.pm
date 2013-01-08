package OnCall::Notify::Types;

use 5.010;
use Any::Moose;
use Data::Dumper;

has 'debug' => (is => 'rw', isa => 'Bool', default => 0);


=head2 ignore_first

Ignore first call and only log the message to STDERR for the moment

=cut

sub ignore_first {
    my($self, $incident) = @_;

    say STDERR "ignore first notify! ID: " . $incident->id;
    $incident->stage($incident->stage +1);
    return $incident;
}


=head2 after_5_min

Notify if the last notify is more than 5 minutes ago

=cut

sub after_5_min {
    my ($self, $incident) = @_;
    
    if (($incident->last_seen + 20) < time){
        say STDERR "Incident still broken! ID: " . $incident->id;
        $incident->stage($incident->stage +1);
        $incident->update_sequence;
        return $incident;
    }
    return $incident;
}


=head2 notify_recovery

Notify the recovery of the incident

=cut

sub notify_recovery {
    my ($self, $incident) = @_;

    say STDERR "Incident recovered! ID: " . $incident->id;
    return $incident;
}

__PACKAGE__->meta->make_immutable();
