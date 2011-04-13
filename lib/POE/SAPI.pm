package POE::SAPI;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use POE::SAPI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

POE::SAPI - The simplified POE API

=head1 SYNOPSIS

#!/usr/bin/perl

use warnings;
use strict;

use lib '../lib';

use Data::Dumper;

use POE qw(SAPI);
use POE::SAPI::HandySubs qw(pad);

POE::Session->create(
	inline_states => {
		_start	=> \&init,
		comm	=> \&comm,
	},
);

POE::Kernel->run();
exit;

sub init {
	my ($kernel,$session,$heap) = @_[KERNEL,SESSION,HEAP];
	$heap->{SAPI} = POE::SAPI->new({ });		# Note no options yet
}

sub comm {
	my ($kernel,$session,$heap,$req) = @_[KERNEL,SESSION,HEAP,ARG0];

	$req->{src} = "UNKNOWN" if (!$req->{src});

	if (!$req->{type}) { $kernel->yield('comm',{ type=>"debug", level=>"critical", msg=>"Just passed a request with no type!", original=>$req }); }
	else {
		if (($req->{level}) && ($req->{level} eq 'verbose')) { return; }
		print "[" . pad($req->{src},12," ") . "], $req->{type}: $req->{msg}\n";
	}

	return if (!$req->{code});

	if ($req->{code} eq 'N_COREREADY') {
		$kernel->yield('comm',{ type=>"debug", level=>"debug", msg=>"Core Ready - Initilizing config" } );
		$kernel->post('SAPI','config',{ type=>"init" });
	}
}


=head1 DESCRIPTION

Stub documentation for POE::SAPI, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO


http://poe.perl.org

=head1 AUTHOR

Paul G Webster, E<lt>paul@daemonrage.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Paul G Webster

All rights reserved.

Redistribution and use in source and binary forms are permitted
provided that the above copyright notice and this paragraph are
duplicated in all such forms and that any documentation,
advertising materials, and other materials related to such
distribution and use acknowledge that the software was developed
by the 'blank files'.  The name of the
University may not be used to endorse or promote products derived
from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
