# vim: expandtab:ts=4

package mods::basic::basic;

use strict;
use warnings;
use threads;

sub init {
    return {
        ping => 'hping',
        raw => 'hraw',
        privmsg => 'hprivmsg',
        command => 'hcommand',
        help => 'hhelp',
    };
}

sub crap {
    undef &hraw;
    undef &hping;
    undef &hprivmsg;
    undef &hcommand;
    undef &hhelp;
    undef &lsmod;
    undef &killthreads;
    undef &lsthreads;
}

sub hraw {
    shift;
    my $e = shift;

    if ($e->{raw} == 1) {
        my @chans = split(/\s*,\s*/, $e->{sinfo}->{chans});
        foreach (@chans) {
            print "  Joining $_\n";
            print {$e->{sock}} 'JOIN '.$_."\r\n";
        }
    } elsif ($e->{raw} == 433) {
        print {$e->{sock}} 'NICK '.$e->{sinfo}->{anick}."\r\n".
                           'USER '.$e->{sinfo}->{username}.
                           ' 0 0 :'.$e->{sinfo}->{realname}."\r\n";
        $e->{conns}->{$e->{server}}->{curnick} = $e->{sinfo}->{anick};
    }
}

sub hping {
    shift;
    my $e = shift;

    print {$e->{sock}} 'PONG '.$e->{data}."\r\n";
}

sub hprivmsg {
    shift;
    my $e = shift;

    # CTCP version request.
    if ($e->{data} eq "\1VERSION\1") {
        # Send version reply.
        print {$e->{sock}} 'NOTICE '.$e->{dest}.
                           " :\1VERSION robo-lite v12".
                           " - pwnagest b0t in teh w0rld.\1\r\n";
    }
}

sub hcommand {
    shift;
    my $e = shift;

    if ($e->{data} =~ /^source/) {
        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                           " :http://github.com/mjhayes/robo-lite\r\n";
    } elsif ($e->{data} =~ /^lsmod/) {
        lsmod($e);
    } elsif ($e->{data} =~ /^killthreads/) {
        killthreads($e);
    } elsif ($e->{data} =~ /^lsthreads/) {
        lsthreads($e);
    }
}

sub hhelp {
    shift;
    my $e = shift;

    print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                       " :lsmod - List loaded modules\r\n";
}

sub lsmod {
    my $e = shift;

    my $m = ' :';
    foreach (keys(%{$e->{mods}})) {
        $m .= "$_ ";
    }

    print {$e->{sock}} 'PRIVMSG '.$e->{dest}.$m."\r\n";
}

sub killthreads {
    my $e = shift;

    my @running = threads->list(threads::running);
    foreach (@running) {
        if ($_->tid() != threads->tid() && $_->tid() != $e->{tid}) {
            print {$e->{sock}} 'PRIVMSG '.$e->{dest}.' :Killing thread '.$_->tid()."\r\n";
            $_->kill('KILL')->detach();
        }
    }
}

sub lsthreads {
    my $e = shift;

    my @running = threads->list(threads::running);
    foreach (@running) {
        my $xtra = '';

        if ($_->tid() == threads->tid()) {
            $xtra = ' (current)';
        } elsif ($_->tid() == $e->{tid}) {
            $xtra = ' (core)';
        }
        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.' :Thread '.$_->tid().$xtra."\r\n";
    }
}

1;
