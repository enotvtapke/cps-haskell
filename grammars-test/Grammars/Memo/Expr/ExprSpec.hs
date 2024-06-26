{-# LANGUAGE OverloadedStrings #-}

module Grammars.Memo.Expr.ExprSpec where

import CPS.Parser.Memo (_parse)
import Data.Bifunctor (first)
import Data.Text qualified as T
import Grammars.Memo.Expr.Expr
import Grammars.Memo.Expr.ExprGenerator (genExpr)
import Grammars.Memo.Expr.ExprParser (exprStart)
import Test.Hspec

exprSpec :: Spec
exprSpec = describe "Expr" $ do
  spec_exprStart
  spec_exprStartRandom

spec_exprStart :: Spec
spec_exprStart =
  describe "exprStart" $ do
    it "parses '42'" $
      _parse exprStart "42" `shouldBe` [(ExprVal (TermVal (FVal 42)), "")]
    it "parses '99+1'" $
      _parse exprStart "99+1" `shouldBe` [(ExprOp (ExprVal (TermVal (FVal 99))) "+" (TermVal (FVal 1)), "")]
    it "parses '75/5'" $
      _parse exprStart "75/5" `shouldBe` [(ExprVal (TermOp (TermVal (FVal 75)) "/" (FVal 5)), "")]
    it "parses '3+1+2'" $
      _parse exprStart "3+1+2" `shouldBe` [(ExprOp (ExprOp (ExprVal (TermVal (FVal 3))) "+" (TermVal (FVal 1))) "+" (TermVal (FVal 2)), "")]
    it "parses '4*(2-44)'" $
      _parse exprStart "4*(2-44)" `shouldBe` [(ExprVal (TermOp (TermVal (FVal 4)) "*" (FExpr (ExprOp (ExprVal (TermVal (FVal 2))) "-" (TermVal (FVal 44))))), "")]
    it "does not parse '+12'" $
      _parse exprStart "+12" `shouldBe` []
    it "does not parse '2^10'" $
      _parse exprStart "2^10" `shouldBe` []

spec_exprStartRandom :: Spec
spec_exprStartRandom =
  describe "exprStart on random Expr" $ do
    it "parses random Expr with length 1000" $
      do
        let generated = show $ genExpr 1000
        let actual = first show <$> _parse exprStart (T.pack generated)
        actual `shouldBe` [(generated, "")]
