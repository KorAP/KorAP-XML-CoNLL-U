use strict;
use warnings;
use Test::More tests => 9;
use Test::Script;
use Test::TempDir::Tiny;
use File::Copy;

script_runs([ 'script/korapxml2conllu', '-h' ], { exit => 255 });
script_stderr_like "Description", "Can print help message";

for my $morpho_fname (glob("t/data/*\.*\.zip")) {
    my $base_fname = $morpho_fname =~ s/(.*)\..*\.zip/$1.zip/r;
    if (!-e $base_fname) {
        fail("cannot find $base_fname");
        next;
    };

    my $conllu_fname = $base_fname =~ s/(.*)\.zip/$1.morpho.conllu/r;
    if (!-e $conllu_fname) {
        fail("cannot find $conllu_fname");
        next;
    };

    my $expected;
    if (open(my $fh, '<', $conllu_fname)) {
        local $/;
        $expected = <$fh>;
        close($fh);
    } else {
        fail("cannot open file $conllu_fname");
        next;
    }
    script_runs([ 'script/korapxml2conllu', $morpho_fname ], "Runs korapxml2conllu with pos and lemma annotated input");
    script_stdout_is $expected, "Converts $morpho_fname correctly";
}

for my $base_fname (glob("t/data/*\.zip")) {
    my $conllu_fname = $base_fname =~ s/(.*)\.zip/$1.conllu/r;
    next if (!-e $conllu_fname);

    my $expected;
    if (open(my $fh, '<', $conllu_fname)) {
        local $/;
        $expected = <$fh>;
        close($fh);
    } else {
        fail("cannot open file $conllu_fname");
        next;
    }
    script_runs([ 'script/korapxml2conllu', $base_fname ], "Runs korapxml2conllu with base input");
    script_stdout_is $expected, "Converts $base_fname correctly to CoNLL-U";
}

my $test_tempdir = tempdir();
my $expected;
my $conllu_fname = "t/data/goe.morpho.conllu";
if(open(my $fh, '<', $conllu_fname )) {
    local $/;
    $expected = <$fh>;
    close($fh);
} else {
    fail("cannot open file $conllu_fname");
}
script_runs([ 'script/conllu2korapxml', "t/data/goe.morpho.conllu" ], {stdout => "$test_tempdir/goe.tree_tagger.zip"},
    "Converts t/data/goe.morpho.conllu to $test_tempdir/goe.tree_tagger.zip");
copy("t/data/goe.zip", $test_tempdir);
script_runs([ 'script/korapxml2conllu', "$test_tempdir/goe.tree_tagger.zip" ],
    "Converts $test_tempdir/goe.tree_tagger.zip to CoNLL-U");
script_stdout_is $expected, "Full round trip: Converts goe.morpho.conllu to KorAP-XML and back to CoNLL-U correctly";
done_testing;
