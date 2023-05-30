#! /bin/false

package Image::MagickTools::CLI;

use strict;

use IO::Handle;
use Locale::TextDomain qw(magick-tools);
use Getopt::Long 2.36 qw(GetOptionsFromArray);

my %global_optspec = (
	'i|in=s' => 'in',
	'o|out=s' => 'out',
	'q|quiet' => 'quiet',
	'h|help' => 'help',
	'v|verbose' => 'verbose',
	'V|version' => 'version',
);
my %global_optspec_defaults;

sub new {
	my ($class, $argv) = @_;

	$argv ||= [@ARGV];

	my %commands = $class->commands;

	# Split arguments into global options like '--verbose', a command,
	# and command-specific options.
	my @args;
	while (@$argv) {
		if ($argv->[0] =~ /^-[-a-zA-Z0-9]/) {
			push @args, shift @$argv;
		} else {
			last;
		}
	}

	# Now collect the commands.
	my @cmds;
	if (@$argv) {
		my $cmd = shift @$argv;
		if (!exists $commands{$cmd}) {
			$class->usageError(__x("unknown command '{command}'.",
			                       command => $cmd));
		}
		push @cmds, [$cmd];
		while (@$argv) {
			my $arg = shift @$argv;
			if (exists $commands{$arg}) {
				push @cmds, [$arg];
			} else {
				push @{$cmds[-1]}, $arg;
			}
		}
	}

	bless {
		__global_options => \@args,
		__cmds => \@cmds,
	}, $class;
}

sub perl_class {
	my ($name) = @_;

	return $name =~ /^[_a-zA-Z][_0-9a-zA-Z]*(?:::[_a-zA-Z][_0-9a-zA-Z]*)*$/o;
};

sub class2module {
	my ($class) = @_;

	$class =~ s{(?:::|')}{/}g;

	return $class . '.pm';
}

sub commands {
	my %commands;

	foreach my $dir (@INC) {
		opendir my $dirh,
			File::Spec->catfile($dir, 'Image', 'MagickTools', 'Command')
			or next;
		my @classes =
			map { s/\.pm$//i; "Image::MagickTools::Command::$_" }
			grep { /[_a-z][_a-z0-9]+\.pm/i }
			readdir $dirh;
		foreach my $class (@classes) {
			my $module = class2module $class;
			eval {
				require $module;
				my $description = $class->description;
				chomp $description;
				$commands{$class->name} = $description;
			};
			if ($@) {
				warn "require $class: $@\n";
				next;
			}
		}
	}

	return %commands;
}

sub dispatch {
	my ($self) = @_;

	autoflush STDOUT, 1;
	autoflush STDERR, 1;

	my %options;
	foreach my $key (keys %global_optspec_defaults) {
		my $default = $global_optspec_defaults{$key};
		$default = [@$default] if 'ARRAY' eq ref $default;
		$options{$key} = $default;
	}

	my %optspec = %global_optspec;
	foreach my $key (keys %global_optspec) {
		$optspec{$key} = ref $options{$global_optspec{$key}} ?
			$options{$global_optspec{$key}} : \$options{$global_optspec{$key}};
	}

	Getopt::Long::Configure('bundling');
	{
		local $SIG{__WARN__} = sub {
			$SIG{__WARN__} = 'DEFAULT';
			$self->usageError(shift);
		};

		GetOptionsFromArray($self->{__global_options}, %optspec);
	}

	$self->displayUsage if $options{help};
	$self->displayVersion if $options{version};

	my @cmds = @{$self->{__cmds}};
	my @instances;
	foreach my $task (@cmds) {
		my ($cmd, @args) = @$task;
		$cmd =~ s/-/::/g;
		$cmd = join '::', map {
			ucfirst $_;
		} split /::/, $cmd;

		my $class = 'Image::MagickTools::Command::' . $cmd;
		my $module = class2module $class;

		eval { require $module };
		if ($@) {
			my $msg = $@;
			chomp $msg;
			die __x("{program}: {command}: {error}\n",
					program => $0,
					command => $self->{__cmd},
					error => $msg);
		}

		# That may call help and exit.
		$class->new(\@args, \%options);
	}

	if (!defined $options{in}) {
		$self->usageError(__x"the option '--in' (resp. '-i') is mandatory.");
	}
	if (!defined $options{out}) {
		$self->usageError(__x"the option '--out' (resp. '-o') is mandatory.");
	}

	my $image = Image::Magick->new;
	my $error = $image->Read($options{in});
	die "$error\n" if length $error;

	foreach my $instance (@instances) {
		$image = $instance->run([$image]);
	}

	return $self;
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

	my %commands = commands;
	foreach my $command (sort keys %commands) {
		my @description = split /\n/, $commands{$command};
		$msg .= '  ' . $command;
		my $offset = 30 - 2 - length $command;
		foreach my $line (@description) {
			$msg .= ' ' x $offset;
			$msg .= "$line\n";
			$offset = 30;
		}
	}

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
    my $msg = __x('{program} (Image::MagickTools) {version}
Copyright (C) {years} Guido Flohr <guido.flohr@cantanea.com>.
License WTFPL_2: <http://www.wtfpl.net/>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Written by Guido Flohr (http://www.guido-flohr.net/).
', program => $0, years => '2023', version => $Image::MagickTools::VERSION);

	print $msg;

	exit 0;
}

1;

=head1 NAME

Image::MagickTools::CLI - Image::MagickTools command-line dispatcher.
