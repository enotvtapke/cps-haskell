{-# LANGUAGE OverloadedStrings #-}

module Grammars.Memo.MiscSpec where

import CPS.Parser.Memo (_parse)
import CPS.Stream.Stream (ParserState (..), parserState)
import Grammars.Memo.Misc (acc, accLongest, higherOrder, indirect, palindrom, exponentional)
import Test.Hspec
import qualified Data.Text as T

miscSpec :: Spec
miscSpec = describe "Misc" $ do
  spec_acc
  spec_accLongest
  spec_palindrom
  spec_indirect
  spec_higherOrder
  spec_exponentional

spec_acc :: Spec
spec_acc =
  describe "acc" $ do
    it "parses 'acc'" $
      _parse acc "acc" `shouldBe` [("acc", ""), ("ac", "c"), ("a", "cc")]
    it "parses 'a'" $
      _parse acc "a" `shouldBe` [("a", "")]
    it "does not parse 'cc'" $
      _parse acc "cc" `shouldBe` []

spec_accLongest :: Spec
spec_accLongest =
  describe "accLongest" $ do
    it "parses 'acc'" $
      _parse accLongest "acc" `shouldBe` [("acc", "")]
    it "parses 'a'" $
      _parse accLongest "a" `shouldBe` [("a", "")]
    it "does not parse 'cc'" $
      _parse accLongest "cc" `shouldBe` []

spec_palindrom :: Spec
spec_palindrom =
  describe "palindrom" $ do
    it "parses 'd'" $
      _parse palindrom (parserState "d") `shouldBe` [("d", ParserState "" 1)]
    it "parses 'ada'" $
      _parse palindrom (parserState "ada") `shouldBe` [("ada", ParserState "" 3)]
    it "parses 'abcdcba'" $
      _parse palindrom (parserState "abcdcba") `shouldBe` [("abcdcba", ParserState "" 7)]
    it "parses 'abcaaccbabcdcbabccaacba'" $
      _parse palindrom (parserState "abcaaccbabcdcbabccaacba") `shouldBe` [("abcaaccbabcdcbabccaacba", ParserState "" 23)]
    it "does not parse 'bda'" $
      _parse palindrom (parserState "bda") `shouldBe` []
    it "does not parse 'abccaccbabcdcbabccaacba'" $
      _parse palindrom (parserState "abccaccbabcdcbabccaacba") `shouldBe` []

spec_indirect :: Spec
spec_indirect =
  describe "indirect" $ do
    it "parses 'a'" $
      _parse indirect "a" `shouldBe` [("a", "")]
    it "parses 'abb'" $
      _parse indirect "abb" `shouldBe` [("abb", ""), ("ab", "b"), ("a", "bb")]
    it "does not parse 'bb'" $
      _parse indirect "bb" `shouldBe` []

spec_higherOrder :: Spec
spec_higherOrder =
  describe "higherOrder" $ do
    it "parses 'с'" $
      _parse higherOrder "c" `shouldBe` [("c", "")]
    it "parses 'cba'" $
      _parse higherOrder "cba" `shouldBe` [("cba", ""), ("c", "ba")]
    it "parses 'cbababa'" $
      _parse higherOrder "cbababa" `shouldBe` [("cbababa", ""), ("cbaba", "ba"), ("cba", "baba"), ("c", "bababa")]
    it "does not parse 'bababa'" $
      _parse higherOrder "bababa" `shouldBe` []
    it "does not parse 'сbadbaba'" $
      _parse higherOrder "сbadbaba" `shouldBe` []

spec_exponentional :: Spec
spec_exponentional =
  describe "exponentional" $ do
    it "parses aaxy" $ do
      let input = genInput 1
      _parse exponentional input `shouldBe` [(stream input, ParserState "" (T.length (stream input))), ("", input)]
    it "parses a{1000}xy{500}" $ do
      let input = genInput 500
      _parse exponentional input `shouldBe` [(stream input, ParserState "" (T.length (stream input))), ("", input)]
    it "does not parse a{500}ba{499}xy{500}" $ do
      let input = parserState (T.pack $ replicate 500 'a' <> "b" <> replicate 499 'a'<> concat (replicate 500 "xy"))
      _parse exponentional input `shouldBe` [("", input)]
  where
    genInput n = parserState (T.pack $ replicate (2 * n) 'a' <> concat (replicate n "xy"))
