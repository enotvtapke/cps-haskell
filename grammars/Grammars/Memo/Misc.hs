{-# LANGUAGE OverloadedStrings #-}

module Grammars.Memo.Misc
  ( acc,
    accLongest,
    palindrom,
    indirect,
    higherOrder,
    cca,
    exponentional,
  )
where

import CPS.Parser.Memo (Key (..), Parser (..), makeStableKey, memo, memoWithKey)
import CPS.Parser.Primitives (chunk, eof, single)
import CPS.Stream.Stream (ParserState)
import Control.Applicative ((<|>))
import Data.Text qualified as T

indirect :: Parser T.Text T.Text
indirect = memo $ indirect' <|> chunk "a"
  where
    indirect' :: Parser T.Text T.Text
    indirect' = memo $ (<>) <$> indirect <*> chunk "b"

accLongest :: Parser T.Text T.Text
accLongest = do
  x <- acc
  x <$ eof

acc :: Parser T.Text T.Text
acc =
  memo $
    T.append <$> acc <*> chunk "c"
      <|> chunk "a"

cca :: Parser (ParserState T.Text) T.Text
cca =
  memo $
    chunk "c"
      >> cca
        <|> do
          chunk "a"

palindrom :: Parser (ParserState T.Text) T.Text
palindrom =
  memo $
    chunk "d"
      <|> do
        l <- chunk "a"
        p <- palindrom
        r <- chunk "a"
        return $ l <> p <> r
      <|> do
        l <- chunk "b"
        p <- palindrom
        r <- chunk "b"
        return $ l <> p <> r
      <|> do
        l <- chunk "c"
        p <- palindrom
        r <- chunk "c"
        return $ l <> p <> r

-- | This parser uses mutually recursive higher order parsers
higherOrder :: Parser T.Text T.Text
higherOrder = memo $ aSuf (chunk "c")
  where
    aSuf :: Parser T.Text T.Text -> Parser T.Text T.Text
    aSuf p = memoWithKey (Key (makeStableKey aSuf, key p)) $ ((<>) <$> bSuf p <*> chunk "a") <|> p

    bSuf :: Parser T.Text T.Text -> Parser T.Text T.Text
    bSuf p = memoWithKey (Key (makeStableKey bSuf, key p)) $ (<>) <$> aSuf p <*> chunk "b"

-- | This parser has exponentional time complexity when unmemoized
exponentional :: Parser (ParserState T.Text) T.Text
exponentional = memo $
  do
    a <- single 'a'
    aa <- exponentional
    x <- single 'x'
    return $ T.snoc (T.cons a aa) x
    <|> do
      a <- single 'a'
      aa <- exponentional
      x <- single 'y'
      return $ T.snoc (T.cons a aa) x
    <|> pure T.empty
