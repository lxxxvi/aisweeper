class Aisweeper::RowsCreator
  def create(x : UInt8 = 10, y : UInt8 = 10, infested : UInt8 = 10)
    tiles = Aisweeper::TilesCreator.new(tiles: x.to_u16 * y.to_u16, infested: infested).shuffled

    Array(Array(Aisweeper::Tile)).new(y) do
      Array(Aisweeper::Tile).new(x) { tiles.shift }
    end
  end
end
