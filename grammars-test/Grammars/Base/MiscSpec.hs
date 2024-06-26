{-# LANGUAGE OverloadedStrings #-}

module Grammars.Base.MiscSpec where

import CPS.Parser.Base (baseParse)
import Grammars.Base.Misc (acc, accLongest, indirect, palindrom)
import Test.Hspec

baseMiscSpec :: Spec
baseMiscSpec = describe "Misc" $ do
  spec_acc
  spec_accLongest
  spec_palindrom
  spec_indirect

spec_acc :: Spec
spec_acc =
  describe "acc" $ do
    it "parses 'acc'" $
      baseParse acc "acc" `shouldBe` [("acc", ""), ("ac", "c"), ("a", "cc")]
    it "parses 'a'" $
      baseParse acc "a" `shouldBe` [("a", "")]
    it "does not parse 'cc'" $
      baseParse acc "cc" `shouldBe` []

spec_accLongest :: Spec
spec_accLongest =
  describe "accLongest" $ do
    it "parses 'acc'" $
      baseParse accLongest "acc" `shouldBe` [("acc", "")]
    it "parses 'a'" $
      baseParse accLongest "a" `shouldBe` [("a", "")]
    it "does not parse 'cc'" $
      baseParse accLongest "cc" `shouldBe` []

spec_palindrom :: Spec
spec_palindrom =
  describe "palindrom" $ do
    it "parses 'd'" $
      baseParse palindrom "d" `shouldBe` [("d", "")]
    it "parses 'ada'" $
      baseParse palindrom "ada" `shouldBe` [("ada", "")]
    it "parses 'abcdcba'" $
      baseParse palindrom "abcdcba" `shouldBe` [("abcdcba", "")]
    it "parses 'abcaaccbabcdcbabccaacba'" $
      baseParse palindrom "abcaaccbabcdcbabccaacba" `shouldBe` [("abcaaccbabcdcbabccaacba", "")]
    it "does not parse 'bda'" $
      baseParse palindrom "bda" `shouldBe` []
    it "does not parse 'abccaccbabcdcbabccaacba'" $
      baseParse palindrom "abccaccbabcdcbabccaacba" `shouldBe` []

spec_indirect :: Spec
spec_indirect =
  describe "indirect" $ do
    it "parses 'a'" $
      baseParse indirect "a" `shouldBe` [("a", "")]
    it "parses 'abb'" $
      baseParse indirect "abb" `shouldBe` [("abb", ""), ("ab", "b"), ("a", "bb")]
    it "does not parse 'bb'" $
      baseParse indirect "bb" `shouldBe` []
