#! /bin/false

package Image::MagickTools::ImageWrapper;

use strict;

sub new {
	my ($class, $image, $filename) = @_;

	bless {
		__image => $image,
		__filename => $filename,
	}, $class;
}

sub image {
	shift->{__image};
}

sub filename {
	shift->{__filename};
}

1;

=head1 NAME

Image::MagickTools::ImageWrapper - Wrapper class for image.

=head1 SYNOPSIS

    $image = Image::Magick->new;
    $wrapper = Image::MagickTools::ImageWrapper->new($image, $filename);
    $wrapper->image->mogrify;
    $wrapper->image->Write($wrapper->filename);

=head1 DESCRIPTION

The class B<Image::MagickTools::ImageWrapper> is a simple wrapper around an
image.

=head1 CONSTRUCTOR

=over 4

=item new(IMAGE, FILENAME)

The B<IMAGE> argument should be an instance of L<Image::Magick> and B<FILENAME>
the filename where the image should be written in the end.

=back

=head1 METHODS

=over 4

=item B<image>

Returns the L<Image::Magick> instance.

=item B<filename>

Returns the output filename.

=back

=head1 SEE ALSO

L<Image::MagickTools>, L<Image::Magick>, perl(1)
