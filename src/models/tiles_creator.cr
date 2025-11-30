class Aisweeper::TilesCreator
  getter tiles : UInt16
  getter infested : UInt8

  def initialize(@tiles = 100, @infested = 10)
    raise ArgumentError.new("Too few AIs") if infested <= 0
    raise ArgumentError.new("Too many AIs") if infested >= tiles
  end

  def shuffled
    all_tiles.shuffle
  end

  private def all_tiles
    infested_tiles.concat(clean_tiles)
  end

  private def infested_tiles
    Array(Aisweeper::Tile).new(infested) { Aisweeper::Tile.new(infested: true) }
  end

  private def clean_tiles
    Array(Aisweeper::Tile).new(tiles - infested) { Aisweeper::Tile.new(infested: false) }
  end
end
