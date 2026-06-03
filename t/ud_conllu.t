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

my $misc_data = <<'CONLLU';
# filename = TEST/TEST/TEST_MISC_001/base/tokens.xml
# text_id = TEST_TEST.TEST_MISC_001
# start_offsets = 0 0 6 11
# end_offsets = 12 5 11 12
1	Geras	geras	ADJ	bdv.	Case=Nom	2	amod	_	SpaceAfter=No|Tag=NNN
2	rytas	rytas	NOUN	dkt.	Case=Nom	0	root	_	Tag=LLL
3	.	.	PUNCT	skyr.	_	2	punct	_	SpaceAfter=No

# start_offsets = 12 13 18 24
# end_offsets = 25 17 24 25
1	Kaip	kaip	ADV	prv.	_	2	advmod	_	SpacesAfter=\n|Tag=MMM
2	sekasi	sektis	VERB	vksm.	_	0	root	_	_
3	?	?	PUNCT	skyr.	_	2	punct	_	_

CONLLU

my $struct_data = <<'CONLLU';
# filename = TEST/TEST/TEST_STR_001/base/tokens.xml
# text_id = TEST_TEST.TEST_STR_001
# newpar id = p1
# sent_id = s1.1
# start_offsets = 0 0 6 11
# end_offsets = 12 5 11 12
1	Geras	geras	ADJ	bdv.	Case=Nom	2	amod	_	_
2	rytas	rytas	NOUN	dkt.	Case=Nom	0	root	_	_
3	.	.	PUNCT	skyr.	_	2	punct	_	SpaceAfter=No

# sent_id = s1.2
# start_offsets = 12 13 18 24
# end_offsets = 25 17 24 25
1	Kaip	kaip	ADV	prv.	_	2	advmod	_	_
2	sekasi	sektis	VERB	vksm.	_	0	root	_	SpaceAfter=No
3	?	?	PUNCT	skyr.	_	2	punct	_	_

# newpar id = p2
# sent_id = s2.1
# start_offsets = 25 26 32
# end_offsets = 39 31 39
1	Labas	labas	ADJ	bdv.	Case=Nom	0	root	_	_
2	vakaras	vakaras	NOUN	dkt.	Case=Nom	1	nmod	_	_

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

my $base_text_data = <<'CONLLU';
# filename = TEST/TEST/TEST_BTX_001/base/tokens.xml
# text_id = TEST_TEST.TEST_BTX_001
# text = Geras rytas.
# start_offsets = 0 0 6 11
# end_offsets = 12 5 11 12
1	Geras	geras	ADJ	bdv.	Case=Nom	2	amod	_	_
2	rytas	rytas	NOUN	dkt.	Case=Nom	0	root	_	_
3	.	.	PUNCT	skyr.	_	2	punct	_	SpaceAfter=No

# text = Kaip sekasi?
# start_offsets = 12 13 18 24
# end_offsets = 25 17 24 25
1	Kaip	kaip	ADV	prv.	_	2	advmod	_	_
2	sekasi	sektis	VERB	vksm.	_	0	root	_	SpaceAfter=No
3	?	?	PUNCT	skyr.	_	2	punct	_	_

CONLLU

my $btx_file = "$test_tempdir/test_base_text.conllu";
{
    open(my $bfh, '>:encoding(UTF-8)', $btx_file)
        or die "Cannot write test file: $!";
    print $bfh $base_text_data;
    close($bfh);
}

# Run with --base-text to generate data.xml
my $zipcontent_btx = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', '--base-text', $btx_file ],
    { stdout => \$zipcontent_btx },
    "conllu2korapxml accepts --base-text option"
);

my $zipfile_btx = "$test_tempdir/test_base_text.zip";
if ($zipcontent_btx) {
    open(my $zfh, '>:raw', $zipfile_btx) or die "Cannot write zip: $!";
    print $zfh $zipcontent_btx;
    close($zfh);

    my $ziplist = `$UNZIP -l $zipfile_btx 2>/dev/null`;
    like($ziplist,
        qr@TEST/TEST/TEST_BTX_001/data\.xml@,
        "Zip contains data.xml at correct path");

    my $data_xml = `$UNZIP -p $zipfile_btx 'TEST/TEST/TEST_BTX_001/data.xml' 2>/dev/null`;

    like($data_xml,
        qr/docid="TEST_TEST\.TEST_BTX_001"/,
        "data.xml has correct docid attribute");

    like($data_xml,
        qr/<raw_text\b/,
        "data.xml contains <raw_text> element");

    like($data_xml,
        qr{<text>Geras rytas\. Kaip sekasi\?</text>},
        "data.xml text is sentences joined by single space");

    like($data_xml,
        qr/xmlns="http:\/\/ids-mannheim\.de\/ns\/KorAP"/,
        "data.xml has correct namespace");

    like($data_xml,
        qr/<\?xml-model href="text\.rng"/,
        "data.xml has correct processing instruction");
}
else {
    fail("Zip contains data.xml at correct path");
    fail("data.xml has correct docid attribute");
    fail("data.xml contains <raw_text> element");
    fail("data.xml text is sentences joined by single space");
    fail("data.xml has correct namespace");
    fail("data.xml has correct processing instruction");
}

# Run WITHOUT --base-text to verify data.xml is NOT generated
my $zipcontent_no_btx = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $btx_file ],
    { stdout => \$zipcontent_no_btx },
    "conllu2korapxml runs without --base-text"
);

my $zipfile_no_btx = "$test_tempdir/test_no_base_text.zip";
if ($zipcontent_no_btx) {
    open(my $zfh, '>:raw', $zipfile_no_btx) or die "Cannot write zip: $!";
    print $zfh $zipcontent_no_btx;
    close($zfh);

    my $ziplist_no = `$UNZIP -l $zipfile_no_btx 2>/dev/null`;
    unlike($ziplist_no,
        qr/data\.xml/,
        "Zip does NOT contain data.xml when --base-text is omitted");
}
else {
    fail("Zip does NOT contain data.xml when --base-text is omitted");
}

# Test XML escaping: text containing &, <, > characters
my $escape_data = <<'CONLLU';
# filename = TEST/TEST/TEST_ESC_001/base/tokens.xml
# text_id = TEST_TEST.TEST_ESC_001
# text = A & B < C > D
# start_offsets = 0 0 2 4 6 8 10 12
# end_offsets = 13 1 3 5 7 9 11 13
1	A	a	NOUN	n.	_	0	root	_	_
2	&	&	PUNCT	p.	_	1	punct	_	_
3	B	b	NOUN	n.	_	1	conj	_	_
4	<	<	PUNCT	p.	_	3	punct	_	_
5	C	c	NOUN	n.	_	1	conj	_	_
6	>	>	PUNCT	p.	_	5	punct	_	_
7	D	d	NOUN	n.	_	1	conj	_	_

CONLLU

my $esc_file = "$test_tempdir/test_escape.conllu";
{
    open(my $efh, '>:encoding(UTF-8)', $esc_file)
        or die "Cannot write test file: $!";
    print $efh $escape_data;
    close($efh);
}

my $zipcontent_esc = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', '--base-text', $esc_file ],
    { stdout => \$zipcontent_esc },
    "conllu2korapxml handles XML special chars in text"
);

my $zipfile_esc = "$test_tempdir/test_escape.zip";
if ($zipcontent_esc) {
    open(my $zfh, '>:raw', $zipfile_esc) or die "Cannot write zip: $!";
    print $zfh $zipcontent_esc;
    close($zfh);

    my $data_esc = `$UNZIP -p $zipfile_esc 'TEST/TEST/TEST_ESC_001/data.xml' 2>/dev/null`;
    like($data_esc,
        qr{<text>A &amp; B &lt; C &gt; D</text>},
        "data.xml escapes &, <, > in full text string");
}
else {
    fail("data.xml escapes &, <, > in full text string");
}

# Test single-sentence document (no joining needed)
my $single_sent_data = <<'CONLLU';
# filename = TEST/TEST/TEST_SST_001/base/tokens.xml
# text_id = TEST_TEST.TEST_SST_001
# text = Hello world
# start_offsets = 0 0 6
# end_offsets = 11 5 11
1	Hello	hello	INTJ	intj.	_	0	root	_	_
2	world	world	NOUN	n.	_	1	flat	_	_

CONLLU

my $sst_file = "$test_tempdir/test_single_sent.conllu";
{
    open(my $sfh, '>:encoding(UTF-8)', $sst_file)
        or die "Cannot write test file: $!";
    print $sfh $single_sent_data;
    close($sfh);
}

my $zipcontent_sst = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', '--base-text', $sst_file ],
    { stdout => \$zipcontent_sst },
    "conllu2korapxml generates data.xml for single-sentence document"
);

my $zipfile_sst = "$test_tempdir/test_single_sent.zip";
if ($zipcontent_sst) {
    open(my $zfh, '>:raw', $zipfile_sst) or die "Cannot write zip: $!";
    print $zfh $zipcontent_sst;
    close($zfh);

    my $data_sst = `$UNZIP -p $zipfile_sst 'TEST/TEST/TEST_SST_001/data.xml' 2>/dev/null`;
    like($data_sst,
        qr{<text>Hello world</text>},
        "data.xml single sentence: text matches exactly");
}
else {
    fail("data.xml single sentence: text matches exactly");
}

# Test: --base-tokens produces base/tokens.xml
my $zipcontent_tok = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', '--base-tokens', $btx_file ],
    { stdout => \$zipcontent_tok },
    "conllu2korapxml runs with --base-tokens"
);

my $zipfile_tok = "$test_tempdir/test_tokens.zip";
if ($zipcontent_tok) {
    open(my $zfh, '>:raw', $zipfile_tok) or die "Cannot write zip: $!";
    print $zfh $zipcontent_tok;
    close($zfh);

    my $ziplist = `$UNZIP -l $zipfile_tok 2>/dev/null`;
    like($ziplist,
        qr@TEST/TEST/TEST_BTX_001/base/tokens\.xml@,
        "Zip contains base/tokens.xml at correct path");

    my $tokens_xml = `$UNZIP -p $zipfile_tok 'TEST/TEST/TEST_BTX_001/base/tokens.xml' 2>/dev/null`;

    like($tokens_xml,
        qr/docid="TEST_TEST\.TEST_BTX_001"/,
        "tokens.xml has correct docid attribute");

    like($tokens_xml,
        qr/xmlns="http:\/\/ids-mannheim\.de\/ns\/KorAP"/,
        "tokens.xml has correct namespace");

    like($tokens_xml,
        qr/<\?xml-model href="span\.rng"/,
        "tokens.xml has correct processing instruction");

    like($tokens_xml,
        qr/version="KorAP-0\.4"/,
        "tokens.xml has correct version");

    # Token spans with sequential IDs and correct offsets
    # Sentence 1: Geras(0..5) rytas(6..11) .(11..12)
    like($tokens_xml,
        qr/<span id="t_0" from="0" to="5"\/>/,
        "Token t_0: Geras from=0 to=5");

    like($tokens_xml,
        qr/<span id="t_1" from="6" to="11"\/>/,
        "Token t_1: rytas from=6 to=11");

    like($tokens_xml,
        qr/<span id="t_2" from="11" to="12"\/>/,
        "Token t_2: period from=11 to=12");

    # Sentence 2: Kaip(13..17) sekasi(18..24) ?(24..25)
    like($tokens_xml,
        qr/<span id="t_3" from="13" to="17"\/>/,
        "Token t_3: Kaip from=13 to=17");

    like($tokens_xml,
        qr/<span id="t_4" from="18" to="24"\/>/,
        "Token t_4: sekasi from=18 to=24");

    like($tokens_xml,
        qr/<span id="t_5" from="24" to="25"\/>/,
        "Token t_5: question mark from=24 to=25");

    # Self-closing span elements (no child fs element)
    unlike($tokens_xml,
        qr/<span id="t_0"[^\/]*>.*?<\/span>/s,
        "Token spans are self-closing (no child elements)");
}
else {
    fail("Zip contains base/tokens.xml at correct path");
    fail("tokens.xml has correct docid attribute");
    fail("tokens.xml has correct namespace");
    fail("tokens.xml has correct processing instruction");
    fail("tokens.xml has correct version");
    fail("Token t_0: Geras from=0 to=5");
    fail("Token t_1: rytas from=6 to=11");
    fail("Token t_2: period from=11 to=12");
    fail("Token t_3: Kaip from=13 to=17");
    fail("Token t_4: sekasi from=18 to=24");
    fail("Token t_5: question mark from=24 to=25");
    fail("Token spans are self-closing (no child elements)");
}

# Test: without --base-tokens, no base/tokens.xml is produced
my $zipcontent_notok = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $btx_file ],
    { stdout => \$zipcontent_notok },
    "conllu2korapxml runs without --base-tokens"
);

my $zipfile_notok = "$test_tempdir/test_notokens.zip";
if ($zipcontent_notok) {
    open(my $zfh, '>:raw', $zipfile_notok) or die "Cannot write zip: $!";
    print $zfh $zipcontent_notok;
    close($zfh);

    my $ziplist_notok = `$UNZIP -l $zipfile_notok 2>/dev/null`;
    unlike($ziplist_notok,
        qr/base\/tokens\.xml/,
        "Zip does NOT contain base/tokens.xml when --base-tokens omitted");
}
else {
    fail("Zip does NOT contain base/tokens.xml when --base-tokens omitted");
}

my $misc_file = "$test_tempdir/test_misc.conllu";
{
    open(my $mfh, '>:encoding(UTF-8)', $misc_file)
        or die "Cannot write test file: $!";
    print $mfh $misc_data;
    close($mfh);
}

my $zipcontent_misc = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $misc_file ],
    { stdout => \$zipcontent_misc },
    "conllu2korapxml runs with MISC column data"
);

my $zipfile_misc = "$test_tempdir/test_misc.zip";
if ($zipcontent_misc) {
    open(my $zfh, '>:raw', $zipfile_misc) or die "Cannot write zip: $!";
    print $zfh $zipcontent_misc;
    close($zfh);

    my $morpho_xml = `$UNZIP -p $zipfile_misc 'TEST/TEST/TEST_MISC_001/ud/morpho.xml' 2>/dev/null`;

    # SpaceAfter=No|Tag=NNN -> only Tag=NNN kept
    like($morpho_xml,
        qr/<f name="misc">Tag=NNN<\/f>/,
        "MISC: SpaceAfter=No filtered, Tag=NNN kept");

    unlike($morpho_xml,
        qr/<f name="misc">SpaceAfter=No\|Tag=NNN<\/f>/,
        "MISC: raw SpaceAfter=No|Tag not stored verbatim");

    # Pure Tag=LLL (no SpaceAfter) -> preserved unchanged
    like($morpho_xml,
        qr/<f name="misc">Tag=LLL<\/f>/,
        "MISC: pure non-SpaceAfter value preserved unchanged");

    # SpaceAfter=No alone -> no misc element at all
    my ($s1_n3_block) = $morpho_xml =~ /(id="s1_n3".*?<\/span>)/s;
    ok(defined $s1_n3_block, "Found span block for s1_n3");
    unlike($s1_n3_block // '',
        qr/<f name="misc">/,
        "MISC: SpaceAfter=No alone produces no misc element");
    unlike($s1_n3_block // '',
        qr/<f name="certainty">/,
        "MISC: SpaceAfter=No alone produces no certainty element");

    # SpacesAfter=\n|Tag=MMM -> only Tag=MMM kept
    like($morpho_xml,
        qr/<f name="misc">Tag=MMM<\/f>/,
        "MISC: SpacesAfter filtered, Tag=MMM kept");

    unlike($morpho_xml,
        qr/SpacesAfter/,
        "MISC: no SpacesAfter value appears in output");

    unlike($morpho_xml,
        qr/SpaceAfter/,
        "MISC: no SpaceAfter value appears in output at all");
}
else {
    fail("MISC: SpaceAfter=No filtered, Tag=NNN kept");
    fail("MISC: raw SpaceAfter=No|Tag not stored verbatim");
    fail("MISC: pure non-SpaceAfter value preserved unchanged");
    fail("Found span block for s1_n3");
    fail("MISC: SpaceAfter=No alone produces no misc element");
    fail("MISC: SpaceAfter=No alone produces no certainty element");
    fail("MISC: SpacesAfter filtered, Tag=MMM kept");
    fail("MISC: no SpacesAfter value appears in output");
    fail("MISC: no SpaceAfter value appears in output at all");
}

my $struct_file = "$test_tempdir/test_struct.conllu";
{
    open(my $sfh, '>:encoding(UTF-8)', $struct_file)
        or die "Cannot write test file: $!";
    print $sfh $struct_data;
    close($sfh);
}

my $zipcontent_str = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $struct_file ],
    { stdout => \$zipcontent_str },
    "conllu2korapxml generates struct.xml when sent_id present"
);

my $zipfile_str = "$test_tempdir/test_struct.zip";
if ($zipcontent_str) {
    open(my $zfh, '>:raw', $zipfile_str) or die "Cannot write zip: $!";
    print $zfh $zipcontent_str;
    close($zfh);

    my $ziplist = `$UNZIP -l $zipfile_str 2>/dev/null`;
    like($ziplist,
        qr@TEST/TEST/TEST_STR_001/base/struct\.xml@,
        "Zip contains struct.xml at correct path");

    my $struct_xml = `$UNZIP -p $zipfile_str 'TEST/TEST/TEST_STR_001/base/struct.xml' 2>/dev/null`;

    like($struct_xml,
        qr/docid="TEST_TEST\.TEST_STR_001"/,
        "struct.xml has correct docid attribute");

    like($struct_xml,
        qr/xmlns="http:\/\/ids-mannheim\.de\/ns\/KorAP"/,
        "struct.xml has correct namespace");

    like($struct_xml,
        qr/<\?xml-model href="span\.rng"/,
        "struct.xml has correct processing instruction");

    # Sentence spans: s1 (0..12), s2 (12..25), s3 (25..39)
    like($struct_xml,
        qr/id="s1" from="0" to="12".*?<f name="name">s<\/f>/s,
        "Sentence span s1: from=0 to=12");

    like($struct_xml,
        qr/id="s2" from="12" to="25".*?<f name="name">s<\/f>/s,
        "Sentence span s2: from=12 to=25");

    like($struct_xml,
        qr/id="s3" from="25" to="39".*?<f name="name">s<\/f>/s,
        "Sentence span s3: from=25 to=39");

    # Paragraph spans: p1 (0..25), p2 (25..39)
    like($struct_xml,
        qr/id="p1" from="0" to="25".*?<f name="name">p<\/f>/s,
        "Paragraph span p1: from=0 to=25");

    like($struct_xml,
        qr/id="p2" from="25" to="39".*?<f name="name">p<\/f>/s,
        "Paragraph span p2: from=25 to=39");

    # All struct spans use the TEI namespace
    like($struct_xml,
        qr/<fs type="struct" xmlns="http:\/\/www\.tei-c\.org\/ns\/1\.0">/,
        "Struct spans use TEI namespace");

    # Spans are sorted by from ascending, then to ascending (mixed s and p)
    my @span_order;
    while ($struct_xml =~ /id="([sp]\d+)" from="(\d+)" to="(\d+)"/g) {
        push @span_order, [$1, $2, $3];
    }
    my $sorted_ok = 1;
    for my $j (1 .. $#span_order) {
        if ($span_order[$j]->[1] < $span_order[$j-1]->[1] ||
            ($span_order[$j]->[1] == $span_order[$j-1]->[1] &&
             $span_order[$j]->[2] < $span_order[$j-1]->[2])) {
            $sorted_ok = 0;
            last;
        }
    }
    ok($sorted_ok, "Struct spans are sorted by from then to");
}
else {
    fail("Zip contains struct.xml at correct path");
    fail("struct.xml has correct docid attribute");
    fail("struct.xml has correct namespace");
    fail("struct.xml has correct processing instruction");
    fail("Sentence span s1: from=0 to=12");
    fail("Sentence span s2: from=12 to=25");
    fail("Sentence span s3: from=25 to=39");
    fail("Paragraph span p1: from=0 to=25");
    fail("Paragraph span p2: from=25 to=39");
    fail("Struct spans use TEI namespace");
}

my $sent_only_data = <<'CONLLU';
# filename = TEST/TEST/TEST_SNO_001/base/tokens.xml
# text_id = TEST_TEST.TEST_SNO_001
# sent_id = x1
# start_offsets = 0 0 6
# end_offsets = 11 5 11
1	Hello	hello	INTJ	intj.	_	0	root	_	_
2	world	world	NOUN	n.	_	1	flat	_	_

# sent_id = x2
# start_offsets = 11 12 18
# end_offsets = 23 17 23
1	Good	good	ADJ	adj.	_	2	amod	_	_
2	night	night	NOUN	n.	_	0	root	_	_

CONLLU

my $sno_file = "$test_tempdir/test_sent_only.conllu";
{
    open(my $sfh, '>:encoding(UTF-8)', $sno_file)
        or die "Cannot write test file: $!";
    print $sfh $sent_only_data;
    close($sfh);
}

my $zipcontent_sno = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $sno_file ],
    { stdout => \$zipcontent_sno },
    "conllu2korapxml generates struct.xml with sent_id only (no newpar)"
);

my $zipfile_sno = "$test_tempdir/test_sent_only.zip";
if ($zipcontent_sno) {
    open(my $zfh, '>:raw', $zipfile_sno) or die "Cannot write zip: $!";
    print $zfh $zipcontent_sno;
    close($zfh);

    my $struct_sno = `$UNZIP -p $zipfile_sno 'TEST/TEST/TEST_SNO_001/base/struct.xml' 2>/dev/null`;

    like($struct_sno,
        qr/id="s1" from="0" to="11".*?<f name="name">s<\/f>/s,
        "Sent-only: sentence span s1 from=0 to=11");

    like($struct_sno,
        qr/id="s2" from="11" to="23".*?<f name="name">s<\/f>/s,
        "Sent-only: sentence span s2 from=11 to=23");

    unlike($struct_sno,
        qr/>p<\/f>/,
        "Sent-only: no paragraph spans when newpar absent");
}
else {
    fail("Sent-only: sentence span s1 from=0 to=11");
    fail("Sent-only: sentence span s2 from=11 to=23");
    fail("Sent-only: no paragraph spans when newpar absent");
}

my $no_struct_data = <<'CONLLU';
# filename = TEST/TEST/TEST_NOS_001/base/tokens.xml
# text_id = TEST_TEST.TEST_NOS_001
# start_offsets = 0 0 4
# end_offsets = 7 3 7
1	foo	foo	NOUN	n.	_	0	root	_	_
2	bar	bar	NOUN	n.	_	1	flat	_	_

CONLLU

my $nos_file = "$test_tempdir/test_no_struct.conllu";
{
    open(my $nfh, '>:encoding(UTF-8)', $nos_file)
        or die "Cannot write test file: $!";
    print $nfh $no_struct_data;
    close($nfh);
}

my $zipcontent_nos = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $nos_file ],
    { stdout => \$zipcontent_nos },
    "conllu2korapxml runs without sent_id (no struct.xml)"
);

my $zipfile_nos = "$test_tempdir/test_no_struct.zip";
if ($zipcontent_nos) {
    open(my $zfh, '>:raw', $zipfile_nos) or die "Cannot write zip: $!";
    print $zfh $zipcontent_nos;
    close($zfh);

    my $ziplist_nos = `$UNZIP -l $zipfile_nos 2>/dev/null`;
    unlike($ziplist_nos,
        qr/struct\.xml/,
        "Zip does NOT contain struct.xml when sent_id absent");
}
else {
    fail("Zip does NOT contain struct.xml when sent_id absent");
}

my $bare_newpar_data = <<'CONLLU';
# filename = TEST/TEST/TEST_BNP_001/base/tokens.xml
# text_id = TEST_TEST.TEST_BNP_001
# newpar
# sent_id = a1
# start_offsets = 0 0 4
# end_offsets = 7 3 7
1	one	one	NUM	num.	_	0	root	_	_
2	two	two	NUM	num.	_	1	flat	_	_

# newpar
# sent_id = a2
# start_offsets = 7 8 14
# end_offsets = 17 13 17
1	three	three	NUM	num.	_	0	root	_	_
2	four	four	NUM	num.	_	1	flat	_	_

CONLLU

my $bnp_file = "$test_tempdir/test_bare_newpar.conllu";
{
    open(my $bfh, '>:encoding(UTF-8)', $bnp_file)
        or die "Cannot write test file: $!";
    print $bfh $bare_newpar_data;
    close($bfh);
}

my $zipcontent_bnp = '';
script_runs(
    [ 'script/conllu2korapxml', '-f', 'ud', $bnp_file ],
    { stdout => \$zipcontent_bnp },
    "conllu2korapxml handles bare newpar (without id)"
);

my $zipfile_bnp = "$test_tempdir/test_bare_newpar.zip";
if ($zipcontent_bnp) {
    open(my $zfh, '>:raw', $zipfile_bnp) or die "Cannot write zip: $!";
    print $zfh $zipcontent_bnp;
    close($zfh);

    my $struct_bnp = `$UNZIP -p $zipfile_bnp 'TEST/TEST/TEST_BNP_001/base/struct.xml' 2>/dev/null`;

    like($struct_bnp,
        qr/id="p1" from="0" to="7".*?<f name="name">p<\/f>/s,
        "Bare newpar: paragraph p1 from=0 to=7");

    like($struct_bnp,
        qr/id="p2" from="7" to="17".*?<f name="name">p<\/f>/s,
        "Bare newpar: paragraph p2 from=7 to=17");
}
else {
    fail("Bare newpar: paragraph p1 from=0 to=7");
    fail("Bare newpar: paragraph p2 from=7 to=17");
}

done_testing;
