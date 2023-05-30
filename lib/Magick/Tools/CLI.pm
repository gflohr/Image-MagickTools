#! /bin/false

package Magick::Tools::CLI;

use strict;

use IO::Handle;
use Locale::TextDomain qw(magick-tools);
use Getopt::Long 2.36 qw(GetOptionsFromArray);

my $perl_class = sub {
	my ($name) = @_;

	return $name =~ /^[_a-zA-Z][_0-9a-zA-Z]*(?:::[_a-zA-Z][_0-9a-zA-Z]*)*$/o;
};

my $class2module = sub {
	my ($class) = @_;

	$class =~ s{(?:::|')}{/}g;

	return $class . '.pm';
};

sub new {
	my ($class, $argv) = @_;

	$argv ||= [@ARGV];

	my (@args, $cmd);

	# Split arguments into global options like '--verbose', a command,
	# and command-specific options.  We simplify this by stipulating that
	# global options cannot take any arguments.  So the first command-line
	# argument that does not start with a hyphen is the command, the rest
	# are options and arguments for that command.
	while (@$argv) {
		my $arg = shift @$argv;
		if ($arg =~ /^-[-a-zA-Z0-9]/) {
			push @args, $arg;
		} else {
			$cmd = $arg;
			last;
		}
	}

	bless {
		__global_options => \@args,
		__cmd => $cmd,
		__cmd_args => [@$argv],
	}, $class;
}

sub dispatch {
	my ($self) = @_;

	autoflush STDOUT, 1;
	autoflush STDERR, 1;

	my %options;
	Getopt::Long::Configure('bundling');
	{
		local $SIG{__WARN__} = sub {
			$SIG{__WARN__} = 'DEFAULT';
			$self->usageError(shift);
		};

		GetOptionsFromArray($self->{__global_options},
			'log-stderr' => \$options{log_stderr},
			'q|quiet' => \$options{quiet},
			'h|help' => \$options{help},
			'v|verbose' => \$options{verbose},
			'V|version' => \$options{version},
		);
	}

	$self->displayUsage if $options{help};
	$self->displayVersion if $options{version};

	my $cmd = $self->{__cmd}
		or $self->usageError(__"no command given!");
	$cmd =~ s/-/::/g;
	$self->usageError(__x("invalid command name '{command}'",
							command => $self->{__cmd}))
		if !perl_class $cmd;

	$cmd = join '::', map {
		ucfirst $_;
	} split /::/, $cmd;

	my $class = 'Magick::Tools::Command::' . $cmd;
	my $module = class2module $class;

	eval { require $module };
	if ($@) {
		if ($@ =~ m{^Can't locate $module in \@INC}) {
			$self->usageError(__x("unknown command '{command}'",
									command => $self->{__cmd}));
		} else {
			my $msg = $@;
			chomp $msg;
			die __x("{program}: {command}: {error}\n",
					program => $0,
					command => $self->{__cmd},
					error => $msg);
		}
	}

	return $class->new->run($self->{__cmd_args}, \%options);
}

sub displayUsage {
	my $msg = __x(<<EOF, program => $0);
Usage: {program} COMMAND [OPTIONS]
EOF

	$msg .= "\n";

	$msg .= __<<EOF;
Mandatory arguments to long options, are mandatory to short options, too.
EOF

	$msg .= "\n";

	$msg .= __<<EOF;
The following commands are currently supported:
EOF

	$msg .= "\n";

	$msg .= __<<EOF;
  enhance                     enhance image
EOF

	$msg .= "\n";

	$msg .= __<<EOF;
Operation mode:
  -q, --quiet                 quiet mode
  -v, --verbose               verbosely log what is going on
      --log-stderr            log to standard error instead of standard out
EOF

	$msg .= "\n";

	$msg .= __<<EOF;
Informative output:
  -h, --help                  display this help and exit
  -V, --version               output version information and exit
EOF

	$msg .= "\n";

	$msg .= __x(<<EOF, program => $0);
Try '{program} --help' for more information.
EOF

	print $msg;

	exit 0;
}

sub commandUsageError {
	my ($class, $cmd, $message, $usage) = @_;

	if ($message) {
		$message =~ s/\s+$//;
		if (defined $cmd) {
			$message = "$0 $cmd: $message\n";
		} else {
			$message = "$0: $message\n";
		}
	} else {
		$message = '';
	}

	if (defined $usage) {
		$message .= __x(<<EOF, program => $0, command => $cmd, usage => $usage);
Usage: {program} [GLOBAL_OPTIONS] {usage}
Try '{program} {command} --help' for more information!
EOF
	} elsif (defined $cmd) {
		$message .= __x(<<EOF, program => $0, command => $cmd);
Usage: {program} [GLOBAL_OPTIONS] {command} [OPTIONS]
Try '{program} {command} --help' for more information!
EOF
	} else {
		$message .= __x(<<EOF, program => $0);
Usage: {program} [GLOBAL_OPTIONS] COMMAND [OPTIONS]
Try '{program} --help' for more information!
EOF
	}

	die $message;
}

sub usageError {
	my ($class, $message) = @_;

	return $class->commandUsageError(undef, $message);
}

sub displayVersion {
    my $msg = __x('{program} (Magick::Tools) {version}
Copyright (C) {years} Guido Flohr <guido.flohr@cantanea.com>.
License WTFPL_2: <http://www.wtfpl.net/>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Written by Guido Flohr (http://www.guido-flohr.net/).
', program => $0, years => '2023', version => $Magick::Tools::VERSION);

	print $msg;

	exit 0;
}

1;

=head1 NAME

Magick::Tools::CLI - Magick::Tools command-line dispatcher.
