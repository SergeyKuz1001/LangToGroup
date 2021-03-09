module TM2SP where

import TMTypes
import TMReader
import SPTypes
import SPGens
import qualified Set
import qualified Data.Map.Lazy as Map

(===) :: [TMReader Generator] -> [TMReader Generator] -> TMReader Relation
w1 === w2 = Equals <$> sequence w1 <*> sequence w2

relations :: TMReader Relations
relations = do
    n <- getN
    m <- getM
    TM quadruplesMap <- getT
    let quadruples = Map.toList quadruplesMap
    fmap Set.fromList $ sequence $
        ( do
            quadruple <- quadruples
            case quadruple of
                ((Q i, S j), (C (S k), Q l)) ->
                    [[q_ i, s_ j] === [q_ l, s_ k]] ++ (
                        if j == 0
                        then [
                            [q_ i, h_0] === [h_0, q_ l, s_ k],
                            [q_ i, h_1] === [q_ l, s_ k, h_1]
                          ]
                        else []
                    )

                ((Q i, S j), (R,       Q l)) ->
                    [[q_ i, s_ j] === [s_ j, q_ l]] ++ (
                        if j == 0
                        then [
                            [q_ i, h_0] === [h_0, q_ l],
                            [q_ i, h_1] === [s_ 0, q_ l, h_1]
                          ]
                        else []
                    )

                ((Q i, S j), (L,       Q l)) ->
                    [[s_ beta, q_ i, s_ j] === [q_ l, s_ beta, s_ j] | beta <- [0..m]] ++ (
                        if j == 0
                        then
                            [[q_ i, h_0] === [q_ l, h_0, s_ 0]] ++
                            [[s_ beta, q_ i, h_1] === [q_ l, s_ beta, h_1] | beta <- [0..m]]
                        else []
                    )
        ) ++
        [[q_ 0, h_0]          === [h_0, q_ 0]] ++
        [[q_ 0, s_ beta]      === [q_ 0]      | beta <- [0..m]] ++
        [[s_ beta, q_ 0, h_1] === [q_ 0, h_1] | beta <- [0..m]]

semigroupGamma :: TuringMachine -> SemigroupPresentation
semigroupGamma = SP . runTMReader relations
