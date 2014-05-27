{-# LANGUAGE BangPatterns, FlexibleInstances, OverloadedStrings,
    TypeSynonymInstances #-}

module QC.Buffer (tests) where

import Data.Monoid (mconcat)
import QC.Common ()
import Test.Framework (Test)
import Test.Framework.Providers.QuickCheck2 (testProperty)
import Test.QuickCheck
import qualified Data.Attoparsec.ByteString.Buffer as BB
import qualified Data.Attoparsec.Text.Buffer as BT
import qualified Data.ByteString as B
import qualified Data.ByteString.Unsafe as B
import qualified Data.Text as T
import qualified Data.Text.Unsafe as T

data BP t b = BP [t] !t !b
            deriving (Eq, Show)

type BPB = BP B.ByteString BB.Buffer
type BPT = BP T.Text BT.Buffer

instance Arbitrary BPB where
  arbitrary = do
    bss <- arbitrary
    return $! BP bss (mconcat bss) (mconcat (map BB.buffer bss))

instance Arbitrary BPT where
  arbitrary = do
    bss <- arbitrary
    return $! BP bss (mconcat bss) (mconcat (map BT.buffer bss))

b_unbuffer :: BPB -> Property
b_unbuffer (BP _ts t buf) = t === BB.unbuffer buf

t_unbuffer :: BPT -> Property
t_unbuffer (BP _ts t buf) = t === BT.unbuffer buf

b_length :: BPB -> Property
b_length (BP _ts t buf) = B.length t === BB.length buf

t_length :: BPT -> Property
t_length (BP _ts t buf) = T.lengthWord16 t === BT.length buf

b_unsafeIndex :: BPB -> Gen Property
b_unsafeIndex (BP _ts t buf) = do
  let l = B.length t
  i <- choose (0,l-1)
  return $ l === 0 .||. B.unsafeIndex t i === BB.unsafeIndex buf i

t_iter :: BPT -> Gen Property
t_iter (BP _ts t buf) = do
  let l = T.lengthWord16 t
  i <- choose (0,l-1)
  let it (T.Iter c q) = (c,q)
  return $ l === 0 .||. it (T.iter t i) === it (BT.iter buf i)

t_iter_ :: BPT -> Gen Property
t_iter_ (BP _ts t buf) = do
  let l = T.lengthWord16 t
  i <- choose (0,l-1)
  return $ l === 0 .||. T.iter_ t i === BT.iter_ buf i

b_unsafeDrop :: BPB -> Gen Property
b_unsafeDrop (BP _ts t buf) = do
  i <- choose (0, B.length t)
  return $ B.unsafeDrop i t === BB.unsafeDrop i buf

t_dropWord16 :: BPT -> Gen Property
t_dropWord16 (BP _ts t buf) = do
  i <- choose (0, T.lengthWord16 t)
  return $ T.dropWord16 i t === BT.dropWord16 i buf

tests :: [Test]
tests = [
    testProperty "b_unbuffer" b_unbuffer
  , testProperty "t_unbuffer" t_unbuffer
  , testProperty "b_length" b_length
  , testProperty "t_length" t_length
  , testProperty "b_unsafeIndex" b_unsafeIndex
  , testProperty "t_iter" t_iter
  , testProperty "t_iter_" t_iter_
  , testProperty "b_unsafeDrop" b_unsafeDrop
  , testProperty "t_dropWord16" t_dropWord16
  ]
