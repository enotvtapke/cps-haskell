module Main (main) where

import CPS.Parser.PrimitivesSpec
import Test.Tasty (defaultMain, testGroup)
import Test.Tasty.Hspec (testSpecs)

main :: IO ()
main = do
  specs <-
    concat
      <$> mapM
        testSpecs
        [ primitivesSpec
        ]
  defaultMain
    ( testGroup
        "Main Tests"
        [ testGroup "Specs" specs
        ]
    )
