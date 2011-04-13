package POE::SAPI;

use 5.010001;
use strict;
use warnings;

use POE qw(SAPI::DBIO SAPI::LocalAuth SAPI::HTTP SAPI::ConfigLoader SAPI::NetTools SAPI::Scheduler SAPI::Extend);

use Data::Dumper;

our $VERSION = '0.02';

sub keepAlive {
        my ($kernel,$session)   = @_[KERNEL,SESSION];
        my $self = shift;
        $kernel->delay('loop' => 1);
        $self->{cycles}++;
}
sub killLauncher { warn "Session halting"; }
sub initLauncher {
	my ($kernel,$session,$self)   = @_[KERNEL,SESSION,OBJECT];

	$kernel->alias_set('SAPI');
	$kernel->alias_set('sapi');
	$kernel->alias_set('Sapi');

	$self->{Components}->{DBIO}->{OBJ} = POE::SAPI::DBIO->new({
		parent => $session->ID,
	});
	$self->{Components}->{DBIO}->{OBJ} = POE::SAPI::LocalAuth->new({
		parent => $session->ID,
	});
	$self->{Components}->{HTTP}->{OBJ} = POE::SAPI::HTTP->new({
		parent => $session->ID,
	});
	$self->{Components}->{ConfigLoader}->{OBJ} = POE::SAPI::ConfigLoader->new({
		parent => $session->ID,
	});
	$self->{Components}->{NetTools}->{OBJ} = POE::SAPI::NetTools->new({
		parent => $session->ID,
	});
	$self->{Components}->{Scheduler}->{OBJ} = POE::SAPI::Scheduler->new({
		parent => $session->ID,
	});

	$kernel->yield('passback',{ type=>"debug", msg=>"Core Starting", src=>"CORE" });

	$kernel->yield('loop'); 
}
sub register {
	my ($kernel,$self,$session,$input)   = @_[KERNEL,OBJECT,SESSION,ARG0];

	my ($name,$type) = ($input->{name},$input->{type});

	if (!$input->{error}) {
		$self->{components}->{local}->{$name}->{state}->{msg} = "ready";
		$self->{components}->{local}->{$name}->{state}->{code} = 1;

		$kernel->yield('passback',{ type=>"debug", msg=>"Registration: $input->{name} type: $input->{type}", src=>"CORE" });

		my $checkSet = 0;
		my @waitlist;

		foreach my $key (keys %{ $self->{components}->{local} }) {
			if ($self->{components}->{local}->{$key}->{state}->{code} == 0) { push @waitlist,$key;  $checkSet++; }
		}

		if ($waitlist[0]) { $kernel->yield('passback',{ type=>"debug", msg=>"Waiting for: @waitlist", src=>"CORE" }); }

		if ($checkSet == 0) { 
			$kernel->yield('passback',{ type=>"debug", msg=>"All local modules ready!", code=>'N_COREREADY' }); 

			foreach my $key (keys %{ $self->{components}->{local} }) {
				$kernel->post($key,'ready',{ type=>'alert', msg=>"System ready", code=>200, src=>"CORE" }); 
			}
		}
	} else {
		$kernel->yield('passback',{ type=>"debug", msg=>"Registration: FAILURE for: $input->{name} ($input->{type}): $input->{error}->{msg}", src=>"CORE" });
	}
}
sub passback {
	my ($kernel,$self,$session,$req)   = @_[KERNEL,OBJECT,SESSION,ARG0];
	$kernel->post($self->{parent},"comm",$req);
}
sub config {
	my ($kernel,$self,$session,$req)   = @_[KERNEL,OBJECT,SESSION,ARG0];

	if (!$req->{type}) { $kernel->yield('passback',{ type=>"debug", msg=>"Call to config with no type!", original=>$req }); return; }

	given($req->{type}) {
		when('init')	{ 
			$kernel->post('ConfigLoader','initConfig');
		}
		default		{ $kernel->yield('passback',{ type=>"debug", msg=>"Call to config with unknown type! ($req->{type})", original=>$req }); }
	}
}
sub abort {
	my ($kernel,$self,$session,$req)   = @_[KERNEL,OBJECT,SESSION,ARG0];

	if (!$req->{confirm}) { 
		$kernel->yield('passback',{ type=>"debug", msg=>"ABORT called (this is not good) - waiting 5 seconds to let final posts finish", src=>"CORE" });
		$kernel->delay('abort' => 5,{ original=>$req->{msg}, confirm=>1 });
		return;
	}

	my $diemsg = $req->{original};
	die "\nDEATH MESSAGE: $diemsg \n";
}
sub boot {
	my ($kernel,$self,$session,$req)   = @_[KERNEL,OBJECT,SESSION,ARG0];

	if ($req->{type} eq 'initial') {
		$kernel->yield('passback',{ type=>"debug", msg=>"Initilizing smart config(tm) architecture", src=>"CORE", class=>"debug" });

		foreach my $key (keys %{ $req->{config} }) {
			$kernel->yield('passback',{ type=>"debug", msg=>"Config opt($key): $req->{config}->{$key}", src=>"CORE" });
			if ($req->{config}->{$key} eq 'auto') { $kernel->yield('passback',{ type=>"debug", msg=>"AUTO DETECTING $key", src=>"CORE", class=>"debug" }); }
		}
	}

#	warn $req->{admin};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

POE::SAPI - The simplified POE API

=head1 README

This software is ALPHA and very volatile, expect updates regularly

Ontop of it being alpha remember some of its sub dependants, namely
"L<POE::SAPI::NetTools>" are DEPENDANT on FreeBSD (the devel platform)

This will change for the Beta release; but at the moment there are
more important developments to do.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use warnings;
	use strict;

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

"L<POE>"

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



