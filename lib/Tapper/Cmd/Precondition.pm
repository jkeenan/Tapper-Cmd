package Tapper::Cmd::Precondition;
use Moose;

use YAML::Syck;
use Kwalify;

use parent 'Tapper::Cmd';

=head1 NAME

Tapper::Cmd::Precondition - Backend functions for manipluation of preconditions in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module handles the precondition part.

    use Tapper::Cmd::Testrun;

    my $bar = Tapper::Cmd::Precondition->new();
    $bar->add($precondition);
    ...

=head1 FUNCTIONS

=cut

=head2 die_on_invalid_precondition

Check whether a precondition is valid either based on a given kwalify
schema or the default schema. Errors are returned by die-ing.

@param array ref - preconditions
@param schema (optional)

@return success 0

@throws Perl die

=cut

sub die_on_invalid_precondition
{
        my ($self, $preconditions, $schema) = @_;
        if (not ($schema and ref($schema) eq 'HASH') ) {
                $schema =
                {
                 type               => 'map',
                 mapping            =>
                 {
                  precondition_type =>
                  { type            => 'str',
                    required        => 1,
                  },
                  '='               =>
                  {
                   type             => 'any',
                   required         => 1,
                  }
                 }
                };
        }
        $preconditions = [ $preconditions] unless ref($preconditions) eq 'ARRAY';
 precondition:
        foreach my $precondition (@$preconditions) {
                # undefined preconditions are caused by tapper headers or a "---\n" line at the end
                next precondition unless defined($precondition);
                Kwalify::validate($schema, $precondition);
        }
        return 0;
}

=head2 add

Add a new precondition. Expects a precondition in YAML format. Multiple
preconditions may be given as one string. In this case every valid
precondition (i.e. those with a precondition_type) will be added. This is
useful for macro preconditions.


@param string    - preconditions in YAML format OR
@param array ref - preconditions as list of hashes
@param hash ref  - kwalify schema (optional)

@return success - list of precondition ids
@return error   - undef

@throws Perl die

=cut

sub add {
        my ($self, $input, $schema) = @_;
        if (ref $input eq 'ARRAY') {
                $self->die_on_invalid_precondition($input, $schema);
                return $self->schema->resultset('Precondition')->add($input);
        } else {
                $input .= "\n" unless $input =~ /\n$/;
                my @yaml = Load($input);
                $self->die_on_invalid_precondition(\@yaml, $schema);
                return $self->schema->resultset('Precondition')->add(\@yaml);
        }
}

=head2 update

Update a given precondition.

@param int    - precondition id
@param string - precondition as it should be

@return success - precondition id
@return error   - error string

@throws die


=cut

sub update {
        my ($self, $id, $condition) = @_;
        my $precondition = $self->schema->resultset('Precondition')->find($id);
        die "Precondition with id $id not found\n" if not $precondition;

        return $precondition->update_content($condition);
}


=head2 del

Delete a precondition with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - precondition id

@return success - 0
@return error   - error string

=cut

sub del {
        my ($self, $id) = @_;
        my $precondition = $self->schema->resultset('Precondition')->find($id);
        return qq(No precondition with id "$id" found) if not $precondition;;
        $precondition->delete();
        return 0;
}

1; # End of Tapper::Cmd::Testrun
