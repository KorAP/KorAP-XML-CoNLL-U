use strict;
use warnings;
use Test::More;
use Test::Script;
use Test::TempDir::Tiny;
use File::Copy;

script_runs([ 'script/korapxml2conllu', '-h' ], { exit => 255 });
script_stderr_like "Description", "Can print help message";

for my $morpho_fname (glob("t/data/*\.*\.zip")) {
    my $base_fname = $morpho_fname =~ s/(.*)\..*\.zip/$1.zip/r;
    die "cannot find $base_fname" if (!-e $base_fname);

    my $conllu_fname = $base_fname =~ s/(.*)\.zip/$1.morpho.conllu/r;
    die "cannot find $conllu_fname" if (!-e $conllu_fname);

    my $expected;
    open(my $fh, '<', $conllu_fname) or die "cannot open file $conllu_fname"; {
        local $/;
        $expected = <$fh>;
    }
    close($fh);
    script_runs([ 'script/korapxml2conllu', $morpho_fname ], "Runs korapxml2conllu with pos and lemma annotated input");
    script_stdout_is $expected, "Converts $morpho_fname correctly";
}

for my $base_fname (glob("t/data/*\.zip")) {
    my $conllu_fname = $base_fname =~ s/(.*)\.zip/$1.conllu/r;
    next if (!-e $conllu_fname);

    my $expected;
    open(my $fh, '<', $conllu_fname) or die "cannot open file $conllu_fname"; {
        local $/;
        $expected = <$fh>;
    }
    close($fh);
    script_runs([ 'script/korapxml2conllu', $base_fname ], "Runs korapxml2conllu with base input");
    script_stdout_is $expected, "Converts $base_fname correctly to CoNLL-U";
}

my $test_tempdir = tempdir();
my $expected;
open(my $fh, '<', "t/data/goe.morpho.conllu"); {
    local $/;
    $expected = <$fh>;
}
close($fh);
script_runs([ 'script/conllu2korapxml', "t/data/goe.morpho.conllu" ], {stdout => "$test_tempdir/goe.tree_tagger.zip"},
    "Converts t/data/goe.morpho.conllu to $test_tempdir/goe.tree_tagger.zip");
copy("t/data/goe.zip", $test_tempdir);
script_runs([ 'script/korapxml2conllu', "$test_tempdir/goe.tree_tagger.zip" ],
    "Converts $test_tempdir/goe.tree_tagger.zip to CoNLL-U");
script_stdout_is $expected, "Full round trip: Converts goe.morpho.conllu to KorAP-XML and back to CoNLL-U correctly";

done_testing;
