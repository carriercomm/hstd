package Cpanel::RepositoryManager;

use strict;
use warnings;
use File::Path;
use Git;

=head1 NAME

Cpanel::RepositoryManager - manage git/hg repositories

=head1 DESCRIPTION

Manage git/hg repositories, clone remote repo, checkout, view log etc.

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
        repo_list => {
            func   => 'api2_repo_list',
            engine => 'hasharray',
        },
        recent_log => {
            func   => 'api2_recent_log',
            engine => 'hasharray',
        },
        init => {
            func   => 'api2_init',
            engine => 'hasharray',
        },
        clone_remote => {
            func   => 'api2_clone_remote',
            engine => 'hasharray',
        },
    };
    return ( \%{ $API->{$func} } );
}

=head2 api2_repo_list

List existing repositories

Returns:

    <data>
        <repo_name>Repository name</repo_name>
        <repo_type>Repository type</repo_type>
    </data>

=cut

sub api2_repo_list {
    return repo_list();
}

=head2 repo_list

Return hasharr { name, type } for all existing repositories.

=cut

sub repo_list {
    opendir my $dh, repo_path();
    my @repos = grep { !/^\./ } readdir $dh;
    closedir $dh;
    return if not @repos;

    my @repo_list;
    foreach my $repo_name (@repos) {
        my $repo_type;
        $repo_type = 'git' if -d repo_path() . $repo_name . "/.git";    # ugly. change this
        $repo_type = 'hg'  if -d repo_path() . $repo_name . "/.hg";
        push @repo_list, { repo_name => $repo_name, repo_type => $repo_type };
    }
    return @repo_list;
}

=head2 api2_recent_log

Return last 20 log entries for all repos sorted by commit timestamp

Returns:

    <data>
        <repo_name>Repository name</repo_name>
        <abb_hash>Abbreviated commit hash</abb_hash>
        <timestamp>Commit timestamp</timestamp>
        <subject>Commit subject</subject>
    </data>

=cut

sub api2_recent_log {
    my @RSD;
    foreach my $repo ( repo_list() ) {
        push @RSD, git_log( $repo->{repo_name} ) if $repo->{repo_type} eq 'git';
    }
    @RSD = sort { $b->{timestamp} <=> $a->{timestamp} } @RSD;
    return @RSD[ 0 .. 19 ];    # limit output to 20 records in total
}

=head2 git_log

Get Git log and prepare desired output

=cut

sub git_log {
    my $repo_name = shift;
    my $repo_path = repo_path($repo_name);
    return if not -d "$repo_path/.git/logs";
    return map {
        /^'?(\S{7}) (\d{10}) (.*)'?$/;
        {
            repo_name => $repo_name,
            abb_hash  => $1,
            timestamp => $2,
            subject   => $3,
        };

    } `git --git-dir=$repo_path/.git log --pretty=format:'%h %ct %s'`;
}

=head2 api2_init

Parameters:

    repo_type (string) - repository type (git/hg)
    repo_name (string) - repository name

Returns:

    <data>
        <output>Command output</output>
    </data>

=cut

sub api2_init {
    my %OPTS      = @_;
    my $repo_path = repo_path( $OPTS{'repo_name'} );
    my $output;
    if ( $OPTS{'repo_type'} eq 'git' ) {
        $output = `git init $repo_path 2>&1`;
    }
    return { output => $output };
}

=head2 api2_clone_remote

Clone remote repository

For some reason only first line of output captured. Check this later.

Example output:

    Cloning into fsck...
    remote: Counting objects: 134, done.
    remote: Compressing objects: 100% (117/117), done.
    remote: Total 134 (delta 51), reused 0 (delta 0)
    Receiving objects: 100% (134/134), 14.38 KiB, done.
    Resolving deltas: 100% (51/51), done.


Params:

    repo_url (string) - repository url
    repo_type (string) - repository type

Returns:

    <data>
        <output>Command output</output>
    </data>

=cut

sub api2_clone_remote {
    my %OPTS = @_;
    if ( $OPTS{'repo_type'} eq 'git' ) {
        my @parts = split /\//, $OPTS{'repo_url'};
        $parts[-1] =~ s/\.git$//;
        my $repo_path = repo_path( $parts[-1] );
        my $output    = `git clone $OPTS{'repo_url'} $repo_path 2>&1`;
        return { output => $output };
    }
}

=head2 repo_path

Return full path to repository

=cut

sub repo_path {
    return $Cpanel::homedir . "/repos/" . shift;
}

=head2 repo_type

Return repository type

=cut

sub repo_type {
    my $repo_path = repo_path(shift);
    return "git" if -d $repo_path . "/.git";
    return "hg"  if -d $repo_path . "/.hg";
}

=head1 AUTHOR

Vadim Dashkevich <dashkevich@uacoders.com>

Produced by Taras Mankovski <taras@positivesum.ca>

=head1 COPYRIGHT

HSTD Repository Manager. Copyright (C) 2010 HSTD.org

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
