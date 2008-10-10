-----------------------------------------------------------------------------
-- |
-- Module      :  Generics.MultiRec
-- Copyright   :  (c) 2008 Universiteit Utrecht
-- License     :  BSD3
--
-- Maintainer  :  dgp-haskell
-- Stability   :  experimental
-- Portability :  non-portable
--
-- multirec --
-- generic programming with fixed points of mutually recursive datatypes
-- 
-- This top-level module re-exports all other modules of the library.
--
-----------------------------------------------------------------------------

module Generics.MultiRec
  (
    -- * Base
    module Generics.MultiRec.Base,
    
    -- * Generic functions
    module Generics.MultiRec.HFunctor,
    module Generics.MultiRec.Fold,
    module Generics.MultiRec.Compos,
    module Generics.MultiRec.Eq
  )
  where

import Generics.MultiRec.Base
import Generics.MultiRec.HFunctor
import Generics.MultiRec.Fold
import Generics.MultiRec.Compos
import Generics.MultiRec.Eq


