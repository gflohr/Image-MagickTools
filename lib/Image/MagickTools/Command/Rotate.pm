#! /bin/false

package Image::MagickTools::Command::Rotate;

use strict;

use base 'Image::MagickTools';

use Locale::TextDomain qw(image-magicktools);

sub _getDefaults {}

sub _getOptionSpecs {
	return (
		degrees => 'd|a|angle|degrees=s',
		background => 'b|background=s',
	);
}

sub _run {
	my ($self, $args, $global_options, %options) = @_;

	my $wrappers = $options{_images};
	my %optspec = $self->_getOptionSpecs;
	my @params = keys %optspec;
	my %params = $self->_cleanOptions(\%options, @params);

	foreach my $wrapper (@$wrappers) {
		my $error = $wrapper->image->Rotate(%params);
		die "$error\n" if length $error;
	}

	return $wrappers;
}

sub description {
	return __(<<'EOF');
rotate an image
EOF
}

1;

=head1 NAME

magick-tools enhance - Enhance image or images

=head1 SYNOPSIS

	magick-tools [--quiet | -q] [--verbose | -v]
	[-h|--help] [-V | --version]
	IMAGE_FILES... rotate [OPTIONS]

Try 'magick-tools --help' for a description of global options.

=head1 DESCRIPTION

Rotate an image.

=head1 OPTIONS

=over 4

=item -d, -degrees, -a, --angle DOUBLE

Rotation angle in clockwise direction. Range: 0 - 360 degrees.

=item -b, --background

The background color as a L<color name|https://imagemagick.org/script/color.php>.

=item -h, --help

Show this help page and exit.

=back

=head1 SEE ALSO

magick-tools(1), perl(1)
