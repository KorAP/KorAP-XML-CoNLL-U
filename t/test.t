use strict;
use warnings;
use Test::More tests => 6;
use Test::Script;

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
    }
    else {
        fail("cannot open file $conllu_fname");
        next;
    };

    script_runs([ 'script/korapxml2conllu', $morpho_fname ], "Runs with input");
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
    }
    else {
        fail("cannot open file $conllu_fname");
        next;
    };
    script_runs([ 'script/korapxml2conllu', $base_fname ], "Runs with input");
    script_stdout_is $expected, "Converts $base_fname correctly";
}

done_testing;
