class Aisweeper::RowsCreator
  def create(x : UInt8 = 10, y : UInt8 = 10, infested : UInt8 = 10)
    tiles = Aisweeper::TilesCreator.new(tiles: x * y, infested: infested).shuffled

    Array(Array(Aisweeper::Tile)).new(x) do
      Array(Aisweeper::Tile).new(y) { tiles.shift }
    end
  end
end
