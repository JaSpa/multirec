{-# LANGUAGE GADTs
           , RankNTypes
           , TypeOperators
           , KindSignatures
           #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Generics.MultiRec.HFunctor
-- Copyright   :  (c) 2008 Universiteit Utrecht
-- License     :  BSD3
--
-- Maintainer  :  generics@haskell.org
-- Stability   :  experimental
-- Portability :  non-portable
--
-- The definition of functorial map.
--
-----------------------------------------------------------------------------
module Generics.MultiRec.HFunctorF where

import Control.Monad (liftM, liftM2)
import Control.Applicative (Applicative(..), liftA, liftA2, WrappedMonad(..))

import Generics.MultiRec.BaseF
import qualified Generics.MultiRec.Base as Base

-- * Generic map

-- We define a general 'hmapA' that works on applicative functors.
-- The simpler 'hmap' is a special case.

class HFunctor (f :: ((* -> *) -> *) -> (* -> (* -> *) -> *) -> * -> (* -> *) -> *) where
  hmapA :: (Applicative a) =>
           (forall ix. Ix s ix => s ix -> r e ix -> a (r' e ix)) ->
           f s r e ix -> a (f s r' e ix)

instance HFunctor (I xi) where
  hmapA f (I x) = liftA I (f index x)

instance HFunctor (K x) where
  hmapA _ (K x)  = pure (K x)

instance (HFunctor f, HFunctor g) => HFunctor (f :+: g) where
  hmapA f (L x) = liftA L (hmapA f x)
  hmapA f (R y) = liftA R (hmapA f y)

instance (HFunctor f, HFunctor g) => HFunctor (f :*: g) where
  hmapA f (x :*: y) = liftA2 (:*:) (hmapA f x) (hmapA f y)

instance HFunctor f => HFunctor (f :>: ix) where
  hmapA f (Tag x) = liftA Tag (hmapA f x)

-- | The function 'hmap' takes a functor @f@. All the recursive instances
-- in that functor are wrapped by an application of @r@. The argument to
-- 'hmap' takes a function that transformes @r@ occurrences into @r'@
-- occurrences, for every @ix@. In order to associate the index @ix@
-- with the correct system @s@, the argument to @hmap@ is additionally
-- parameterized by a witness of type @s ix@. 
hmap  :: (HFunctor f) =>
         (forall ix. Ix s ix => s ix -> r e ix -> r' e ix) ->
         f s r e ix -> f s r' e ix
hmap f x = Base.unI0 (hmapA (\ ix x -> Base.I0 (f ix x)) x)

-- | Monadic version of 'hmap'.
hmapM :: (HFunctor f, Monad m) =>
         (forall ix. Ix s ix => s ix -> r e ix -> m (r' e ix)) ->
         f s r e ix -> m (f s r' e ix)
hmapM f x = unwrapMonad (hmapA (\ ix x -> WrapMonad (f ix x)) x)
