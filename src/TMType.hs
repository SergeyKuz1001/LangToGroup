module TMType where

import Data.Set (Set)

-- input, tape alphabets
newtype InputAlphabet = InputAlphabet (Set Square)
    deriving (Eq, Ord, Show)
newtype TapeAlphabet = TapeAlphabet (Set Square)
    deriving (Eq, Ord, Show)
-- state of TM
newtype State = State String
    deriving (Eq, Ord, Show)
-- k - vector of tapes states
newtype MultiTapeStates = MultiTapeStates [Set State]
    deriving (Eq, Ord, Show)
-- k - vector of start states
newtype StartStates = StartStates [State]
    deriving (Eq, Ord, Show)
-- k - vector of end states
newtype AccessStates = AccessStates [State]
    deriving (Eq, Ord, Show)

newtype StateOmega = StateOmega {state :: State}
    deriving (Eq, Ord)
instance Show StateOmega where
    show s = "F_{" ++ q ++ "}" 
        where (State q) = state s
-- command of TM for single tape
data TapeCommand = SingleTapeCommand ((Square, State, Square), (Square, State, Square)) | PreSMCommand ((Square, StateOmega), (Square, StateOmega))
    deriving (Eq, Ord, Show)

data Square = Value {val_name :: String, val_quote_cnt :: Int} | E Int | RBS | LBS | ES | PCommand [TapeCommand] | BCommand [TapeCommand]
    deriving (Eq, Ord, Show)

defValue :: String -> Square
defValue s = Value s 0 

-- commands
newtype Commands = Commands (Set [TapeCommand])
    deriving (Eq, Ord, Show)

-- TM
newtype TM = TM (InputAlphabet, [TapeAlphabet], MultiTapeStates, Commands, StartStates, AccessStates)
    deriving (Eq, Ord, Show)