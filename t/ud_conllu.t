use strict;
use warnings;
use Test::More;
use Test::Script;
use Test::TempDir::Tiny;

my $UNZIP = `sh -c 'command -v unzip'`;
chomp $UNZIP;

if ($UNZIP eq '') {
    plan skip_all => 'No unzip executable found in PATH.';
}

my $offset_data = <<'CONLLU';
# filename = TEST/TEST/TEST_OFF_001/base/tokens.xml
# text_id = TEST_TEST.TEST_OFF_001
# text = Geras rytas.
1	Geras	geras	ADJ	bdv.	Case=Nom	2	amod	_	_
2	rytas	rytas	NOUN	dkt.	Case=Nom	0	root	_	_
3	.	.	PUNCT	skyr.	_	2	punct	_	SpaceAfter=No

# text = Kaip sekasi?
1	Kaip	kaip	ADV	prv.	_	2	advmod	_	_
2	sekasi	sektis	VERB	vksm.	_	0	root	_	SpaceAfter=No
3	?	?	PUNCT	skyr.	_	2	punct	_	_

CONLLU

my $test_tempdir = tempdir();
my $offset_file = "$test_tempdir/test_offset.conllu";
{
    open(my $ofh, '>:encoding(UTF-8)', $offset_file)
        or die "Cannot write test file: $!";
    print $ofh $offset_data;
    close($ofh);
}

my $zipcontent_off = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $offset_file ],
    { stdout => \$zipcontent_off },
    "conllu2korapxml computes offsets from # text"
);

my $zipfile_off = "$test_tempdir/test_offset.zip";
if ($zipcontent_off) {
    open(my $zfh, '>:raw', $zipfile_off) or die "Cannot write zip: $!";
    print $zfh $zipcontent_off;
    close($zfh);

    my $morpho_xml = `$UNZIP -p $zipfile_off 'TEST/TEST/TEST_OFF_001/ud/morpho.xml' 2>/dev/null`;

    # Sentence 1: "Geras rytas." (12 chars, starts at 0)
    #   Geras: 0-5, rytas: 6-11, .: 11-12
    like($morpho_xml,
        qr/id="s1_n1" from="0" to="5"/,
        "Computed offset: token 'Geras' at 0..5");
    like($morpho_xml,
        qr/id="s1_n2" from="6" to="11"/,
        "Computed offset: token 'rytas' at 6..11");
    like($morpho_xml,
        qr/id="s1_n3" from="11" to="12"/,
        "Computed offset: token '.' at 11..12 (SpaceAfter=No)");

    # Sentence 2: "Kaip sekasi?" (12 chars, starts at 13 = 12 + 1 space)
    #   Kaip: 13-17, sekasi: 18-24, ?: 24-25
    like($morpho_xml,
        qr/id="s2_n1" from="13" to="17"/,
        "Computed offset: token 'Kaip' at 13..17 (sentence 2)");
    like($morpho_xml,
        qr/id="s2_n2" from="18" to="24"/,
        "Computed offset: token 'sekasi' at 18..24");
    like($morpho_xml,
        qr/id="s2_n3" from="24" to="25"/,
        "Computed offset: token '?' at 24..25 (SpaceAfter=No)");

    # Verify dependency XML has correct offsets (head references)
    my $dep_xml = `$UNZIP -p $zipfile_off 'TEST/TEST/TEST_OFF_001/ud/dependency.xml' 2>/dev/null`;

    # Token 1 "Geras" (0..5) -> head token 2 "rytas" (6..11)
    like($dep_xml,
        qr/id="s1_n1" from="0" to="5".*?<span from="6" to="11"/s,
        "Dependency: 'Geras' head points to 'rytas' offsets");

    # Token 2 "rytas" (6..11) -> head 0 = sentence span (0..12)
    like($dep_xml,
        qr/id="s1_n2" from="6" to="11".*?<span from="0" to="12"/s,
        "Dependency: 'rytas' head points to sentence span");
}
else {
    fail("Computed offset: token 'Geras' at 0..5");
    fail("Computed offset: token 'rytas' at 6..11");
    fail("Computed offset: token '.' at 11..12 (SpaceAfter=No)");
    fail("Computed offset: token 'Kaip' at 13..17 (sentence 2)");
    fail("Computed offset: token 'sekasi' at 18..24");
    fail("Computed offset: token '?' at 24..25 (SpaceAfter=No)");
    fail("Dependency: 'Geras' head points to 'rytas' offsets");
    fail("Dependency: 'rytas' head points to sentence span");
}

# No SpaceAfter at all - every token has normal space separation
my $no_spaceafter_data = <<'CONLLU';
# filename = TEST/TEST/TEST_NSA_001/base/tokens.xml
# text_id = TEST_TEST.TEST_NSA_001
# text = One two three
1	One	one	NUM	num.	_	0	root	_	_
2	two	two	NUM	num.	_	1	flat	_	_
3	three	three	NUM	num.	_	1	flat	_	_

CONLLU

my $nsa_file = "$test_tempdir/test_no_spaceafter.conllu";
{
    open(my $nfh, '>:encoding(UTF-8)', $nsa_file)
        or die "Cannot write test file: $!";
    print $nfh $no_spaceafter_data;
    close($nfh);
}

my $zipcontent_nsa = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $nsa_file ],
    { stdout => \$zipcontent_nsa },
    "conllu2korapxml handles tokens with no SpaceAfter"
);

my $zipfile_nsa = "$test_tempdir/test_no_spaceafter.zip";
if ($zipcontent_nsa) {
    open(my $zfh, '>:raw', $zipfile_nsa) or die "Cannot write zip: $!";
    print $zfh $zipcontent_nsa;
    close($zfh);

    my $morpho_nsa = `$UNZIP -p $zipfile_nsa 'TEST/TEST/TEST_NSA_001/ud/morpho.xml' 2>/dev/null`;

    # "One two three" = 13 chars
    #   One: 0-3, two: 4-7, three: 8-13
    like($morpho_nsa,
        qr/id="s1_n1" from="0" to="3"/,
        "No SpaceAfter: token 'One' at 0..3");
    like($morpho_nsa,
        qr/id="s1_n2" from="4" to="7"/,
        "No SpaceAfter: token 'two' at 4..7");
    like($morpho_nsa,
        qr/id="s1_n3" from="8" to="13"/,
        "No SpaceAfter: token 'three' at 8..13");
}
else {
    fail("No SpaceAfter: token 'One' at 0..3");
    fail("No SpaceAfter: token 'two' at 4..7");
    fail("No SpaceAfter: token 'three' at 8..13");
}

# Adjacent tokens - no space between consecutive tokens (SpaceAfter=No)
my $adjacent_data = <<'CONLLU';
# filename = TEST/TEST/TEST_ADJ_001/base/tokens.xml
# text_id = TEST_TEST.TEST_ADJ_001
# text = foo(bar)baz end
1	foo	foo	NOUN	n.	_	0	root	_	SpaceAfter=No
2	(	(	PUNCT	skyr.	_	3	punct	_	SpaceAfter=No
3	bar	bar	NOUN	n.	_	1	appos	_	SpaceAfter=No
4	)	)	PUNCT	skyr.	_	3	punct	_	SpaceAfter=No
5	baz	baz	NOUN	n.	_	1	conj	_	_
6	end	end	NOUN	n.	_	1	conj	_	_

CONLLU

my $adj_file = "$test_tempdir/test_adjacent.conllu";
{
    open(my $afh, '>:encoding(UTF-8)', $adj_file)
        or die "Cannot write test file: $!";
    print $afh $adjacent_data;
    close($afh);
}

my $zipcontent_adj = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $adj_file ],
    { stdout => \$zipcontent_adj },
    "conllu2korapxml handles adjacent tokens without spaces"
);

my $zipfile_adj = "$test_tempdir/test_adjacent.zip";
if ($zipcontent_adj) {
    open(my $zfh, '>:raw', $zipfile_adj) or die "Cannot write zip: $!";
    print $zfh $zipcontent_adj;
    close($zfh);

    my $morpho_adj = `$UNZIP -p $zipfile_adj 'TEST/TEST/TEST_ADJ_001/ud/morpho.xml' 2>/dev/null`;

    # "foo(bar)baz end" = 15 chars
    #   foo: 0-3, (: 3-4, bar: 4-7, ): 7-8, baz: 8-11, end: 12-15
    like($morpho_adj,
        qr/id="s1_n1" from="0" to="3"/,
        "Adjacent: token 'foo' at 0..3");
    like($morpho_adj,
        qr/id="s1_n2" from="3" to="4"/,
        "Adjacent: token '(' at 3..4 (no space before)");
    like($morpho_adj,
        qr/id="s1_n3" from="4" to="7"/,
        "Adjacent: token 'bar' at 4..7 (no space before)");
    like($morpho_adj,
        qr/id="s1_n4" from="7" to="8"/,
        "Adjacent: token ')' at 7..8 (no space before)");
    like($morpho_adj,
        qr/id="s1_n5" from="8" to="11"/,
        "Adjacent: token 'baz' at 8..11 (no space before)");
    like($morpho_adj,
        qr/id="s1_n6" from="12" to="15"/,
        "Adjacent: token 'end' at 12..15 (space before)");
}
else {
    fail("Adjacent: token 'foo' at 0..3");
    fail("Adjacent: token '(' at 3..4 (no space before)");
    fail("Adjacent: token 'bar' at 4..7 (no space before)");
    fail("Adjacent: token ')' at 7..8 (no space before)");
    fail("Adjacent: token 'baz' at 8..11 (no space before)");
    fail("Adjacent: token 'end' at 12..15 (space before)");
}

# Repeated token form - same word appears multiple times in sentence
my $repeat_data = <<'CONLLU';
# filename = TEST/TEST/TEST_REP_001/base/tokens.xml
# text_id = TEST_TEST.TEST_REP_001
# text = the cat and the dog
1	the	the	DET	det.	_	2	det	_	_
2	cat	cat	NOUN	n.	_	0	root	_	_
3	and	and	CCONJ	cc.	_	5	cc	_	_
4	the	the	DET	det.	_	5	det	_	_
5	dog	dog	NOUN	n.	_	2	conj	_	_

CONLLU

my $rep_file = "$test_tempdir/test_repeat.conllu";
{
    open(my $rfh, '>:encoding(UTF-8)', $rep_file)
        or die "Cannot write test file: $!";
    print $rfh $repeat_data;
    close($rfh);
}

my $zipcontent_rep = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $rep_file ],
    { stdout => \$zipcontent_rep },
    "conllu2korapxml handles repeated token forms"
);

my $zipfile_rep = "$test_tempdir/test_repeat.zip";
if ($zipcontent_rep) {
    open(my $zfh, '>:raw', $zipfile_rep) or die "Cannot write zip: $!";
    print $zfh $zipcontent_rep;
    close($zfh);

    my $morpho_rep = `$UNZIP -p $zipfile_rep 'TEST/TEST/TEST_REP_001/ud/morpho.xml' 2>/dev/null`;

    # "the cat and the dog" = 19 chars
    #   the: 0-3, cat: 4-7, and: 8-11, the: 12-15, dog: 16-19
    like($morpho_rep,
        qr/id="s1_n1" from="0" to="3"/,
        "Repeated: first 'the' at 0..3");
    like($morpho_rep,
        qr/id="s1_n2" from="4" to="7"/,
        "Repeated: 'cat' at 4..7");
    like($morpho_rep,
        qr/id="s1_n4" from="12" to="15"/,
        "Repeated: second 'the' at 12..15 (not matching first)");
    like($morpho_rep,
        qr/id="s1_n5" from="16" to="19"/,
        "Repeated: 'dog' at 16..19");
}
else {
    fail("Repeated: first 'the' at 0..3");
    fail("Repeated: 'cat' at 4..7");
    fail("Repeated: second 'the' at 12..15 (not matching first)");
    fail("Repeated: 'dog' at 16..19");
}

# Single-token sentence - minimal sentence with only one word
my $single_data = <<'CONLLU';
# filename = TEST/TEST/TEST_SNG_001/base/tokens.xml
# text_id = TEST_TEST.TEST_SNG_001
# text = Hello
1	Hello	hello	INTJ	intj.	_	0	root	_	_

# text = World
1	World	world	NOUN	n.	_	0	root	_	_

CONLLU

my $sng_file = "$test_tempdir/test_single.conllu";
{
    open(my $sfh, '>:encoding(UTF-8)', $sng_file)
        or die "Cannot write test file: $!";
    print $sfh $single_data;
    close($sfh);
}

my $zipcontent_sng = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $sng_file ],
    { stdout => \$zipcontent_sng },
    "conllu2korapxml handles single-token sentences"
);

my $zipfile_sng = "$test_tempdir/test_single.zip";
if ($zipcontent_sng) {
    open(my $zfh, '>:raw', $zipfile_sng) or die "Cannot write zip: $!";
    print $zfh $zipcontent_sng;
    close($zfh);

    my $morpho_sng = `$UNZIP -p $zipfile_sng 'TEST/TEST/TEST_SNG_001/ud/morpho.xml' 2>/dev/null`;

    # Sentence 1: "Hello" (5 chars, starts at 0)
    # Sentence 2: "World" (5 chars, starts at 6 = 5 + 1 space)
    like($morpho_sng,
        qr/id="s1_n1" from="0" to="5"/,
        "Single-token: 'Hello' at 0..5");
    like($morpho_sng,
        qr/id="s2_n1" from="6" to="11"/,
        "Single-token: 'World' at 6..11 (after space separator)");
}
else {
    fail("Single-token: 'Hello' at 0..5");
    fail("Single-token: 'World' at 6..11 (after space separator)");
}

# Explicit offsets take precedence over # text when both are present
my $explicit_wins_data = <<'CONLLU';
# filename = TEST/TEST/TEST_EXP_001/base/tokens.xml
# text_id = TEST_TEST.TEST_EXP_001
# text = Geras rytas.
# start_offsets = 0 100 200 300
# end_offsets = 999 199 299 399
1	Geras	geras	ADJ	bdv.	Case=Nom	2	amod	_	_
2	rytas	rytas	NOUN	dkt.	Case=Nom	0	root	_	_
3	.	.	PUNCT	skyr.	_	2	punct	_	_

CONLLU

my $exp_file = "$test_tempdir/test_explicit.conllu";
{
    open(my $efh, '>:encoding(UTF-8)', $exp_file)
        or die "Cannot write test file: $!";
    print $efh $explicit_wins_data;
    close($efh);
}

my $zipcontent_exp = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $exp_file ],
    { stdout => \$zipcontent_exp },
    "conllu2korapxml uses explicit offsets when both # text and offsets present"
);

my $zipfile_exp = "$test_tempdir/test_explicit.zip";
if ($zipcontent_exp) {
    open(my $zfh, '>:raw', $zipfile_exp) or die "Cannot write zip: $!";
    print $zfh $zipcontent_exp;
    close($zfh);

    my $morpho_exp = `$UNZIP -p $zipfile_exp 'TEST/TEST/TEST_EXP_001/ud/morpho.xml' 2>/dev/null`;
    like($morpho_exp,
        qr/id="s1_n1" from="100" to="199"/,
        "Explicit offsets win: token uses from=100 (not computed 0)");
}
else {
    fail("Explicit offsets win: token uses from=100 (not computed 0)");
}

# -------------------------------------------------------------------
# Inline test data: minimal UD CoNLL-U with explicit offsets.
# Uses "# newdoc id" (UD style) instead of "# filename" / "# text_id"
# (KorAP style). Explicit offsets are provided so this test does not
# depend on automatic offset computation.
# -------------------------------------------------------------------

my $ud_conllu_data = <<'CONLLU';
# newdoc id = TEST_LIT_001
# start_offsets = 0 0 6 11
# end_offsets = 12 5 11 12
1	Geras	geras	ADJ	bdv.	Case=Nom	2	amod	_	_
2	rytas	rytas	NOUN	dkt.	Case=Nom	0	root	_	_
3	.	.	PUNCT	skyr.	_	2	punct	_	_

CONLLU

my $conllu_file = "$test_tempdir/test_ud.conllu";
{
    open(my $fh, '>:encoding(UTF-8)', $conllu_file)
        or die "Cannot write test file: $!";
    print $fh $ud_conllu_data;
    close($fh);
}

my $zipcontent = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud',
      '--text-sigle', 'TEST/TEST/{ID}', $conllu_file ],
    { stdout => \$zipcontent },
    "conllu2korapxml accepts --text-sigle with UD CoNLL-U input"
);

my $zipfile = "$test_tempdir/test_newdoc.zip";
if ($zipcontent) {
    open(my $zfh, '>:raw', $zipfile) or die "Cannot write zip: $!";
    print $zfh $zipcontent;
    close($zfh);

    my $ziplist = `$UNZIP -l $zipfile 2>/dev/null`;
    like($ziplist,
        qr@TEST/TEST/TEST_LIT_001/ud/morpho\.xml@,
        "Zip contains morpho.xml at path derived from newdoc id");
    like($ziplist,
        qr@TEST/TEST/TEST_LIT_001/ud/dependency\.xml@,
        "Zip contains dependency.xml at path derived from newdoc id");

    my $zipdata = `$UNZIP -c $zipfile 2>/dev/null`;
    like($zipdata,
        qr/docid="TEST_TEST\.TEST_LIT_001"/,
        "docid correctly derived from text-sigle template and newdoc id");
}
else {
    fail("Zip contains morpho.xml at path derived from newdoc id");
    fail("Zip contains dependency.xml at path derived from newdoc id");
    fail("docid correctly derived from text-sigle template and newdoc id");
}

my $zipcontent_lc = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud',
      '--text-sigle', 'TEST/TEST/{id}', $conllu_file ],
    { stdout => \$zipcontent_lc },
    "text-sigle template accepts {id} (lowercase)"
);

if ($zipcontent_lc) {
    my $zipfile_lc = "$test_tempdir/test_lc.zip";
    open(my $zfh, '>:raw', $zipfile_lc) or die "Cannot write zip: $!";
    print $zfh $zipcontent_lc;
    close($zfh);

    my $zipdata_lc = `$UNZIP -c $zipfile_lc 2>/dev/null`;
    like($zipdata_lc,
        qr/docid="TEST_TEST\.TEST_LIT_001"/,
        "docid correct with lowercase {id} template");
}
else {
    fail("docid correct with lowercase {id} template");
}

my $zipcontent_mc = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud',
      '--text-sigle', 'TEST/TEST/{Id}', $conllu_file ],
    { stdout => \$zipcontent_mc },
    "text-sigle template accepts {Id} (mixed case)"
);

if ($zipcontent_mc) {
    my $zipfile_mc = "$test_tempdir/test_mc.zip";
    open(my $zfh, '>:raw', $zipfile_mc) or die "Cannot write zip: $!";
    print $zfh $zipcontent_mc;
    close($zfh);

    my $zipdata_mc = `$UNZIP -c $zipfile_mc 2>/dev/null`;
    like($zipdata_mc,
        qr/docid="TEST_TEST\.TEST_LIT_001"/,
        "docid correct with mixed-case {Id} template");
}
else {
    fail("docid correct with mixed-case {Id} template");
}

# Template with only 2 parts (missing corpus level)
my $err_2parts = `$^X script/conllu2korapxml -f ud --text-sigle 'TEST/{ID}' $conllu_file 2>&1`;
isnt($? >> 8, 0, "Rejects template with only 2 parts (non-zero exit)");
like($err_2parts, qr/ERROR/, "Error message for 2-part template");

# Template with 4 parts (too many levels)
my $err_4parts = `$^X script/conllu2korapxml -f ud --text-sigle 'A/B/C/{ID}' $conllu_file 2>&1`;
isnt($? >> 8, 0, "Rejects template with 4 parts (non-zero exit)");
like($err_4parts, qr/ERROR/, "Error message for 4-part template");

# Template with empty middle part
my $err_empty = `$^X script/conllu2korapxml -f ud --text-sigle 'TEST//{ID}' $conllu_file 2>&1`;
isnt($? >> 8, 0, "Rejects template with empty part (non-zero exit)");
like($err_empty, qr/ERROR/, "Error message for empty-part template");

# Template with only 1 part (no slashes)
my $err_1part = `$^X script/conllu2korapxml -f ud --text-sigle '{ID}' $conllu_file 2>&1`;
isnt($? >> 8, 0, "Rejects template with only 1 part (non-zero exit)");
like($err_1part, qr/ERROR/, "Error message for 1-part template");

my $bad_id_data = <<'CONLLU';
# newdoc id = BAD/SLASH_ID
# start_offsets = 0 0
# end_offsets = 4 4
1	Test	test	NOUN	NN	_	0	root	_	_

CONLLU

my $bad_id_file = "$test_tempdir/bad_id.conllu";
{
    open(my $bfh, '>:encoding(UTF-8)', $bad_id_file)
        or die "Cannot write test file: $!";
    print $bfh $bad_id_data;
    close($bfh);
}

my $err_slash = `$^X script/conllu2korapxml -f ud --text-sigle 'A/B/{ID}' $bad_id_file 2>&1`;
isnt($? >> 8, 0,
    "Rejects newdoc id with slash (expanded sigle has wrong part count)");
like($err_slash, qr/ERROR/,
    "Error message for newdoc id containing slash");
done_testing;
