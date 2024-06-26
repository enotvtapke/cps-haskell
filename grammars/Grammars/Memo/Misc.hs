{-# LANGUAGE OverloadedStrings #-}

module Grammars.Memo.Misc
  ( acc,
    accLongest,
    palindrom,
    indirect,
    higherOrder,
    cca,
    exponential,
    exponentialUnmemoized,
    anbncn,
    count,
  )
where

import CPS.Parser.Memo (Key (..), Parser (..), makeStableKey, memo, memoWithKey, getOrMakeKey)
import CPS.Parser.Primitives (chunk, eof, single)
import CPS.Stream.Stream (ParserState)
import Control.Applicative (Alternative (some), (<|>))
import Control.Monad (replicateM, join)
import Data.Text qualified as T

-- | This parser is for grammmar with indirect left recursion
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
acc = memo $ T.append <$> acc <*> chunk "c" <|> chunk "a"

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
    aSuf p = memoWithKey (Key (makeStableKey aSuf, getOrMakeKey p)) $ ((<>) <$> bSuf p <*> chunk "a") <|> p

    bSuf :: Parser T.Text T.Text -> Parser T.Text T.Text
    bSuf p = memoWithKey (Key (makeStableKey bSuf, getOrMakeKey p)) $ (<>) <$> aSuf p <*> chunk "b"

-- | This parser has exponential time complexity when unmemoized
exponential :: Parser (ParserState T.Text) T.Text
exponential =
  memo $
    do
      a <- single 'a'
      aa <- exponential
      x <- single 'x'
      return $ T.snoc (T.cons a aa) x
      <|> do
        a <- single 'a'
        aa <- exponential
        x <- single 'y'
        return $ T.snoc (T.cons a aa) x
      <|> pure T.empty

exponentialUnmemoized :: Parser (ParserState T.Text) T.Text
exponentialUnmemoized =
  do
    a <- single 'a'
    aa <- exponentialUnmemoized
    x <- single 'x'
    return $ T.snoc (T.cons a aa) x
    <|> do
      a <- single 'a'
      aa <- exponentialUnmemoized
      x <- single 'y'
      return $ T.snoc (T.cons a aa) x
    <|> pure T.empty

-- | This parser parses non-context-free language
anbncn :: Parser (ParserState T.Text) T.Text
anbncn = do
  a <- some (single 'a')
  b <- replicateM (length a) (single 'b')
  c <- replicateM (length a) (single 'c')
  eof
  return $ T.pack (a <> b <> c)

count :: Parser String String -> Int -> Parser String String
count p n = join <$> replicateM n p
