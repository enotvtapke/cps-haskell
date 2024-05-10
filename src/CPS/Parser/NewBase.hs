{-# LANGUAGE FunctionalDependencies #-}

module CPS.Parser.NewBase
  ( BaseParser,
    baseParse,
    baseSat,
    DeterministicAlternative(..),
    Cont(..),
    ContState,
    MemoTable,
    MemoEntry(..),
  )
where

import Control.Applicative (Alternative (empty, (<|>)))
import Control.Monad (MonadPlus, guard, join)
import Control.Monad.State
  ( MonadState (get),
    State,
    StateT (..),
    evalState,
    modify,
  )
import Control.Monad.State.Lazy (gets)
import Data.Bifunctor (Bifunctor (first))
import Data.Dynamic (Dynamic (..), Typeable, fromDyn, toDyn)
import Data.HashMap.Lazy qualified as Map
import Data.Hashable (Hashable)
import Data.Typeable (typeOf)
-- import Text.Megaparsec (ParsecT(un))
import Text.Megaparsec.Internal (ParsecT(..))

data MemoEntry k a r = MemoEntry {results :: [a], continuations :: [a -> ContState k [r]]}

type MemoTable k = Map.HashMap k (MemoEntry k Dynamic Dynamic)

type ContState k = State (MemoTable k)

newtype Cont k a = Cont {runCont :: forall r. (Typeable r) => (a -> ContState k [r]) -> ContState k [r]}

type BaseParser k s = StateT s (Cont k)

instance Monad (Cont k) where
  (>>=) :: Cont k a -> (a -> Cont k b) -> Cont k b
  (>>=) m f = Cont (\cont -> runCont m (\r -> runCont (f r) cont))

instance Functor (Cont k) where
  fmap :: (a -> b) -> Cont k a -> Cont k b
  fmap f m = Cont (\cont -> runCont m (cont . f))

instance Applicative (Cont k) where
  pure :: a -> Cont k a
  pure a = Cont (\cont -> cont a)
  (<*>) :: Cont k (a -> b) -> Cont k a -> Cont k b
  (<*>) f m = Cont (\cont -> runCont f (\r -> runCont (r <$> m) cont))

instance Alternative (Cont k) where
  empty :: Cont k a
  empty = Cont (\_ -> return empty)
  (<|>) :: Cont k a -> Cont k a -> Cont k a
  (<|>) l r =
    Cont
      ( \k -> do
          leftResults <- runCont l k
          rightResults <- runCont r k
          return $ leftResults <|> rightResults
      )

instance MonadPlus (Cont k)

infixl 3 </>

class Alternative f => DeterministicAlternative f where
  (</>) :: f a -> f a -> f a

instance DeterministicAlternative (Cont k) where
  (</>) :: Cont k a -> Cont k a -> Cont k a
  (</>) l r =
    Cont
      ( \k -> do
          leftResults <- runCont l k
          case leftResults of
            [] -> runCont r k
            _ -> return leftResults
      )

instance DeterministicAlternative (BaseParser k s) where
  (</>) :: BaseParser k s a -> BaseParser k s a -> BaseParser k s a
  StateT m </> StateT n = StateT $ \s -> m s </> n s

class Memoizable m k where
  memo :: (Typeable a, Hashable k, Eq k) => k -> m a -> m a

instance Memoizable (Cont k) k where
  memo :: (Typeable a, Hashable k, Eq k) => k -> Cont k a -> Cont k a
  memo = memoCont

-- instance (Memoizable m k) => Memoizable (ParsecT e s m) k where
--   memo :: (Memoizable m k, Typeable a, Hashable k, Eq k) => k -> ParsecT e s m a -> ParsecT e s m a
--   memo key p = ParsecT $ \s cok cerr eok eerr ->
--     memo (key) $ unParser p s cok cerr eok eerr
--     -- unParser p s cok cerr eok eerr
--     -- where
--     --   memoCok x y z = memo (cok x y z)

memoCont :: (Typeable a, Hashable k, Eq k) => k -> Cont k a -> Cont k a
memoCont key cont = Cont $ \continuation ->
    do
      -- modify $ Map.insertWith (\_ old -> old) key Map.empty
      entry <- gets $ Map.lookup key
      case entry of
        Nothing -> do
          modify $ addNewEntry key $ MemoEntry [] [toDynContinuation continuation]
          runCont
            cont
            ( \result -> do
                modify (addResult key result)
                conts <- gets $ \table -> continuations (table Map.! key)
                join <$> mapM (\cont -> fmap fromDynUnsafe <$> cont (toDyn result)) conts
            )
        Just foundEntry -> do
          modify (addContinuation key continuation)
          join <$> mapM (continuation . fromDynUnsafe) (results foundEntry)
  where
    toDynContinuation :: (Typeable r, Typeable a) => (a -> ContState k [r]) -> Dynamic -> ContState k [Dynamic]
    toDynContinuation cont x = fmap toDyn <$> cont (fromDynUnsafe x)
    addNewEntry :: Hashable k => k -> MemoEntry k Dynamic Dynamic -> MemoTable k -> MemoTable k
    addNewEntry = Map.insert
    addResult :: (Hashable k, Typeable a) => k -> a -> MemoTable k -> MemoTable k
    addResult key res = Map.adjust (\e -> MemoEntry (toDyn res : results e) (continuations e)) key
    addContinuation :: (Hashable k, Typeable a, Typeable r) => k -> (a -> ContState k [r]) -> MemoTable k -> MemoTable k
    addContinuation key cont = Map.adjust (\e -> let c = MemoEntry (results e) (let b = toDynContinuation cont in b: continuations e) in c) key
    fromDynUnsafe :: (Typeable a) => Dynamic -> a
    fromDynUnsafe dynamic = fromDyn dynamic $ error ("Dynamic has invalid type.\nGot: " <> show (typeOf dynamic))

-- baseMemo :: (Typeable a, Hashable k, Hashable s, Eq k, Eq s) => k -> BaseParser k s a -> BaseParser k s a
-- baseMemo key parser = StateT $ \state ->
--   Cont $ \continuation ->
--     do
--       modify $ Map.insertWith (\_ old -> old) key Map.empty
--       entry <- gets $ \table -> Map.lookup state $ table Map.! key
--       case entry of
--         Nothing -> do
--           modify $ addNewEntry state $ MemoEntry [] [toDynContinuation continuation]
--           runCont
--             (runStateT parser state)
--             ( \result -> do
--                 modify (addResult state result)
--                 conts <- gets $ \table -> continuations $ (table Map.! key) Map.! state
--                 join <$> mapM (\cont -> fmap fromDynUnsafe <$> cont (first toDyn result)) conts
--             )
--         Just foundEntry -> do
--           modify (addContinuation state continuation)
--           join <$> mapM (continuation . first fromDynUnsafe) (results foundEntry)
--   where
--     toDynContinuation :: (Typeable r, Typeable a) => ((a, s) -> ContState k s [r]) -> (Dynamic, s) -> ContState k s [Dynamic]
--     toDynContinuation cont x = fmap toDyn <$> cont (first fromDynUnsafe x)
--     addNewEntry state entry table = Map.insert key (Map.insert state entry (table Map.! key)) table
--     addResult state res table = Map.insert key (Map.adjust (\e -> MemoEntry (first toDyn res : results e) (continuations e)) state (table Map.! key)) table
--     addContinuation state cont table = Map.insert key (Map.adjust (\e -> MemoEntry (results e) (toDynContinuation cont : continuations e)) state (table Map.! key)) table
--     fromDynUnsafe :: (Typeable a) => Dynamic -> a
--     fromDynUnsafe dynamic = fromDyn dynamic $ error ("Dynamic has invalid type.\nGot: " <> show (typeOf dynamic))

baseSat :: (s -> Bool) -> BaseParser k s ()
baseSat f = do
  s <- get
  guard (f s)

baseParse :: (Typeable s, Typeable t) => BaseParser k s t -> s -> [(t, s)]
baseParse p s = evalState idContState Map.empty
  where
    idContState = runCont (runStateT p s) (return . pure)
