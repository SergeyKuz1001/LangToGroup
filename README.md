# LangToGroup
Implementation of [Isoperimetric and Isodiametric Functions of Groups](https://arxiv.org/abs/math/9811105) in Haskell.

Implementation algorithm building the presentation of the group for a formal language with the preservation of the language. The implementation of this algorithm is necessary for research in the field of formal languages with the involvement of the group-theoretical methods. At present, there are only theoretical works showing the possibility of such construction, however, the algorithm and its implementation are absent up to this point. As far as we know, this implementation is the first in its area.  

## Build status
[![Build Status](https://travis-ci.org/YaccConstructor/LangToGroup.svg?branch=master)](https://travis-ci.org/YaccConstructor/LangToGroup)

## Building 
To build run:

``stack build``

## Testing
For run the tests:

``stack test``

## Running experiments
For run experiments and print its numerical results you can use ``is_det <bool>`` flag.

So, for print experiments' results using deterministic symmetrization:

``stack exec -- LangToGroup-printer --is_det true``

using nondeterministic symmetrization:

``stack exec -- LangToGroup-printer --is_det false``

## Printing example transformations in LaTeX
Grammar's transformations also can be printed in LaTeX. For this should be used ``--print_example <grammar>`` flag.
The following grammars can be used as print examples: "one\" --- one rule grammar, \"a*\" --- grammar for regular language 
<img src="https://render.githubusercontent.com/render/math?math=L = \{a*\}">
, \"dyck\" --- Dyck language grammar. 

For example,

``stack exec -- LangToGroup-printer --is_det true --print_example one``

Output filename can be specified by ``-o <filename>`` flag.

## Printing example group presentation in Gap-format file
For this you can use ``-G`` flag without a parameter, but with ``--is_det <bool>`` and ``--print_example <grammar>`` flags.
Also, output filename can be specified by ``-o <filename>`` flag, if it does not speccified it been printing with default filename "out.txt".

For example, following prints in "out.txt" a group presentation, which obtained from Dyck language grammar using nondeterministic symmetrization: 

``stack exec -- LangToGroup-printer -G --is_det false --print_example dyck``

## Printing a Turing machine from a custom grammar file
For this you should use ``-i <filepath>`` flag for configuring full path to input file with grammar and ``-o <filepath>`` for configuring full path to output file for storing possible errors.
So, for printing turing machine from given custom grammar file:

``stack exec -- stack exec -- LangToGroup-user -i <filepath> -o <filepath>``

Examples of grammar files given below.

**Boolean grammar**

    S; S Sa; c v b
    S-> c&! v&! Sa&! Eps
    Sa->! b
    S-> a& b&! v&! Sa&! Eps
**Conjunctive grammar**

    S; S Abc D Cr; c b d e
    S-> D c& d Abc
    Abc-> b
    D-> Cr
    Cr-> e
**Context-free grammar**

    S; S A D1; c2 b e
    S-> c2 D1 A
    A-> b
    D1-> e