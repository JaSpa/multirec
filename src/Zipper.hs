{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE StandaloneDeriving   #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE PatternSignatures    #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE GADTs                #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE EmptyDataDecls       #-}
{-# LANGUAGE TypeOperators        #-}

module Zipper where

import Control.Monad

import Base

-- ixh : type of hole
-- ix  : type of tree
data Prod' df f (l :: * -> *) ixh ix = Prod' (df l ixh ix) (f l ix)

data Sum' df dg (l :: * -> *) ixh ix = L' (df l ixh ix) | R' (dg l ixh ix)

data Zero' (l :: * -> *) ixh ix

data Tag' ixtag df (l :: * -> *) ixh ix where
  Tag' :: df l ixh ix -> Tag' ix df l ixh ix

data Unit' xi (l :: * -> *) ixh ix where
  Unit' :: Unit' ixh l ixh ix

type Unit = K ()



data Zipper lz ix where
  Zipper :: Ix lz ixh => ixh -> (CList lz ixh ix) -> Zipper lz ix

data CList lc ixh ix where
  CNil :: CList l ix ix
  CCons :: D (PF l) l ixh ix -> CList l ix ix' -> CList l ixh ix' 

toZipper :: Ix l ix => ix -> Zipper l ix
toZipper x = Zipper x CNil

-- The stuff below does not type. But I don't know why!
--
--down :: forall ll ix . (ZipFuns (PF ll)) => Zipper ll ix -> Maybe (Zipper ll ix)
--down (Zipper (x::ix') ctxs)
--  = do
--    ExFirst ctx x' <- firstf (from x::PF ll ll ix') --(from x::PF ll ll ix')
--    return (Zipper x' (CCons ctx ctxs))

class Diff (f ::  (* -> *) -> * -> * ) where
  type D f :: (* -> *) -- family name
           -> *        -- type of the hole
           -> *        -- type of surrounding tree
           -> *

instance Diff Unit where
  type D Unit = Zero'

instance Diff (Id xi) where
  type D (Id xi) = Unit' xi

instance (Diff f, Diff g) => Diff (f :+: g) where
  type D (f :+: g) = D f `Sum'` D g

instance (Diff f, Diff g) => Diff (f :*: g) where
  type D (f :*: g) = Prod' (D f) g `Sum'` Prod' (D g) f

instance Diff f => Diff (f ::: ixtag) where
  type D (f ::: ixtag) = Tag' ixtag (D f)

data ExFirst f lx ix = forall ixh . Ix lx ixh => ExFirst (D f lx ixh ix) ixh

class ZipFuns (f :: (* -> *) -> * -> *) where
  firstf :: f lm ix -> Maybe (ExFirst f lm ix)
  up     :: Ix l ixh => ixh -> D f l ixh ix -> Maybe (f l ix)
  --nextf  :: Ix l ixh => ixh -> D f ixh ix -> Either (ExFirst f l ix) (f l ix)

instance ZipFuns f => ZipFuns (f ::: ixtag) where
  firstf (Tag x)
   = do
     ExFirst ctx h <- firstf x
     return (ExFirst (Tag' ctx) h) 
  up h (Tag' ctx) = liftM Tag (up h ctx)

instance (ZipFuns f, ZipFuns g) => ZipFuns (f :*: g) where
  firstf (x :*: y)
   = do
     ExFirst ctx h <- firstf x
     return (ExFirst (L' (Prod' ctx y)) h)
     `mplus`
     do
     ExFirst ctx h <- firstf y
     return (ExFirst (R' (Prod' ctx x)) h)
  up h (L' (Prod' ctx y)) = liftM (:*:y) (up h ctx)
  up h (R' (Prod' ctx x)) = liftM (x:*:) (up h ctx)
  

instance ZipFuns Unit where
  firstf (K ()) = Nothing
  up ixh zeroval = undefined

instance ZipFuns (Id xi) where
  firstf (Id x) = Just (ExFirst Unit' x)
  up ixh Unit' = Just (Id ixh)

instance (ZipFuns f, ZipFuns g) => ZipFuns (f :+: g) where
  firstf (L x)
   = do
     ExFirst ctx h <- firstf x
     return (ExFirst (L' ctx) h)
  firstf (R x)
   = do
     ExFirst ctx h <- firstf x
     return (ExFirst (R' ctx) h)
  up h (L' ctx) = liftM L (up h ctx)
  up h (R' ctx) = liftM R (up h ctx)


