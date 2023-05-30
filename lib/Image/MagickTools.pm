#! /usr/bin/false

package Image::MagickTools;

use strict;

$Image::MagickTools::VERSION = 0.1;

use Locale::TextDomain qw(image-magicktools);

use File::Spec;
use Getopt::Long 2.36 qw(GetOptionsFromArray);

sub new {
	my ($class) = @_;

	my $self = '';
	bless \$self, $class;
}

sub name {
	my ($self) = @_;

	my $class = ref $self ? ref $self : $self;
	$class =~ s/.*:://;

	return lc $class;
}

sub description {
	my ($self) = @_;

	my $class = ref $self ? ref $self : $self;
	die __x("'{class}' does not implement the method 'description'.\n");
}

sub run {
	my ($self, $args, $global_options) = @_;

	$args ||= [];
	my %options = $self->parseOptions($args);

	return $self->_run($args, $global_options, %options);
}

sub parseOptions {
	my ($self, $args) = @_;

	my %options = $self->_getDefaults;
	my %specs = $self->_getOptionSpecs;
	$specs{help} = 'h|help';

	my %optspec;
	foreach my $key (keys %specs) {
		$optspec{$specs{$key}} =
				ref $options{$key} ? $options{$key} : \$options{$key};
	}

	Getopt::Long::Configure('bundling');
	{
		local $SIG{__WARN__} = sub {
			$SIG{__WARN__} = 'DEFAULT';
			$self->__usageError(shift);
		};

		GetOptionsFromArray($args, %optspec);
	}

	# Exits.
	$self->_displayHelp if $options{help};

	return %options;
}

sub _getDefaults {}
sub _getOptionSpecs {};

sub __usageError {
	my ($self, @msg) = @_;

	my $class = ref $self;
	$class =~ s/^Image::MagickTools::Command:://;
	my $cmd = join '-', map { lcfirst $_ } split /::/, $class;

	return Qgoda::CLI->commandUsageError($cmd, @msg);
}

sub _displayHelp {
	my ($self) = @_;

	my $module = Image::MagickTools::class2module(ref $self);

	my $path = $INC{$module};
	$path = './' . $path if !File::Spec->file_name_is_absolute($path);

	$^W = 1 if $ENV{'PERLDOCDEBUG'};
	pop @INC if $INC[-1] eq '.';
	require Pod::Perldoc;
	local @ARGV = ($path);
	exit(Pod::Perldoc->run());
}

1;

=pod

=head1 NAME

Image::MagickTools - Some ImageMagick tools that I often use.

	magick-tools [--quiet | -q] [--verbose | -v]
	[-h|--help] [-V | --version]
	IMAGE_FILES... COMMANDS [OPTIONS]

	magick-tools --help

=head1 COPYRIGHT

Copyright (C) 2023, Guido Flohr <guido.flohr@cantanea.com>
