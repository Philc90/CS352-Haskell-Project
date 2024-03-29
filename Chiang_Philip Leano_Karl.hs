import Parser
import Data.List

{-
CS352 Spring 2017
This project is due Friday June 9th at MIDNIGHT. There will be no extension!!
Teams of up to 3 students can work on this project. In this case only 1 file must be
submitted for all 3 students; the name of all the students in the team must appear
in the file name.
MAKE SURE THE NAME OF THE FILE YOU SUBMIT FOLLOWS THE USUAL CONVENTION:
LastName1_FirstName1 LastName2_FirstName2 LastName3_FirstName3.hs

-}

{-
The purpose of this project is to implement a tautology checker in ternary logic.
This project is composed of 3 largely independent parts and a 4th part that brings
it all together:
1)    Implementation of the operators of ternary logic in Haksell
2)    Implementation of an evaluator of ternary logic expression trees
3)    Implementation of a parser for ternary logic expressions returning expression trees
4)    Implementation of the tautology checker

Parts 1 and 2 are the same as the homework #3, with the exception that variables
have been added to the TExpTree and the evaluator. The code for those 2 parts is
included below.
The rest of this file contains the skeleton of the solution. Most data definitions
and some of the functions are already coded for you. You will have to code all the
functions marked TODO. At the end of each section are a few functions whose name
starts with the word test. These functions will test your implementation.

Feel free to execute them, they take no argument and return True if the test passes.
Add your implementation in the places indicated by the words TODO. You can also add
helper functions if yout so desire, but DO NOT make any other changes to the file. In
particular do not elminate any of the comments and most importantly DO NOT make any
change the code of the test functions.
Points will be taken away for tampering with those functions.

Don't forget to define the type for all the functions you code!!!
-}

{-
Ternary logic:
We’ll use the constructors T, F and M for True, False and Maybe

The basic operation of ternary logic are not, and, or, equivalence and implication
with the truth table below. To avoid conflict with the Bool implementation of Haskell
we'll use the following names:
n't for not
&&& for and
||| to or
<=> for equivalence
==> for implication

Truth Table:
x    y    n't x    x <=> y     x ||| y     x &&& Y     x ==> Y
T    F     F         F           T           F           F
T    T               T           T           T           T
T    M               M           T           M           M
F    F     T         T           F           F           T
F    T               F           T           F           T
F    M               M           M           F           T
M    F     M         M           M           F           M
M    T               M           T           M           T
M    M               T           M           M           T
-}

-- P A R T 1   T E R N A R Y   L O G I C

-- We use Ternary for the datatype, with the constructor T F and M
data Ternary = T | F | M
    deriving (Eq,  Show, Ord)

--Implement the n't (not) function
n't :: Ternary -> Ternary
n't T = F
n't F = T
n't M = M

-- The equivalence operator has the lowest precedence infix:
infix 1 <=>
--Implement the infix operator <=> (equivalence)
(<=>) :: Ternary -> Ternary -> Ternary
T <=> T = T
F <=> F = T
M <=> M = T
T <=> F = F
F <=> T = F
_ <=> _ = M

-- The implication operator has the same precedence as equivalence
infix 1 ==>
--Implement the infix operator ==> (implication)
T ==> F = F
T ==> M = M
M ==> F = M
_ ==> _ = T

-- The Or operator is just above equivalence in precedence
infix 2 |||
--Implement the infix operator ||| (Or)
(|||) :: Ternary -> Ternary -> Ternary
T ||| _ = T
_ ||| T = T
F ||| F = F
_ ||| _ = M


-- The And operator is just above Or in precedence
infix 3 &&&
--Implement the infix operator &&& (And)
(&&&) :: Ternary -> Ternary -> Ternary
F &&& _ = F
_ &&& F = F
T &&& T = T
_ &&& _ = M

-- This completes part 1. You can use the following functions to test the implementation
testNot :: Bool
testNot = (n't T == F) && (n't F == T) && (n't M == M)

testEquiv :: Bool
testEquiv = ((T <=> F) == F)
         && ((T <=> T) == T)
         && ((T <=> M) == M)
         && ((F <=> F) == T)
         && ((F <=> T) == F)
         && ((F <=> M) == M)
         && ((M <=> F) == M)
         && ((M <=> T) == M)
         && ((M <=> M) == T)

testImply :: Bool
testImply = ((T ==> F) == F)
         && ((T ==> T) == T)
         && ((T ==> M) == M)
         && ((F ==> F) == T)
         && ((F ==> T) == T)
         && ((F ==> M) == T)
         && ((M ==> F) == M)
         && ((M ==> T) == T)
         && ((M ==> M) == T)

testOr :: Bool
testOr = ((T ||| F) == T)
      && ((T ||| T) == T)
      && ((T ||| M) == T)
      && ((F ||| F) == F)
      && ((F ||| T) == T)
      && ((F ||| M) == M)
      && ((M ||| F) == M)
      && ((M ||| T) == T)
      && ((M ||| M) == M)

testAnd :: Bool
testAnd = ((T &&& F) == F)
        && ((T &&& T) == T)
        && ((T &&& M) == M)
        && ((F &&& F) == F)
        && ((F &&& T) == F)
        && ((F &&& M) == F)
        && ((M &&& F) == F)
        && ((M &&& T) == M)
        && ((M &&& M) == M)

testPart1 = testNot && testEquiv && testImply && testOr && testAnd


-- P A R T 2: Create an evaluator for TExpTree's
{- In order to test tautologies the TExpTree type is enhanced to support variables
The enhanced type TExpTree uses the constructors L, V, N, A, O, E, I
L for Ternary literals (i.e. T, F or M)
V for Variables (string)
N for a node representing the prefix not
A for a node representing the infix And
O for a node representing the infix Or
E for a node representing the infix Equivalence
I for a node representing the infix Implication
It will be convenient to have the new type derive from the classes Show and Eq
-}
data TExpTree = L Ternary              -- Ternary literal (i.e. T, F or M)
              | V String               -- Variable
              | N TExpTree             -- Prefix not
              | A TExpTree TExpTree    -- And node
              | O TExpTree TExpTree    -- Or node
              | E TExpTree TExpTree    -- Equivalence node
              | I TExpTree TExpTree    -- Implication node
    deriving (Show, Eq)

{- To evaluate such a tree we need to use a dictionary to lookup the value assigned
to the variables. The dictionary consists of a list of pairs (String, Value) and is
defined as follows:
-}
type Dict = [(String, Ternary)]

{-The function lk that takes a dictionary and a string and returns
  the value associated with the string in the dictionary.
-}
lk :: Dict -> String -> Ternary
lk d s = head [t | (k, t) <- d, k==s]

{- The function evalT now takes a dictionary and an expression tree
and returns the value of the expression given the value assigned to the variables
in the dictionary.
-}
evalT :: Dict -> TExpTree -> Ternary
evalT d (L x) = x
evalT d (V s) = lk d s
evalT d (N x) = n't (evalT d x)
evalT d (A l r) = (evalT d l) &&& (evalT d r)
evalT d (O l r) = (evalT d l) ||| (evalT d r)
evalT d (E l r) = (evalT d l) <=> (evalT d r)
evalT d (I l r) = (evalT d l) ==> (evalT d r)

-- This completes part 2. The following functions test the implementation

testDict :: Dict
testDict = [("vT", T), ("vF", F), ("vM", M)]

testLk :: Bool
testLk =  ((lk testDict "vT") == T)
       && ((lk testDict "vF") == F)
       && ((lk testDict "vM") == M)

testEvalT :: Bool
testEvalT = evalT testDict (O (V "vT") (O (N (V "vT")) (E (V "vT") (L M)))) == T
          && evalT testDict (O (V "vF") (O (N (V "vF")) (E (V "vF") (L M)))) == T
          && evalT testDict (O (V "vM") (O (N (V "vM")) (E (V "vM") (L M)))) == T
          && evalT testDict (O (V "vM") (N (V "vM"))) == M
          && evalT testDict (A (L F) ( V "vM")) == F
          && evalT testDict (O (V "vT") (O (N (V "vF")) (E (V "vM") (I (L M) (L T))))) == T

testPart2 :: Bool
testPart2 = testLk && testEvalT


-- P A R T 3 : Implementation of a parser for ternary expressions
{-Grammar:

We use the following grammar for the ternary expressions

tExp :: tOpd ( '<=>' tExp | '==>' tExp| e )
tOpd :: tTerm ( '|||' tOpd | e )
tTerm :: tFact ( '&&&' tTerm | e)
tFact :: '~' tPrim | tPrim
tPrim :: tVar | tLit | '('tExp')'
tVar :: lowercase (Alphanumeric)*
tLit :: T | F | M

This is similar to the grammar we've seen in class. Note that the symbol ~ is used for negation.
This is to avoid confusion between the n't being both an identifier and a prefix operator
As in Haskell, identifiers will start with a lowercase letter, followed by any number of letters
and digits. You do not have to allow the single quote characters in identifiers.
-}

{- TODO: Implement a Parser tExp for the grammar above that generates an expression tree.
The type Parser a is defined in the file Parser.hs. You can (and probably should)
make use of the functions in that file. They are the same as those we have seen in class.
Hint: you will need to define a function for each of the rules of the grammar.
It'll be easier to use the test functions if you give your parsers the same name as the non-terminal
they parse.
-}

-- Some helper functions and parsers

-- Turns character to ternary literal
charToTernary :: Char -> Ternary
charToTernary 'T' = T
charToTernary 'F' = F
charToTernary 'M' = M

-- Parser that consumes "<=>"
eqOperator :: Parser ()
eqOperator = do space
                char '<'
                char '='
                char '>'
                return ()

-- Parser that consumes "==>"
impOperator :: Parser ()
impOperator = do space
                 char '='
                 char '='
                 char '>'
                 return ()

-- Parser that consumes "|||"
orOperator :: Parser ()
orOperator = do space
                char '|'
                char '|'
                char '|'
                return ()

-- Parser that consumes "&&&"
andOperator :: Parser ()
andOperator = do space
                 char '&'
                 char '&'
                 char '&'
                 return ()

-- Grammar parsers

-- Parser for tLit rule
-- tLit :: T | F | M
tLit :: Parser TExpTree
tLit = do space
          v <- (char 'T' +++ char 'F' +++ char 'M')
          space
          return (L (charToTernary v))

-- Parser for tVar rule
-- tVar :: lowercase (Alphanumeric)*
tVar :: Parser TExpTree
tVar = do v <- identifier
          return (V v)

-- Parser for tPrim rule
-- tPrim :: tVar | tLit | '('tExp')'
tPrim :: Parser TExpTree
tPrim = do v <- (tLit +++ tVar +++ tPrimHelper)
           return (v)

-- Helper parser for third tPrim rule: reads the parentheses, with tExp in the middle
tPrimHelper :: Parser TExpTree
tPrimHelper = do space
                 char '('
                 v <- tExp
                 char ')'
                 space
                 return v

-- Parser for tExp rule
-- tExp :: tOpd ( '<=>' tExp | '==>' tExp| e )
tExp :: Parser TExpTree
tExp = do space
          v <- tOpd
          space
          (do eqOperator             -- tExp :: tOpd '<=>' tExp
              space
              w <- tExp
              space
              return (E v w)
           +++ (do impOperator       -- tExp :: tOpd '==>' tExp
                   space
                   w <- tExp
                   space
                   return (I v w)
                +++ return v))       -- tExp :: tOpd

-- Parser for tOpd rule
-- tOpd :: tTerm ( '|||' tOpd | e )
tOpd :: Parser TExpTree
tOpd = do space
          v <- tTerm
          space
          (do orOperator             -- tOpd :: tTerm '|||' tOpd
              space
              w <- tOpd
              space
              return (O v w)
           +++ return v)             -- tOpd :: tTerm

-- Parser for tTerm rule
-- tTerm :: tFact ( '&&&' tTerm | e)
tTerm :: Parser TExpTree
tTerm = do space
           v <- tFact
           space
           (do andOperator           -- tTerm :: tFact '&&&' tTerm
               space
               w <- tTerm
               space
               return (A v w)
            +++ return v)            -- tTerm :: tFact

-- Parser for tFact rule
-- tFact :: '~' tPrim | tPrim
tFact = do space
           (do char '~'              -- tFact :: '~' tPrim
               space
               v <- tPrim
               space
               return (N v)
            +++ (do space            -- tFact :: tPrim
                    v <- tPrim
                    space
                    return v))


-- TODO: Implement a function parseT that takes a string as input
-- and returns a ternary logic expression tree (TExpTree)

-- parseT: if it parses with no remaining string, succeed with the TExpTree
--         else, it throws error
parseT :: String -> TExpTree
parseT s = case parse tExp s of
                Just(first, "") -> first
                Just(_, _) -> error "Invalid Expression"
                Nothing -> error "Invalid Expression"

-- This completes part 3. You can use the following functions to test your implementation

testtLit :: Bool
testtLit = lt == (L T) && lf == (L F) && lm == (L M)
           where Just (lt, _) = parse tLit " T "
                 Just (lf, _) = parse tLit " F "
                 Just (lm, _) = parse tLit " M "

testtVar :: Bool
testtVar = id == (V "id") where Just (id, _) = parse tVar " id "

testtPrim :: Bool
testtPrim = lt == (L T) && lf == (L F) && lm == (L M) && pv == (V "id2")  && pe == (L T)
            where Just (lt, "") = parse tPrim " T "
                  Just (lf, "") = parse tPrim " F "
                  Just (lm, "") = parse tPrim " M "
                  Just (pv, "") = parse tPrim " id2 "
                  Just (pe, "") = parse tPrim " ( T ) "

testtFact :: Bool
testtFact = lt == (L T) && lf == (L F) && lm == (L M) && pv == (V "id2")  && pe == (L T)
          && fnt == N (L T) && fnf == N (L F) && fnm == N(L M) && fnv == N(V "id2")  && fnet == N(L T)
            where Just (lt, "") = parse tFact " T "
                  Just (lf, "") = parse tFact " F "
                  Just (lm, "") = parse tFact " M "
                  Just (pv, "") = parse tFact " id2 "
                  Just (pe, "") = parse tFact " ( T ) "
                  Just (fnt, "") = parse tFact "~ T "
                  Just (fnf, "") = parse tFact "~ F "
                  Just (fnm, "") = parse tFact "~ M "
                  Just (fnv, "") = parse tFact "~ id2 "
                  Just (fnet, "") = parse tFact " ~( T ) "

testtTerm :: Bool
testtTerm = lt == (L T) && lf == (L F) && lm == (L M) && pv == (V "id2")  && pe == (L T)
          && fnt == N (L T) && fnf == N (L F) && fnm == N(L M) && fnv == N(V "id2")  && fnet == N(L T)
          && alv == A (L T)(V "var")
            where Just (lt, "") = parse tTerm " T "
                  Just (lf, "") = parse tTerm " F "
                  Just (lm, "") = parse tTerm " M "
                  Just (pv, "") = parse tTerm " id2 "
                  Just (pe, "") = parse tTerm " ( T ) "
                  Just (fnt, "") = parse tTerm "~ T "
                  Just (fnf, "") = parse tTerm "~ F "
                  Just (fnm, "") = parse tTerm "~ M "
                  Just (fnv, "") = parse tTerm "~ id2 "
                  Just (fnet, "") = parse tTerm " ~( T ) "
                  Just (alv, "") = parse tTerm "T &&& var"

testtOpd :: Bool
testtOpd = lt == (L T) && lf == (L F) && lm == (L M) && pv == (V "id2")  && pe == (L T)
          && fnt == N (L T) && fnf == N (L F) && fnm == N(L M) && fnv == N(V "id2")  && fnet == N(L T)
          && alv == A (L T) (V "var") && ovv == O (V "var") (V "var2")
            where Just (lt, "") = parse tExp " T "
                  Just (lf, "") = parse tExp " F "
                  Just (lm, "") = parse tExp " M "
                  Just (pv, "") = parse tExp " id2 "
                  Just (pe, "") = parse tExp " ( T ) "
                  Just (fnt, "") = parse tExp "~ T "
                  Just (fnf, "") = parse tExp "~ F "
                  Just (fnm, "") = parse tExp "~ M "
                  Just (fnv, "") = parse tExp "~ id2 "
                  Just (fnet, "") = parse tExp " ~( T ) "
                  Just (alv, "") = parse tExp "T &&& var"
                  Just (ovv, "") = parse tExp "var ||| var2"

testtExp :: Bool
testtExp = lt == (L T) && lf == (L F) && lm == (L M) && pv == (V "id2")  && pe == (L T)
          && fnt == N (L T) && fnf == N (L F) && fnm == N(L M) && fnv == N(V "id2")  && fnet == N(L T)
          && alv == A (L T) (V "var") && ovv == O (V "var") (V "var2")
          && ce == O (V "v") (O (N (V "v")) (E (V "v") (I (L M) (L T))))
            where Just (lt, "") = parse tExp " T "
                  Just (lf, "") = parse tExp " F "
                  Just (lm, "") = parse tExp " M "
                  Just (pv, "") = parse tExp " id2 "
                  Just (pe, "") = parse tExp " ( T ) "
                  Just (fnt, "") = parse tExp "~ T "
                  Just (fnf, "") = parse tExp "~ F "
                  Just (fnm, "") = parse tExp "~ M "
                  Just (fnv, "") = parse tExp "~ id2 "
                  Just (fnet, "") = parse tExp " ~( T ) "
                  Just (alv, "") = parse tExp "T &&& var"
                  Just (ovv, "") = parse tExp "var ||| var2"
                  Just (vel, "") = parse tExp "v<=>M"
                  Just (liv, "") = parse tExp "T ==> q"
                  Just (ce, "") = parse tExp "v ||| ~v ||| (v<=>M==>T)"

testPart3 :: Bool
testPart3 = testtLit && testtVar && testtPrim && testtFact && testtTerm && testtOpd && testtExp


-- P A R T 4: Tautology Prover
{- An expression is a tautology if it evaluates to T (True) regardless of the value assigned to
the variables it contains. The strategy we'll employ is to evaluate the expression under all
possible combination of value of the variables and ensure the result is always T (True).

Therefore the first thing we need to do is get a list of all the free variables that occur in
the expression we want to prove is a tautologie.
TODO: Create a function varList that takes as input a ternary logic expression tree (TExpTree)
and retuns a list of all the variable names (strings) contained in the tree.
-}

-- varList to extract variables from TExpTree
--         Extra: Ensures there are no duplicate variables in the list
varList :: TExpTree -> [String]
varList t = nub (varListHelper t)

-- varListHelper: extracts the variables from the TExpTree. Duplicate variables
--                are removed in the varList function
varListHelper :: TExpTree -> [String]
varListHelper t = case t of
                    (L _) -> []
                    (V var) -> [var]
                    (N t1) -> varListHelper t1
                    (A t1 t2) -> varListHelper t1 ++ varListHelper t2
                    (O t1 t2) -> varListHelper t1 ++ varListHelper t2
                    (E t1 t2) -> varListHelper t1 ++ varListHelper t2
                    (I t1 t2) -> varListHelper t1 ++ varListHelper t2

{- Next we need to generate a dictionary for all the possible combinations of values
that can be assigned to the variables.
TODO: create a function dictList that takes a list of variable names (strings) and returns
a list of all the possible dictionaries associating values in the ternary logic to each
of the variables.
Hint: This is a recursive process. For a single variable, there will be 3 dictionaries,
one for each of the 3 literal values in ternary logic. For 2 variables there will be
9 dictionaries, associating all 3 possible values of the first variable to the 3 possible
values of the second variable, and so forth.
-}

dictList :: [String] -> [Dict]
dictList [] = [[]]
dictList (v:[]) = [[(v, tern)] | tern <- [T, F, M]]
dictList (v:vs) = [[(v, tern)] ++ dict | tern <- [T, F, M], dict <- dictList vs]
                  -- List comprehension to generate the combinations from adding another variable

{-
Now we can evaluate a ternary logic expression against all possible
combinations of values of its variables.
TODO: create a function allCases that takes an expression tree (TExpTree) as input and
returns in a list of the results (ternary logic literals) of evaluating the expression tree
to all possible combination of values assigned to the variables (dictionaries)
-}

-- allCases: gets the varList from the TExpTree, then dictList to get all possible
--           combinations of value. Then evaluate the TExpTree for each possible
--           combination, record result in list.
allCases :: TExpTree -> [Ternary]
allCases t = [ evalT dict t | dict <- dictList(varList t)]

{- Finally for the tautology checker.
TODO: create a function isTautology that takes a string, parses it
and return True if the expression contained in the string is a tautology. I.e. if the
evaluation of the expression returns T regardless of the value assigned to the variables.
-}

-- Helper function for isTautology: True if all Ternary values in list are 'T',
--                                  False if not
allT :: [Ternary] -> Bool
allT [] = False
allT [T] = True
allT [_] = False
allT (T:terns) = allT terns
allT (_:terns) = False

-- isTautology: the String is a tautology if it parses to a TExpTree that, for all
--              possible combinations of values for the variables, is 'T'.
isTautology :: String -> Bool
isTautology s = allT (allCases (parseT s))

{- This completes part 4 and the project. You can use the test functions below
to test your work
-}
testVarList :: Bool
testVarList = varList (O (V "vT") (O (N (V "vM")) (E (V "vF") (L M)))) == ["vT", "vM", "vF"]
            && varList (O (L T) (O (N (L F)) (E (L M) (L M)))) == []

sortedDictList :: Ord a => [[a]] -> [[a]]
sortedDictList xss = sort [sort d | d <- xss]

testDictList :: Bool
testDictList = dictList [] == [[]]
                && sortedDictList (dictList ["vT", "vM", "vF"])
              == sortedDictList
                 [[("vT",T),("vM",T),("vF",T)],[("vT",F),("vM",T),("vF",T)],[("vT",M),("vM",T),("vF",T)]
                 ,[("vT",T),("vM",F),("vF",T)],[("vT",F),("vM",F),("vF",T)],[("vT",M),("vM",F),("vF",T)]
                 ,[("vT",T),("vM",M),("vF",T)],[("vT",F),("vM",M),("vF",T)],[("vT",M),("vM",M),("vF",T)]
                 ,[("vT",T),("vM",T),("vF",F)],[("vT",F),("vM",T),("vF",F)],[("vT",M),("vM",T),("vF",F)]
                 ,[("vT",T),("vM",F),("vF",F)],[("vT",F),("vM",F),("vF",F)],[("vT",M),("vM",F),("vF",F)]
                 ,[("vT",T),("vM",M),("vF",F)],[("vT",F),("vM",M),("vF",F)],[("vT",M),("vM",M),("vF",F)]
                 ,[("vT",T),("vM",T),("vF",M)],[("vT",F),("vM",T),("vF",M)],[("vT",M),("vM",T),("vF",M)]
                 ,[("vT",T),("vM",F),("vF",M)],[("vT",F),("vM",F),("vF",M)],[("vT",M),("vM",F),("vF",M)]
                 ,[("vT",T),("vM",M),("vF",M)],[("vT",F),("vM",M),("vF",M)],[("vT",M),("vM",M),("vF",M)]]


testTautology :: Bool
testTautology = isTautology "v ||| ~v ||| (v <=> M)"
              && not (isTautology "v ||| ~v ")
              && isTautology "(v &&& t <=> t &&& v) &&& (w ||| x <=> x ||| w) &&& (z <=> z)"
              && isTautology "~(x ||| y) <=> (~x &&& ~y)"
              && isTautology "~(x &&& y) <=> (~x ||| ~y)"
              && isTautology "v ||| ~v ||| (v<=>M==>F)"

testPart4 :: Bool
testPart4 = testVarList && testDictList && testTautology

testAll :: Bool
testAll = testPart1 && testPart2 && testPart3 && testPart4
