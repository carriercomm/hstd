package Cpanel::SSHAuthorizedKeys;

use strict;
use warnings;
use Cpanel::PwCache;

=head1 NAME

Cpanel::SSHAuthorizedKeys - manage ~/.ssh/authorized_keys

=head1 DESCRIPTION

This modules used for authorized keys management. Used by sshkeymanager.

=head1 METHODS

=head2 api2

This function specifies which API2 calls are mapped to which functions.
It is also responsible for returning a hash that contains information
on how the module works.

See cpanel dev docs: Writing cPanel Modules/Creating API2 Calls

=cut

sub api2 {
    my $func = shift;
    my $API  = {
        listkeys => {
            func   => 'api2_listkeys',
            engine => 'hasharray',
        },
        importkey => {
            func   => 'api2_importkey',
            engine => 'hasharray',
        },
        delkey => {
            func   => 'api2_delkey',
            engine => 'hasharray',
        },
    };
    return ( \%{ $API->{$func} } );
}

=head2 api2_listkeys

List all keys from ~/.ssh/authorized_keys

Returns:

    <data>
        <type>Key type. Ex: ssh-rsa</type>
        <key>Key hash</key>
        <user>user@host</user>
    </data>

=cut

sub api2_listkeys {
    my @RSD;
    open my $fh, authkeys_file();
    while (<$fh>) {
        my @parts = split / /;
        push @RSD, { type => $parts[0], key => $parts[1], user => $parts[2] };
    }
    close $fh;
    return @RSD;
}

=head2 api2_importkey

Import public key to ~/.ssh/authorized_keys

Parameters:

    key (string) - SSH public key

=cut

sub api2_importkey {
    my %OPTS = @_;
    my $key  = $OPTS{'key'};
    $key =~ s/^\s+//;
    $key =~ s/\s+$//;
    $key =~ s/\n//g;
    open my $fh, '>>', authkeys_file();
    print $fh $key, "\n";
    close $fh;
}

=head2 api2_delkey

Delete public key from ~/.ssh/authorized_keys

Parameters:

    user (string) - Key's user@hostname string. All matching keys will be deleted.

=cut

sub api2_delkey {
    my %OPTS = @_;
    open my $fh, '<', authkeys_file();
    my @lines = <$fh>;
    close $fh;
    @lines = grep { !/\s$OPTS{'user'}$/ } @lines;
    open $fh, '>', authkeys_file();
    print $fh @lines;
    close $fh;
}

=head2 authkeys_file

Get full path of ~/.ssh/authorized_keys

=cut

sub authkeys_file {
    return Cpanel::PwCache::gethomedir() . "/.ssh/authorized_keys";
}

=head1 AUTHOR

Vadim Dashkevich <dashkevich@uacoders.com>

Produced by Taras Mankovski <taras@positivesum.ca>

=head1 COPYRIGHT

HSTD SSH Key Manager. Copyright (C) 2010 HSTD.org

=head1 LICENCE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
