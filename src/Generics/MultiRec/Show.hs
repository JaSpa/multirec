{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE GADTs                 #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Generics.MultiRec.Show
-- Copyright   :  (c) 2008--2009 Universiteit Utrecht
-- License     :  BSD3
--
-- Maintainer  :  generics@haskell.org
-- Stability   :  experimental
-- Portability :  non-portable
--
-- Generic show.
--
-----------------------------------------------------------------------------

module Generics.MultiRec.Show where

import Generics.MultiRec.Base
import Generics.MultiRec.HFunctor
import Generics.MultiRec.FoldK

import qualified Prelude as P
import Prelude hiding (show, showsPrec)

-- * Generic show

class HFunctor phi f => HShow phi f where
  hShowsPrecAlg :: Algebra' phi f [Int -> ShowS]

instance El phi xi => HShow phi (I xi) where
  hShowsPrecAlg _ (I (K0 x)) = x

-- | For constant types, we make use of the standard
-- show function.
instance Show a => HShow phi (K a) where
  hShowsPrecAlg _ (K x) = [\ n -> P.showsPrec n x]

instance HShow phi U where
  hShowsPrecAlg _ U = []

instance (HShow phi f, HShow phi g) => HShow phi (f :+: g) where
  hShowsPrecAlg ix (L x) = hShowsPrecAlg ix x
  hShowsPrecAlg ix (R y) = hShowsPrecAlg ix y

instance (HShow phi f, HShow phi g) => HShow phi (f :*: g) where
  hShowsPrecAlg ix (x :*: y) = hShowsPrecAlg ix x ++ hShowsPrecAlg ix y

instance HShow phi f => HShow phi (f :>: ix) where
  hShowsPrecAlg ix (Tag x) = hShowsPrecAlg ix x

instance (Constructor c, HShow phi f) => HShow phi (C c f) where
  hShowsPrecAlg ix cx@(C x) =
    case conFixity cx of
      Prefix    -> [\ n -> showParen (not (null fields) && n > 10)
                                     (spaces ((conName cx ++) : map ($ 11) fields))]
      Infix a p -> [\ n -> showParen (n > p)
                                     (spaces (head fields p : (conName cx ++) : map ($ p) (tail fields)))]
   where
    fields = hShowsPrecAlg ix x

showsPrec :: (Fam phi, HShow phi (PF phi)) => phi ix -> Int -> ix -> ShowS
showsPrec p n x = spaces (map ($ n) (fold hShowsPrecAlg p x))

show :: (Fam phi, HShow phi (PF phi)) => phi ix -> ix -> String
show ix x = showsPrec ix 0 x ""

-- * Utilities

spaces :: [ShowS] -> ShowS
spaces []     = id
spaces [x]    = x
spaces (x:xs) = x . (' ':) . spaces xs
