{-# LANGUAGE OverloadedStrings #-}

module LambdaHeights.ReplayMenu where

import           Data.Either
import           Data.List
import qualified Data.Text                           as T
import           Data.Yaml
import qualified LambdaHeights.Menu                  as Menu
import           LambdaHeights.RenderContext
import           LambdaHeights.Resources
import qualified LambdaHeights.Table                 as Table
import qualified LambdaHeights.Types.ReplayMenuState as ReplayMenu
import qualified LambdaHeights.Types.ReplayState     as Replay
import qualified LambdaHeights.Types.Table           as Table
import qualified LambdaHeights.Types.Timer           as Timer
import qualified LambdaHeights.Types.Loop as Loop
import           Linear.V2
import qualified SDL
import           System.Directory

createConfig :: IO Menu.RenderConfig
createConfig = Menu.RenderConfig <$> retroGamingFont 11 <*> retroGamingFont 11

loadReplayFiles :: IO [Replay.Description]
loadReplayFiles = do
  fileNames <- filterPacked (T.isSuffixOf ".desc") <$> listDirectory "replays"
  let filePathes = map ("replays/" ++) fileNames
  sortBy (flip compare) . rights <$> mapM decodeFileEither filePathes

filterPacked :: (T.Text -> Bool) -> [String] -> [String]
filterPacked f = map T.unpack . filter f . map T.pack

buildTable :: [Replay.Description] -> Table.Table
buildTable xs =
  let texts    = tableHeader : ensureRows (map toList xs)
      selected = V2 2 1
  in  Table.newTable texts selected

toList :: Replay.Description -> [String]
toList x =
  let durationSec = realToFrac (Replay.duration x) / 1000 :: Float
  in  [ Replay.fileName x
      , show $ Replay.time x
      , show durationSec
      , show $ Replay.score x
      , show $ Replay.version x
      ]

tableHeader :: [String]
tableHeader = ["file path", "time", "duraction (sec)", "score", "version"]

ensureRows :: [[String]] -> [[String]]
ensureRows [] = [replicate 5 "n/a"]
ensureRows xs = xs

updateSelection :: Table.UpdateTable
updateSelection =
  Table.with Table.convertKeycode
    $ Table.applyKeycode
    $ Table.limitNotFirstRow
    $ Table.limitFirstColumn Table.limitAll

update :: Loop.Update ReplayMenu.State (Maybe String) [SDL.Event]
update timer events state =
  let updated = Menu.update updateSelection id events $ ReplayMenu.table state
  in  case updated of
        Left  result -> (timer, Left result)
        Right table  -> (timer, Right $ updateViewport $ state { ReplayMenu.table = table })

updateViewport :: ReplayMenu.State -> ReplayMenu.State
updateViewport state =
  let viewport = Table.updatePageViewport (ReplayMenu.table state) (ReplayMenu.viewport state)
  in  state { ReplayMenu.viewport = viewport }

render :: RenderContext -> Menu.RenderConfig -> Timer.LoopTimer -> ReplayMenu.State -> IO ()
render ctx config _ state = do
  let table    = ReplayMenu.table state
  let viewport = ReplayMenu.viewport state
  let table'   = Table.viewportTable viewport table
  view <- Table.newTableView (Menu.font config) table'
  Menu.render ctx config view
