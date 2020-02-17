#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'korapxmlconllu',
  AUTHOR       => 'Marc Kupietz',
  ABSTRACT     => 'Conversion between CoNLL-U formats  KorAP-XML',
  VERSION      => '0.1',
  LICENSE      => 'freebsd',
  BUILD_REQUIRES => {
  },
  PREREQ_PM => {
    'IO::Compress::Zip' => '2.091',
    'POSIX'=> 0,
    'Getopt::Std' => 0,
    'Encode' => 0,
    'List::Util' => 0
  },
  MIN_PERL_VERSION => '5.016',
  EXE_FILES => ['./script/korapxml2conllu']
);
