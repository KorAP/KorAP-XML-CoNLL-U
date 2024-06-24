use strict;
use warnings;
use Test::More;
use Test::Script;
use Test::TempDir::Tiny;
use File::Copy;

script_runs([ 'script/korapxml2conllu', '-h' ], { exit => 1 });
script_stdout_like "Description", "Can print help message";

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
        $expected =~ s/^(# text_id\s*=\s*[^\s]+)\s*$/$1/mg;
        close($fh);
    } else {
        fail("cannot open file $conllu_fname");
        next;
    }
    script_runs([ 'script/korapxml2conllu', $morpho_fname ], "Runs korapxml2conllu with pos and lemma annotated input");
    script_stdout_is $expected, "Converts $morpho_fname correctly";
}

for my $morpho_fname (glob("t/data/*\.*\.zip")) {
    my $base_fname = $morpho_fname =~ s/(.*)\..*\.zip/$1.zip/r;
    if (!-e $base_fname) {
        fail("cannot find $base_fname");
        next;
    };

    my $conllu_fname = $base_fname =~ s/(.*)\.zip/$1.morpho.sbfm.conllu/r;
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
    script_runs([ 'script/korapxml2conllu', '--s-bounds-from-morpho', $morpho_fname ], "Runs korapxml2conllu with --s-bounds-from-morpho correctly");
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

for my $w2v_fname (glob("t/data/*\.w2v_simple")) {
    my $base_fname = $w2v_fname =~ s/(.*)\.w2v_simple/$1.zip/r;
    next if (!-e $base_fname);

    my $expected;
    if (open(my $fh, '<', $w2v_fname)) {
        local $/;
        $expected = <$fh>;
        close($fh);
    } else {
        fail("cannot open file $w2v_fname");
        next;
    }
    script_runs([ 'script/korapxml2conllu', '--word2vec', $base_fname ], "Runs korapxml2conllu with base input and w2v output");
    script_stdout_is $expected, "Converts $base_fname correctly to word2vec input format";
}

for my $w2v_fname (glob("t/data/*\.w2v")) {
    my $base_fname = $w2v_fname =~ s/(.*)\.w2v/$1.zip/r;
    next if (!-e $base_fname);

    my $expected;
    if (open(my $fh, '<', $w2v_fname)) {
        local $/;
        $expected = <$fh>;
        close($fh);
    } else {
        fail("cannot open file $w2v_fname");
        next;
    }
    script_runs([ 'script/korapxml2conllu', '-m', '<textSigle>([^<.]+)', '-m', '<creatDate>([^<]{4,7})', '--word2vec', $base_fname ], "Runs korapxml2conllu with base input and w2v and metadata output");
    script_stdout_is $expected, "Converts $base_fname correctly to word2vec input format together with some metadata";
}

my $expected;
if (open(my $fh, '<', 't/data/goe.1c.txt')) {
    local $/;
    $expected = <$fh>;
    close($fh);
} else {
    fail("cannot open file.");
}
script_runs([ 'script/korapxml2conllu', '-c',  '1', 't/data/goe.zip' ], "Runs korapxml2conllu in one column mode");
script_stdout_is $expected, "Converts correctly in one column mode.";

my $test_tempdir = tempdir();
my $conllu_fname = "t/data/goe.morpho.conllu";
if(open(my $fh, '<', $conllu_fname )) {
    local $/;
    $expected = <$fh>;
    close($fh);
} else {
    fail("cannot open file $conllu_fname");
  }

ok(length($expected) > 100, 'Output is not empty');

my $zipfile = "$test_tempdir/goe.tree_tagger.zip";
my $zipcontent;
script_runs([ 'script/conllu2korapxml', "t/data/goe.morpho.conllu" ], {stdout => \$zipcontent},
    "Converts t/data/goe.morpho.conllu to KorAP-XML zip");
open(my $fh, ">", $zipfile) or fail("cannot open file $zipfile for writing");
print $fh $zipcontent;
close($fh);
copy("t/data/goe.zip", $test_tempdir);
script_runs([ 'script/korapxml2conllu', "$test_tempdir/goe.tree_tagger.zip" ],
    "Converts $test_tempdir/goe.tree_tagger.zip to CoNLL-U");
script_stdout_is $expected, "Full round trip: Converts goe.morpho.conllu to KorAP-XML and back to CoNLL-U correctly";

script_runs([ 'script/korapxml2conllu', '-e',  'div/type', "t/data/goe.tree_tagger.zip" ], "Runs korapxml2conllu with morpho input and attribute extraction");
script_stdout_like "\n# div/type = Autobiographie\n", "Extracts attributes from morpho zips";
script_stdout_like "\n# div/type = section\n", "Extracts attributes from morpho zips";

script_runs([ 'script/korapxml2conllu', '-e',  '(posting/id|div/id)', "t/data/wdf19.zip" ], "Runs korapxml2conllu with base input and regex attribute extraction");
script_stdout_like "\n# posting/id = i.13075_11_45", "Extracts multiple attributes from base zips (1)";
script_stdout_like "\n# div/id = i.13075_14", "Extracts multiple attributes from base zips (2)";
script_stdout_like "\n# posting/id = i.14548_9_1\n3\tbonjour", "Extracts attributes in the right place";
script_stdout_like "\n# posting/id = i.12610_4_4", "Extracts directly adjacent postings from base zips (1)";
script_stdout_like "\n# posting/id = i.12610_4_5", "Extracts directly adjacent postings from base zips (2)";
script_stdout_like "\n# posting/id = i.14548_9_1", "Extracts last postings in base zip";

script_runs([ 'script/korapxml2conllu', '-e',  '(posting/id|div/id)', "t/data/wdf19.tree_tagger.zip" ], "Runs korapxml2conllu with morpho input and regex attribute extraction");
script_stdout_like "\n# posting/id = i.13075_11_45", "Extracts multiple attributes from morpho zips (1)";
script_stdout_like "\n# div/id = i.13075_14", "Extracts multiple attributes from morpho zips (2)";
script_stdout_like "\n# posting/id = i.12610_4_4", "Extracts directly adjacent postings from morpho zips (1)";
script_stdout_like "\n# posting/id = i.12610_4_5", "Extracts directly adjacent postings from morpho zips (2)";
script_stdout_like "\n# posting/id = i.14548_9_1", "Extracts last postings in morpho zip";

$zipfile = "$test_tempdir/without_lemma.zip";
script_runs([ 'script/conllu2korapxml', "t/data/without_lemma.tsv" ], {stdout => \$zipcontent},
    "Converts t/data/without_lemma.tsv to KorAP-XML zip");
open($fh, ">", $zipfile) or fail("cannot open file $zipfile for writing");
print $fh $zipcontent;
close($fh);
my $UNZIP = `sh -c 'command -v unzip'`;
chomp $UNZIP;

if ($UNZIP eq '') {
    warn('No unzip executable found in PATH.');
    return 0;
};
$zipcontent = `$UNZIP -c $zipfile`;
unlike($zipcontent, qr/.*name ="lemma".*/, "conllu2korapxml igores _ lemmas.");
like($zipcontent, qr/.*<f name="pos">NN|NN<\/f>.*/, "conllu2korapxml does not ignore pos for _ lemmas.");

script_runs([ 'script/conllu2korapxml', '-l', 'debug', 't/data/goe.ud.conllu' ], {stdout => \$zipcontent}, "Runs conllu2korap with UDPipe and unparsable comments");
script_stderr_like "Foundry:\\s+ud", "Found generator based foundry";
script_stderr_like "Ignored\\s+foundry\\s+name:\\s+base", "Ignore defined foundry";

$zipfile = "$test_tempdir/goe.ud.zip";
open($fh, ">", $zipfile) or fail("cannot open file $zipfile for writing");
print $fh $zipcontent;
close($fh);

$zipcontent = `$UNZIP -Z $zipfile`;
like($zipcontent, qr@GOE/AGA/00000/ud/morpho\.xml@, "conllu2korapxml UDPipe input conversion contains morpho layer with foundry name 'ud'");
like($zipcontent, qr@GOE/AGA/00000/ud/dependency\.xml@, "conllu2korapxml UDPipe input conversion contains dependency layer with foundry name 'ud'");
like($zipcontent, qr@rw-rw-rw-.*GOE/AGA/00000/ud/morpho\.xml@, "KorAP-XML zip contents have read and write permissions");

$zipcontent = `$UNZIP -c $zipfile`;
like($zipcontent, qr/.*<f name="upos">VERB<\/f>.*/, "conllu2korapxml extracts upos tags.");
like($zipcontent, qr/.*<f name="pos">VVFIN<\/f>.*/, "conllu2korapxml extracts (x)pos tags.");
unlike($zipcontent, qr/.*<f name="pos">_<\/f>.*/, "conllu2korapxml ignores _ pos tags.");
unlike($zipcontent, qr/.*<f name="upos">_<\/f>.*/, "conllu2korapxml ignores _ upos tags.");

script_runs([ 'script/conllu2korapxml', 't/data/deu-deps.conllu' ], "Runs conllu2korap with UDPipe input");
script_stderr_unlike "fileparse(): need a valid pathname", "Ignore sent_id and newdoc id";
script_stderr_like "WARNING: No valid input document.*token offsets missing", "Warn on missing token offsets";
script_stderr_like qr@WARNING: No valid input document.*text.id .*missing@,   "Warn on missing text ids";

script_runs([ 'script/korapxml2conllu', "t/data/nkjp.zip" ], "Runs korapxml2conllu on nkjp test data");
script_stderr_unlike("Use of uninitialized value", "Handles lonely docid parameters (line separated from layer elements)");
script_stdout_like("\n9\twesołości\twesołość\tsubst\tsubst\tsg:gen:f", "Correctly converts nkjp annotations");

script_runs([ 'script/korapxml2conllu', "--sigle-pattern", "KOT", "t/data/nkjp.zip" ], "Runs korapxml2conllu with --sigle-pattern option on combined base/morpho files");
script_stdout_like("NKJP/NKJP/KOT/nkjp/morpho.xml", "--sigle-pattern to specify a doc sigle pattern extracts the right texts");
script_stdout_unlike("NKJP/NKJP/KolakowskiOco/nkjp/morpho.xml", "--sigle-pattern to specify a doc sigle pattern does not extract the wrong texts");

script_runs([ 'script/korapxml2conllu', "--sigle-pattern", "13072", "t/data/wdf19.tree_tagger.zip" ], "Runs korapxml2conllu with --sigle-pattern option on seprate base/morpho files");
script_stdout_like("WDF19/A0000/13072/tree_tagger/morpho.xml", "--sigle-pattern to specify a text sigle pattern extracts the right texts");
script_stdout_unlike("WDF19/A0000/14247/tree_tagger/morpho.xml", "--sigle-pattern to specify a text sigle pattern does not extract the wrong texts");

script_runs([ 'script/korapxml2conllu', "t/data/nkjp-fail.zip" ], "Runs korapxml2conllu on nkjp-fail test data");
script_stderr_like("could not retrieve token at 1297-1298/ 1297  - ending with:  e! upadku.", "Offset error");

script_runs([ 'script/conllu2korapxml', 't/data/goe.marmot-malt.conllu' ], {stdout => \$zipcontent}, "Runs conllu2korap with marmot and malt annotations");
$zipfile = "$test_tempdir/goe.marmalt.zip";
open($fh, ">", $zipfile) or fail("cannot open file $zipfile for writing");
print $fh $zipcontent;
close($fh);
$zipcontent = `$UNZIP -l $zipfile`;
like($zipcontent, qr@GOE/AGA/00000/marmot/morpho\.xml@, "conllu2korapxml can handle different foundries for motpho and dependency layers");
like($zipcontent, qr@GOE/AGA/00000/malt/dependency\.xml@, "conllu2korapxml sets the secondary dependency foundry correctly");

script_runs([ 'script/conllu2korapxml',  '-f', 'upos dependency:gsd', 't/data/goe.ud.conllu' ], {stdout => \$zipcontent}, "Runs conllu2korap with marmot and malt annotations");
$zipfile = "$test_tempdir/goe.marmalt.zip";
open($fh, ">", $zipfile) or fail("cannot open file $zipfile for writing");
print $fh $zipcontent;
close($fh);
$zipcontent = `$UNZIP -l $zipfile`;
like($zipcontent, qr@GOE/AGA/00000/upos/morpho\.xml@, "conllu2korapxml can handle different foundries for motpho and dependency layers");
like($zipcontent, qr@GOE/AGA/00000/gsd/dependency\.xml@, "conllu2korapxml sets the secondary dependency foundry correctly");

done_testing;
