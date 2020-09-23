#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'korapxml2conllu',
    AUTHOR           => 'Marc Kupietz',
    ABSTRACT         => 'Conversion from KorAP-XML zip files to CoNLL-U format',
    VERSION          => '0.1',
    LICENSE          => 'freebsd',
    BUILD_REQUIRES   => {
    },
    PREREQ_PM        => {
        'POSIX'        => 0,
        'Getopt::Std'  => 0,
        'Encode'       => "3.07",
        'Test::More'   => "1.302177",
        'Test::Script' => "1.12"
    },
    MIN_PERL_VERSION => '5.016',
    EXE_FILES        => [ './script/korapxml2conllu' ]
);
