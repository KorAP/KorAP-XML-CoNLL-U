# KorAP-XML-CoNLL-U
Tool package to convert between KorAP XML format and [CoNLL-U format](https://universaldependencies.org/format.html) including token boundary information. 

## Description
The status of the package is very prelimanry. Currently, only a script `korapxml2conllu` is provided. It converts KorAP XML zip "morpho" files with POS and lemma annotations to corresponding CoNLL-U files with foundry information, text ids and token offsets in comments.

## Installation
```shell script
$ perl Makefile.PL
$ make install
```
#### Note
Because of the large table of abbreviations, the conversion from the jflex source to java,
i.e. the calculation of the DFA, takes about 4 to 20 minutes, depending on your hardware,
and requires a lot of heap space.

For this reason the java source that is generated from the jflex source is distributed
with the source code and not deleted on `mvn clean`.

If you want to modify the jflex source, while keeping the abbreviation lists,
you will need ad least 5 GB of free RAM.

## Documentation
The KorAP tokenizer reads from standard input and writes to standard output. It supports multiple modes of operations.

With the `--positions` option, for example, the tokenizer prints all offsets of the first character of a token and the first character after a token.
In order to end a text, flush the output and reset the character position, an EOT character (0x04) can be used.
#### Command Line Invocation
```
$ echo -n -e 'This is a text.\x0a\x03\x0aAnd this is another text.\n\x03\n' |\
   java -jar target/KorAP-Tokenizer-1.3-SNAPSHOT.jar --positions

0 4 5 7 8 9 10 15 
0 3 4 8 9 11 12 19 20 25 
```
#### Invocation with Sentence Splitting
```
echo -n -e ' This ist a start of a text. And this is a sentence!!! But what the hack????\x0a\x03\x0aAnd this is another text.\n\x03\nAnd this a sentence without marker\n' |\
   java -jar target/KorAP-Tokenizer-1.3-SNAPSHOT.jar --positions --sentence-boundaries
1 5 6 9 10 11 12 17 18 20 21 22 23 27 27 28 29 32 33 37 38 40 41 42 43 51 51 54 55 58 59 63 64 67 68 72 72 76 
1 28 29 54 55 76
0 3 4 8 9 11 12 19 20 24 24 25 
0 25
```

## Development and License

**Authors**: 
* [Marc Kupietz](https://www1.ids-mannheim.de/digspra/personal/kupietz.html)
* [Nils Diewald](https://www1.ids-mannheim.de/digspra/personal/diewald.html)

Copyright (c) 2020, [Leibniz Institute for the German Language](http://www.ids-mannheim.de/), Mannheim, Germany

This package is developed as part of the [KorAP](http://korap.ids-mannheim.de/)
Corpus Analysis Platform at the Leibniz Institute for German Language
([IDS](http://www.ids-mannheim.de/)).

The package contains code from [Apache Lucene](https://lucene.apache.org/) with modifications by Jim Hall.

It is published under the [Apache 2.0 License](LICENSE).

## Contributions

Contributions are very welcome!

Your contributions should ideally be committed via our [Gerrit server](https://korap.ids-mannheim.de/gerrit/)
to facilitate reviewing (see [Gerrit Code Review - A Quick Introduction](https://korap.ids-mannheim.de/gerrit/Documentation/intro-quick.html)
if you are not familiar with Gerrit). However, we are also happy to accept comments and pull requests
via GitHub.

## References
- Beißwenger, Michael / Bartsch, Sabine / Evert, Stefan / Würzner, Kay-Michael. (2016). EmpiriST 2015: A Shared Task on the Automatic Linguistic Annotation of Computer-Mediated Communication and Web Corpora. 44-56. 10.18653/v1/W16-2606. 
