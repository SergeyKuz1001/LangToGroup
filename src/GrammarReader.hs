{-# LANGUAGE OverloadedStrings #-}

-- |This module represents functionality for reading grammar texts from files and determing their type.
--
-- Depending on the type of grammar, specific algorithm for building a group will be executed.

module GrammarReader (convertGrammar2TM) where

import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Debug

import Data.Text (Text)
import Data.String
import Data.Void
import Data.Functor
import Data.Set (Set)
import qualified Data.Set as Set
import qualified Data.List as List

import System.IO
import System.Environment
import qualified System.Environment as SE

import GrammarType
import CFG2TM

-- |Parser part.
type Parser = Parsec Void Text


-- |Parsers for terminal symbols in given grammar: it might be Epsilon, Nonterminal, Terminal, Conjunction or Negation
pEpsilon :: Parser Symbol
pEpsilon = void ("Eps") >> pure Eps

pNonterminal :: Parser Nonterminal
pNonterminal = Nonterminal
    <$> (
        (++)
        <$> ((++) <$> ((:) <$> upperChar <*> (pure [])) <*> many lowerChar)
        <*> many digitChar
        )

pTerminal :: Parser Terminal
pTerminal = Terminal
    <$> (
        (++)
        <$> some lowerChar
        <*> many digitChar
        )

pConjunction :: Parser Symbol
pConjunction = void ("&") *> pure (O Conjunction)

pNegation :: Parser Symbol
pNegation = void ("!") *> pure (O Negation)

-- |Word part.
-- |Word is chain, generated by grammar. It might be Epsilon (if word is empty), or sequence of 'Terminal' or 'Nonterminal'.
pWord :: Parser [Symbol]
pWord = (++) <$> pword' <*> (pure [])

pword' = some (void " " *> (T <$> pTerminal <|> N <$> pNonterminal))
         <|>
         (:) <$> pEpsilon <*> (pure [])

-- |Parsing relations part.
pRelations :: Parser (Set Relation)
pRelations = do
    firstRelation <- pRelation
    relations <- Set.fromList <$> (many (void ("\n") *> pRelation))
    relations <- pure (Set.insert firstRelation relations)
    return relations

-- |Parser for one relation. Relation is in such form : Nonterminal -> [Symbol],
-- 1) in boolean grammar relation has form
-- Nonterminal -> a_1 & a_2 & .... & a_n & !b_1 & !b_2 & ... &!b_m, m + n >= 1, a_i and b_j - words (see above).
-- 2) in conjunctive grammar relation has form
-- Nonterminal -> a_1 & a_2 & .... & a_n, a_i - word
-- 3) in context-free grammar relation has form
-- Nonterminal -> word
pRelation :: Parser Relation
pRelation = do
     nonterminal <- pNonterminal
     void ("->")
     symbols <-  try (pVeryLongRule) <|> (pPositiveFormula) <|> (pNegativeFormula)
     relation <- Relation <$>  pure (nonterminal, symbols)
     return relation

-- |Consider an Relation Nonterminal -> a_1 & a_2 & .... & a_n & !b_1 & !b_2 & ... &!b_m
-- we will name part 'a_1 & a_2 & .... & a_n' 'positive formula' and '& a_2 & .... & a_n' 'positive conjunction'.
-- Similarly, we will name part '!b_1 & !b_2 & .... & !b_n' 'negative formula' and '& !b_2 & .... & !b_n' 'negative conjunction'.
-- If Relation has positive and negative formula (it is relation of boolean grammar), we will call it very long rule.
--
-- Worth noting that parsing other types of relations is included in parsing very long rule:
-- relation without negative formula is the relation of conjunctive grammar,
-- relation without negative or positive formula (with only one word) is the relation of context-free grammar.
pVeryLongRule :: Parser [Symbol]
pVeryLongRule = do
    symbols <- pWord
    symbols <- (++) <$> pure symbols <*> concat <$> (many (try pPositiveConjunction))
    symbols <- (++) <$> pure symbols <*> concat <$> many pNegativeConjunction
    return symbols

pNegativeConjunction :: Parser [Symbol]
pNegativeConjunction = do
    symbols1 <- pConjunction
    symbols2 <- pNegation
    symbols3 <- pWord
    symbols <- pure ((++) (symbols1 : symbols2 : []) symbols3)
    return symbols

pPositiveConjunction :: Parser [Symbol]
pPositiveConjunction = do
    symbols <- (try pConjunction)
    symbols <- (++) <$> pure (symbols : []) <*> pWord
    return symbols

pPositiveFormula :: Parser [Symbol]
pPositiveFormula = do
    symbols <- pWord
    symbols <- ((++) <$> pure symbols <*> concat <$> many pPositiveConjunction)
    return symbols

pNegativeFormula :: Parser [Symbol]
pNegativeFormula = do
    symbols <- pNegation
    symbols <- (++) <$> pure (symbols : []) <*> pWord
    symbols <- ((++) <$> pure symbols <*> concat <$> many pNegativeConjunction)
    return symbols

-- |Parsers for set of terminals and nonterminals.
pNonterminals :: Parser (Set Nonterminal)
pNonterminals = do
    nonterminals <- Set.fromList <$> ((++) <$> many (void " " *> pNonterminal) <*> (pure []))
    return nonterminals

pTerminals :: Parser (Set Terminal)
pTerminals = do
    terminals <- Set.fromList <$> ((++) <$> many (void " " *> pTerminal) <*> (pure []))
    return terminals

-- |Parser for whole Grammar.
-- |Order of grammar components in input is:
-- |{Start symbol};{Set of nonterminals};{Set of terminals};{Relations}
pGrammar :: Parser Grammar
pGrammar = do
    startSymbol <- pNonterminal
    void (";")
    nonterminals <- pNonterminals
    void (";")
    terminals <- pTerminals
    void ("\n")
    relations <- pRelations
    grammar <- Grammar <$> pure (nonterminals, terminals, relations, startSymbol)
    return grammar

-- |Method for classifying type of input grammar.
checkGrammarType :: Grammar -> GrammarType
checkGrammarType (Grammar (_, _, setOfRelations, _)) =
    checkGrammarType' $ (concat . map (\ (Relation (_, symbols)) -> symbols) . Set.toList) setOfRelations

checkGrammarType' :: [Symbol] -> GrammarType
checkGrammarType' symbols
    | (List.elem (O Conjunction) symbols) && (List.elem (O Negation) symbols) = Boolean
    | (List.elem (O Conjunction) symbols) && not (List.elem (O Negation) symbols) = Conjunctive
    | not (List.elem (O Conjunction) symbols) && not (List.elem (O Negation) symbols) = CFG

parseFromFile p errorFileName grammarFileName = runParser p errorFileName <$> ((fromString) <$> readFile grammarFileName)

--temporary added deriving show to all types in GrammarType module
convertGrammar2TM :: String -> String -> IO ()
convertGrammar2TM grammarFile errorFile = do
    result <- (parseFromFile (pGrammar <* eof) errorFile grammarFile)
    case result of
      Left err -> hPutStrLn stderr $ "Error: " ++ show err
      Right cs -> case (checkGrammarType cs) of
          Boolean -> putStrLn ("Boolean " ++ show cs) -- here will be new algorithm
          Conjunctive -> putStrLn ("Conjunctive " ++ show cs)
          CFG -> putStrLn ("CFG " ++ show cs ++ "\n" ++ show (cfg2tm cs))


-- |Valid examples of input
-- 1) context-free grammar
-- S; S A D1; c2 b e
-- S-> c2 D1 A
-- A-> b
-- D1-> e
-- where 'S' - start symbol, 'S A D1' - set of nonterminals, 'c2 b e' - set of terminals,
-- S-> c2 D1 A, A-> b, D1-> e' - relations.
-- Another valid example: 'S; S B; a b
-- S-> a B
-- B-> b
-- 2) conjunctive grammar
-- S; S Abc D Cr; c b d e
-- S-> D c& d Abc
-- Abc-> b
-- D-> Cr
-- Cr-> e
-- where 'S' - start symbol, 'S Abc D Cr' - set of nonterminals, 'c b d e' - set of terminals,
-- S-> D c& d Abc, Abc-> b, D-> Cr, Cr-> e' - relations.
-- 3) boolean grammar
-- S; S Sa; c v b
-- S-> c_&! v&! Sa&! Eps
-- Sa->! b
-- where 'S' - start symbol, 'S 'Sa - set of nonterminals, 'c v b' - set of terminals,
-- 'S-> c_&! v&! Sa&! Eps;Sa->! b' - relation, '_' - separator, that marks the end of positive formula.
-- Another valid examples for boolean grammar:
-- 1)
-- S; S; c v b
-- S->! c&! v&! b&! Eps
-- 2)
-- S; S Sa; c v b
-- S-> c_&! v&! Sa&! Eps
-- Sa->! b'