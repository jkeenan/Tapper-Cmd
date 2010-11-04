package Artemis::Cmd::Testrun;
use Moose;
use Artemis::Model 'model';
use DateTime;


use parent 'Artemis::Cmd';

=head1 NAME

Artemis::Cmd::Testrun - Backend functions for manipluation of testruns in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module handles the testrun part.

    use Artemis::Cmd::Testrun;

    my $bar = Artemis::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS


=head2 add

Add a new testrun to database.

=cut


=head2 add

Add a new testrun. Owner/owner_user_id and requested_hosts/requested_host_ids
allow to specify the associated value as id or string which will be converted
to the associated id. If both values are given the id is used and the string
is ignored. The function expects a hash reference with the following options:
-- optional --
* requested_host_ids - array of int
or
* requested_hosts    - array of string

* notes - string
* shortname - string
* topic - string
* date - DateTime

* owner_user_id - int
or
* owner - string

@param hash ref - options for new testrun

@return success - testrun id)
@return error   - exception

@throws exception without class

=cut

sub add {
        my ($self, $received_args) = @_;
        my %args = %{$received_args}; # copy

        $args{notes}                 ||= '';
        $args{shortname}             ||=  '';

        $args{topic_name}              = $args{topic}    || 'Misc';
        my $topic = model('TestrunDB')->resultset('Topic')->find_or_create({name => $args{topic_name}});
                
        $args{earliest}              ||= DateTime->now;
        $args{owner}                 ||= $ENV{USER};
        $self->
        $args{owner_user_id}         ||= Artemis::Model::get_or_create_user( $args{owner} );

        if ($args{requested_hosts} and not $args{requested_host_ids}) {
                foreach my $host (@{$args{requested_hosts}}) {
                        my $host_result = model('TestrunDB')->resultset('Host')->search({name => $host})->first;
                        push @{$args{requested_host_ids}}, $host_result->id if $host_result;
                }
        }
                
                
        if (not $args{queue_id}) {
                $args{queue}   ||= 'AdHoc';
                my $queue_result = model('TestrunDB')->resultset('Queue')->search({name => $args{queue}}); 
                die qq{Queue "$args{queue}" does not exists\n} if not $queue_result->count;
                $args{queue_id}  = $queue_result->first->id;
        }
        return model('TestrunDB')->resultset('Testrun')->add(\%args);
}


=head2 update

Changes values of an existing testrun. The function expects a hash reference with
the following options (at least one should be given):

* hostname  - string
* notes     - string
* shortname - string
* topic     - string
* date      - DateTime
* owner_user_id - int
or
* owner     - string

@param int      - testrun id
@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=cut

sub update {
        my ($self, $id, $args) = @_;
        my %args = %{$args};    # copy

        my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);

        $args{owner_user_id}         = $args{owner_user_id}         || Artemis::Model::get_or_create_user( $args{owner} )          if $args{owner};

        return $testrun->update_content(\%args);
}

=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=cut

sub del {
        my ($self, $id) = @_;
        my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);
        if ($testrun->testrun_scheduling->requested_hosts->count) {
                foreach my $host ($testrun->testrun_scheduling->requested_hosts->all) {
                        $host->delete();
                }
        }
        if ($testrun->testrun_scheduling->requested_features->count) {
                foreach my $feat ($testrun->testrun_scheduling->requested_features->all) {
                        $feat->delete();
                }
        }

        $testrun->delete();
        return 0;
}

=head2 rerun

Insert a new testrun into the database. All values not given are taken from
the existing testrun given as first argument.

@param int      - id of original testrun
@param hash ref - different values for new testrun

@return success - testrun id
@return error   - exception

@throws exception without class

=cut

sub rerun {
        my ($self, $id, $args) = @_;
        my %args = %{$args || {}}; # copy
        my $testrun = model('TestrunDB')->resultset('Testrun')->find( $id );
        return $testrun->rerun(\%args);
}



=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<osrc-sysin at elbe.amd.com>, or through
the web interface at L<https://osrc/bugs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2009 OSRC SysInt Team, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Artemis::Cmd::Testrun
