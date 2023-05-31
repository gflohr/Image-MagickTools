#! /bin/false

package Image::MagickTools::Command::Enhance;

use strict;

use base 'Image::MagickTools';

use Locale::TextDomain qw(image-magicktools);

sub _getDefaults {}

sub _getOptionSpecs {
	return (
		radius => 'r|radius=s',
		sigma => 's|sigma=s',
		amount => 'a|amount=s',
		threshold => 't|threshold=s',
	);
}

sub _run {
	my ($self, $args, $global_options, %options) = @_;

	my $images = $options{_images};

	foreach my $image (@$images) {

	}

	return $images;
}

sub description {
	return __(<<'EOF');
enhance image or images
EOF
}

1;

=head1 NAME

magick-tools enhance - Enhance image or images

=head1 SYNOPSIS

	magick-tools [--quiet | -q] [--verbose | -v]
	[-h|--help] [-V | --version]
	IMAGE_FILES... enhance [OPTIONS]

Try 'magick-tools --help' for a description of global options.

=head1 DESCRIPTION

Enhance images by applying one or more filters.

=head1 OPTIONS

=over 4

=item -r, -radius

The radius of the Gaussian, in pixels,  not counting the center pixel
(default 0).

=item -s, --sigma

The standard deviation of the Gaussian, in pixels (default 1.0).

=item -a, --amount

The percentage of the difference between the original and the blur
image that is added back into the original (default 1.0).

=item -t, --threshold

The threshold, as a fraction of QuantumRange, needed to apply the
difference amount (default 0.05).

=item -h, --help

Show this help page and exit.

=back

=head1 SEE ALSO

magick-tools(1), perl(1)
