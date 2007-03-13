package TAP::Parser::Source;

use strict;
use vars qw($VERSION);

use TAP::Parser::Iterator::Process;

# Causes problem on MacOS and shouldn't be necessary anyway
#$SIG{CHLD} = sub { wait };

=head1 NAME

TAP::Parser::Source - Stream output from some source

=head1 VERSION

Version 0.52

=cut

$VERSION = '0.52';

=head1 DESCRIPTION

Takes a command and hopefully returns a stream from it.

=head1 SYNOPSIS

 use TAP::Parser::Source;
 my $source = TAP::Parser::Source->new;
 my $stream = $source->source(['/usr/bin/ruby', 'mytest.rb'])->get_stream;

=head1 METHODS

=head2 Class methods

=head3 C<new>

 my $source = TAP::Parser::Source->new;

Returns a new C<TAP::Parser::Source> object.

=cut

sub new {
    my $class = shift;
    _autoflush( \*STDOUT );
    _autoflush( \*STDERR );
    bless { switches => [] }, $class;
}

##############################################################################

=head2 Instance methods

=head3 C<source>

 my $source = $source->source;
 $source->source(['./some_prog some_test_file']);

 # or
 $source->source(['/usr/bin/ruby', 't/ruby_test.rb']);

Getter/setter for the source.  The source should generally consist of an array
reference of strings which, when executed via C<&IPC::Open3::open3>, should
return a filehandle which returns successive rows of TAP.

=cut

sub source {
    my $self = shift;
    return $self->{source} unless @_;
    unless ( 'ARRAY' eq ref $_[0] ) {
        $self->_croak("Argument to &source must be an array reference");
    }
    $self->{source} = shift;
    return $self;
}

##############################################################################

=head3 C<get_stream>

 my $stream = $source->get_stream;

Returns a stream of the output generated by executing C<source>.

=cut

sub get_stream {
    my ($self) = @_;
    my @command = $self->_get_command
      or $self->_croak("No command found!");

    return TAP::Parser::Iterator::Process->new(@command);
}

sub _get_command { @{ shift->source } }

##############################################################################

=head3 C<error>

 unless ( my $stream = $source->get_stream ) {
     die $source->error;
 }

If a stream cannot be created, this method will return the error.

=cut

sub error {
    my $self = shift;
    return $self->{error} unless @_;
    $self->{error} = shift;
    return $self;
}

##############################################################################

=head3 C<exit>

  my $exit = $source->exit;

Returns the exit status of the process I<if and only if> an error occurs in
opening the file.

=cut

sub exit {
    my $self = shift;
    return $self->{exit} unless @_;
    $self->{exit} = shift;
    return $self;
}

##############################################################################

=head3 C<pid>

  my $pid = $source->pid;

Returns the pid of the command being used to execute the tests.

=cut

sub pid {
    my $self = shift;
    return $self->{pid} unless @_;
    $self->{pid} = shift;
    return $self;
}

# Turns on autoflush for the handle passed
sub _autoflush {
    my $flushed = shift;
    my $old_fh  = select $flushed;
    $| = 1;
    select $old_fh;
}

sub _croak {
    my $self = shift;
    require Carp;
    Carp::croak(@_);
}

1;
