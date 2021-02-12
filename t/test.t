use strict;
use warnings;
use Test::More;
use Test::Script;

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

done_testing;