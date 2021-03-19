#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'korapxml2conllu',
    AUTHOR           => 'Marc Kupietz',
    ABSTRACT         => 'Conversion between KorAP-XML zip and CoNLL-U',
    VERSION_FROM     => 'script/korapxml2conllu',
    LICENSE          => 'freebsd',
    BUILD_REQUIRES   => {
        'Test::More'          => "1.302177",
        'Test::Script'        => "1.12",
        'Test::TempDir::Tiny' => 0,
        'File::Temp'          => 0.2308,
        'Pod::Usage'          => 0,
        'IO::Compress::Zip'   => '2.091',
    },
    PREREQ_PM        => {
        'POSIX'             => 0,
        'Getopt::Std'       => 0,
        'Getopt::Long'      => 0,
        'Log::Any'          => '1.708',
        'Encode'            => "3.07",
        'IO::Compress::Zip' => '2.091'
    },
    MIN_PERL_VERSION => '5.016',
    EXE_FILES        => [ './script/korapxml2conllu', './script/conllu2korapxml' ]
);
