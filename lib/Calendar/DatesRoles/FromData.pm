package Calendar::DatesRoles::FromData;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Role::Tiny;
no strict 'refs'; # Role::Tiny imports strict for us

sub _parse_data {
    my $mod = shift;

    return if defined ${"$mod\::_CDFROMDATA_CACHE_MIN_YEAR"};

    my ($min, $max);
    my $fh = \*{"$mod\::DATA"};
    my $i = 0;
    while (my $line = <$fh>) {
        $i++;
        chomp $line;
        next unless $line =~ /\S/;
        next if $line =~ /^#/;
        my @fields = split /;/, $line;
        my $e = {};
        $e->{date} = $fields[0];
        $e->{date} =~ /\A(\d{4})-(\d{2})-(\d{2})(?:T|\z)/a
            or die "BUG: $mod:data #$i: Invalid date syntax '$e->{date}'";
        $e->{year}  = $1;
        $e->{month} = $2 + 0;
        $e->{day}   = $3 + 0;
        $min = $e->{year} if !defined($min) || $min > $e->{year};
        $max = $e->{year} if !defined($max) || $max < $e->{year};
        $e->{summary} = $fields[1];
        $e->{tags} = [split /,/, $fields[2]] if defined $fields[2];
        push @{"$mod\::_CDFROMDATA_CACHE_ENTRIES"}, $e;
    }
    ${"$mod\::_CDFROMDATA_CACHE_MIN_YEAR"} = $min;
    ${"$mod\::_CDFROMDATA_CACHE_MAX_YEAR"} = $max;
}

sub get_min_year {
    my $mod = shift;

    $mod->_parse_data();
    return ${"$mod\::_CDFROMDATA_CACHE_MIN_YEAR"};
}

sub get_max_year {
    my $mod = shift;

    $mod->_parse_data();
    return ${"$mod\::_CDFROMDATA_CACHE_MAX_YEAR"};
}

sub get_entries {
    my $mod = shift;
    my ($year, $month, $day) = @_;

    die "Please specify year" unless defined $year;
    my $min = $mod->get_min_year;
    die "Year is less than earliest supported year $min" if $year < $min;
    my $max = $mod->get_max_year;
    die "Year is greater than latest supported year $max" if $year > $max;

    my $entries = \@{"$mod\::_CDFROMDATA_CACHE_ENTRIES"};
    my @res;
    for my $e (@$entries) {
        next unless $e->{year} == $year;
        next if defined $month && $e->{month} != $month;
        next if defined $day   && $e->{day}   != $day;
        push @res, $e;
    }

    \@res;
}

1;
# ABSTRACT: Provide Calendar::Dates interface to consumer which has __DATA__ section

=head1 DESCRIPTION

This role provides L<Calendar::Dates> interface to modules that puts the entries
in __DATA__ section. Entries should be in the following format:

 YYYY-MM-DD;Summary;tag1,tag2

Blank lines or lines that start with C<#> are ignored.

Examples:

 2019-02-14;Valentine's day
 2019-06-01;Pancasila day


=head1 METHODS

=head2 get_min_year

=head2 get_max_year

=head2 get_entries


=head1 SEE ALSO

L<Calendar::Dates>

L<Calendar::DatesRoles::FromEntriesVar>
