{-# LANGUAGE LambdaCase #-}

module GPGens where

import SPReader
import SPGens (toString)
import qualified SPTypes as SP
import GPTypes
import Control.Monad ((>=>), (=<<))

element :: Int -> Element
element = Positive . G

neg :: Element -> Element
neg (Positive g) = Negative g
neg (Negative g) = Positive g

(^~) :: SPReader Element -> SPReader Element
(^~) = fmap neg

q_ :: Int -> SPReader Element
q_ x = return $ element x

h_0 :: SPReader Element
h_0 = do
    n <- getN
    return $ element (n + 1)

h_1 :: SPReader Element
h_1 = do
    n <- getN
    return $ element (n + 2)

s_ :: Int -> SPReader Element
s_ i = do
    n <- getN
    return $ element (i + n + 3)

r_ :: Int -> SPReader Element
r_ i = do
    n <- getN
    m <- getM
    return $ element (i + n + m + 3)

x :: SPReader Element
x = do
    n <- getN
    m <- getM
    l <- getL
    return $ element (n + m + l + 4)

t :: SPReader Element
t = do
    n <- getN
    m <- getM
    l <- getL
    return $ element (n + m + l + 5)

k :: SPReader Element
k = do
    n <- getN
    m <- getM
    l <- getL
    return $ element (n + m + l + 6)

convertG :: SP.Generator -> SPReader Element
convertG = (fromTMReader . toString) >=> fromString where
    fromString :: String -> SPReader Element
    fromString = \case
        'q':'_':num -> q_ (read num)
        "h_0"       -> h_0
        "h_1"       -> h_1
        's':'_':num -> s_ (read num)
        other       -> error $ show other ++ " isn't valid generator"

convertW :: SP.GWord -> SPReader EWord
convertW = sequence . map convertG
