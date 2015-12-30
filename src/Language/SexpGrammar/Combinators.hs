{-# LANGUAGE RankNTypes      #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}

module Language.SexpGrammar.Combinators
  ( list
  , vect
  , el
  , rest
  , props
  , (.:)
  , (.:?)
  , bool
  , integer
  , int
  , real
  , double
  , string
  , symbol
  , keyword
  , string'
  , symbol'
  , sym
  , kw
  , coproduct
  , fx
  , pair
  , unpair
  , swap
  ) where

import Prelude hiding ((.), id)

import Control.Category
import Data.Semigroup (sconcat)
import qualified Data.List.NonEmpty as NE
import Data.Functor.Foldable (Fix (..))
import Data.Scientific
import Data.StackPrism
import Data.Text (Text, pack, unpack)
import Data.Coerce

import Data.InvertibleGrammar
import Data.InvertibleGrammar.TH
import Language.Sexp.Types
import Language.SexpGrammar.Base

----------------------------------------------------------------------
-- Sequence combinators

list :: Grammar SeqGrammar t t' -> Grammar SexpGrammar (Sexp :- t) t'
list = Inject . GList

vect :: Grammar SeqGrammar t t' -> Grammar SexpGrammar (Sexp :- t) t'
vect = Inject . GVect

el :: Grammar SexpGrammar (Sexp :- a) b -> Grammar SeqGrammar a b
el = Inject . GElem

rest :: Grammar SexpGrammar (Sexp :- a) (b :- a) -> Grammar SeqGrammar a ([b] :- a)
rest = Inject . GRest

props :: Grammar PropGrammar a b -> Grammar SeqGrammar a b
props = Inject . GProps

(.:) :: Kw -> Grammar SexpGrammar (Sexp :- t) (a :- t) -> Grammar PropGrammar t (a :- t)
(.:) name = Inject . GProp name

(.:?) :: Kw -> Grammar SexpGrammar (Sexp :- t) (a :- t) -> Grammar PropGrammar t (Maybe a :- t)
(.:?) name g = coproduct
  [ $(grammarFor 'Just) . (name .: g)
  , $(grammarFor 'Nothing)
  ]

----------------------------------------------------------------------
-- Atom combinators

bool :: SexpG Bool
bool = Inject . GAtom . Inject $ GBool

integer :: SexpG Integer
integer = Inject . GAtom . Inject $ GInt

int :: SexpG Int
int = iso fromIntegral fromIntegral . integer

real :: SexpG Scientific
real = Inject . GAtom . Inject $ GReal

double :: SexpG Double
double = iso toRealFloat fromFloatDigits . real

string :: SexpG Text
string = Inject . GAtom . Inject $ GString

string' :: SexpG String
string' = iso unpack pack . string

symbol :: SexpG Text
symbol = Inject . GAtom . Inject $ GSymbol

symbol' :: SexpG String
symbol' = iso unpack pack . symbol

keyword :: SexpG Kw
keyword = Inject . GAtom . Inject $ GKeyword

sym :: Text -> SexpG_
sym = Inject . GAtom . Inject . GSym

kw :: Kw -> SexpG_
kw = Inject . GAtom . Inject . GKw

----------------------------------------------------------------------
-- Special combinators

coproduct :: [Grammar g a b] -> Grammar g a b
coproduct = sconcat . NE.fromList

fx :: Grammar g (f (Fix f) :- t) (Fix f :- t)
fx = iso coerce coerce

pair :: Grammar g (b :- a :- t) ((a, b) :- t)
unpair :: Grammar g ((a, b) :- t) (b :- a :- t)
(pair, unpair) = (Iso f g, Iso g f)
  where
    f = (\(b :- a :- t) -> (a, b) :- t)
    g = (\((a, b) :- t) -> (b :- a :- t))

swap :: Grammar g (b :- a :- t) (a :- b :- t)
swap = Iso (\(b :- a :- t) -> a :- b :- t)
           (\(a :- b :- t) -> b :- a :- t)
