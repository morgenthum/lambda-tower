module SDL.GUI.Table.Types where

import           Data.Matrix
import           Data.Word
import           Linear.V2
import           Linear.V4
import qualified SDL.Font    as SDLF

type Color = V4 Word8
type DataMatrix = Matrix String

data Table = Table {
  content  :: DataMatrix,
  selected :: V2 Int
}

data CellStyle = CellStyle {
  cellFont :: SDLF.Font,
  cellBg   :: Color,
  cellFg   :: Color
}

tableDimension :: Table -> (Int, Int)
tableDimension table = let m = content table in (nrows m, ncols m)
