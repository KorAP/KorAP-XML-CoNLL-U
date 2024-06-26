# KorAP-XML-CoNLL-U

Tool package to convert between KorAP XML format and [CoNLL-U format](https://universaldependencies.org/format.html), as
well as other simple formats,including token boundary information.

## Description

The state of the package is very preliminary. Currently, two scripts are provided:

* `korapxml2conllu` converts KorAP XML zip "base" and "morpho" (with POS and lemma annotations) files to corresponding
  CoNLL-U (or word2vec input) files with foundry information, text ids and token offsets in comments
* `conllu2korapxml` converts CoNLL-U files that follow KorAP-specific comment conventions
  and contain morphosyntactic and/or dependency annotations to
  corresponding KorAP-XML zip files

## Installation

### Using cpanm

```bash
cpanm https://github.com/KorAP/KorAP-XML-CoNLL-U.git
```

### Local

```shell script
perl Makefile.PL
make
make test TEST_VERBOSE=1
make install
```

## Command Line Invocation

### `korapxml2conllu`

```

$ korapxml2conllu wpd17.tree_tagger.zip | head -42

# foundry = tree_tagger
# filename = WPD17/A00/00001/tree_tagger/morpho.xml  
# text_id = WPD17_A00.00001
# start_offsets = 0 0 5 13 19 23 33 37 43 52 61 63 67 73 85 87 91 97 101 113 123 130 136 142 146 150 155 158 169 178 184 190
# end_offsets = 191 4 12 18 22 32 36 42 51 61 62 66 72 85 86 90 96 100 112 122 129 135 141 145 149 154 157 168 177 183 190 191
1            Alan         Alan         NE           NE           _            _            _            _            1.000000
2            Smithee      --           NE           NE           _            _            _            _            1.000000
3            steht        stehen       VVFIN        VVFIN        _            _            _            _            1.000000
4            als          als          KOKOM        KOKOM        _            _            _            _            0.995658
5            Pseudonym    Pseudonym    NN           NN           _            _            _            _            1.000000
6            für          für          APPR         APPR         _            _            _            _            1.000000
7            einen        eine         ART          ART          _            _            _            _            0.998238
8            fiktiven     fiktiv       ADJA         ADJA         _            _            _            _            1.000000
9            Regisseur    Regisseur    NN           NN           _            _            _            _            1.000000
10           ,            ,            $,           $,           _            _            _            _            1.000000
11           der          die          ART          ART          _            _            _            _            0.954604
12           Filme        Film         NN           NN           _            _            _            _            1.000000
13           verantwortet verantworten VVPP         VVPP         _            _            _            _            0.753983
14           ,            ,            $,           $,           _            _            _            _            1.000000
15           bei          bei          APPR         APPR         _            _            _            _            0.999325
16           denen        die          PDS          PDS          _            _            _            _            0.906725
17           der          die          ART          ART          _            _            _            _            0.998927
18           eigentliche  eigentlich   ADJA         ADJA         _            _            _            _            1.000000
19           Regisseur    Regisseur    NN           NN           _            _            _            _            1.000000
20           seinen       sein         PPOSAT       PPOSAT       _            _            _            _            1.000000
21           Namen        Name         NN           NN           _            _            _            _            1.000000
22           nicht        nicht        PTKNEG       PTKNEG       _            _            _            _            1.000000
23           mit          mit          APPR         APPR         _            _            _            _            0.999012
24           dem          die          ART          ART          _            _            _            _            0.999949
25           Werk         Werk         NN           NN           _            _            _            _            1.000000
26           in           in           APPR         APPR         _            _            _            _            1.000000
27           Verbindung   Verbindung   NN           NN           _            _            _            _            1.000000
28           gebracht     bringen      VVPP         VVPP         _            _            _            _            0.999331
29           haben        haben        VAINF        VAINF        _            _            _            _            0.999987
30           möchte       mögen        VMFIN        VMFIN        _            _            _            _            1.000000
31           .            .            $.           $.           _            _            _            _            1.000000

# start_offsets = 192 192 196 201 205 210 216 219 223 227 237 243 246 254 255 258 260 264 271 283 292 294 302 306 309 316 319
# end_offsets = 320 195 200 204 209 215 218 222 226 236 242 245 253 255 258 259 263 270 282 292 293 301 305 308 315 319 320
1            Von          von          APPR         APPR         _            _            _            _            0.999214
2            1968         1968         CARD         CARD         _            _            _            _            1.000000
3            bis          bis          APPR         APPR         _            _            _            _            0.861721


$ ./script/korapxml2conllu t/data/goe.zip | head -20
# foundry = base
# filename = GOE/AGA/00000/base/tokens.xml  
# text_id = GOE_AGA.00000
# start_offsets = 0 0 9 12
# end_offsets = 22 8 11 22
1	Campagne	_	_	_	_	_	_	_	_
2	in	_	_	_	_	_	_	_	_
3	Frankreich	_	_	_	_	_	_	_	_

# start_offsets = 23 23
# end_offsets = 27 27
1	1792	_	_	_	_	_	_	_	_

# start_offsets = 28 28 33 37 40 44 53
# end_offsets = 54 32 36 39 43 53 54
1	auch	_	_	_	_	_	_	_	_
2	ich	_	_	_	_	_	_	_	_
3	in	_	_	_	_	_	_	_	_
4	der	_	_	_	_	_	_	_	_
5	Champagne	_	_	_	_	_	_	_	_

```

#### Example producing language model training input from KorAP-XML

```
./script/korapxml2conllu --word2vec t/data/wdf19.zip
```

```
Arts visuels Pourquoi toujours vouloir séparer BD et Manga ?
Ffx 18:20 fév 25 , 2003 ( CET ) soit on ne sépara pas , soit alors on distingue aussi , le comics , le manwa , le manga ..
la bd belge et touts les auteurs européens ..
on commence aussi a parlé de la bd africaine et donc ...
wikipedia ce prete parfaitement à ce genre de decryptage .
…
```

#### Example producing language model training input with preceding metadata columns

```
./script/korapxml2conllu -m '<textSigle>([^<]+)' -m '<creatDate>([^<]+)' --word2vec t/data/wdf19.zip 
```

```
WDF19/A0000.10894	2014.08.28	Arts visuels Pourquoi toujours vouloir séparer BD et Manga ?
WDF19/A0000.10894	2014.08.28	Ffx 18:20 fév 25 , 2003 ( CET ) soit on ne sépara pas , soit alors on distingue aussi , le comics , le manwa , le manga ..
WDF19/A0000.10894	2014.08.28	la bd belge et touts les auteurs européens ..
WDF19/A0000.10894	2014.08.28	on commence aussi a parlé de la bd africaine et donc ...
WDF19/A0000.10894	2014.08.28	wikipedia ce prete parfaitement à ce genre de decryptage .
```

### `conllu2korapxml`

```
./script/conllu2korapxml < t/data/goe.morpho.conllu > goe.morpho.zip
```

## Development and License

**Author**:

* [Marc Kupietz](https://www.ids-mannheim.de/digspra/personal/kupietz.html)

Copyright (c) 2024, [Leibniz Institute for the German Language](http://www.ids-mannheim.de/), Mannheim, Germany

This package is developed as part of the [KorAP](http://korap.ids-mannheim.de/)
Corpus Analysis Platform at the Leibniz Institute for German Language
([IDS](http://www.ids-mannheim.de/)).

It is published under the BSD 2-clause "Simplified" license.

## Contributions

Contributions are very welcome!

Your contributions should ideally be committed via our [Gerrit server](https://korap.ids-mannheim.de/gerrit/)
to facilitate reviewing (
see [Gerrit Code Review - A Quick Introduction](https://korap.ids-mannheim.de/gerrit/Documentation/intro-quick.html)
if you are not familiar with Gerrit). However, we are also happy to accept comments and pull requests
via GitHub.
