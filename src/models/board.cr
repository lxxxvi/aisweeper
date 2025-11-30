class Aisweeper::Board
  getter id : String
  getter rows : Array(Array(Aisweeper::Tile))
  getter store : Aisweeper::BoardStore

  def initialize(@id : String, @rows : Array(Array(Aisweeper::Tile)), @store : Aisweeper::BoardStore)
  end

  def self.all(storage_base_path : Path = Aisweeper::BoardStore::DEFAULT_BASE_PATH)
    Dir.children(storage_base_path).map do |child|
      find_or_create(id: child, storage_base_path: storage_base_path)
    end.sort_by do |board|
      board.id
    end
  end

  def self.find(id : String, storage_base_path : Path = Aisweeper::BoardStore::DEFAULT_BASE_PATH)
    store = Aisweeper::BoardStore.new(id: id, storage_base_path: storage_base_path)

    self.new(id: id, rows: store.load, store: store)
  end

  def self.find_or_create(id = Random.new.hex(3), x : UInt8 = 10, y : UInt8 = 10, infested : UInt8 = 10, storage_base_path : Path = Aisweeper::BoardStore::DEFAULT_BASE_PATH)
    store = Aisweeper::BoardStore.new(id: id, storage_base_path: storage_base_path)

    rows = if File.exists?(store.board_file_path)
             store.load
           else
             new_rows = Aisweeper::RowsCreator.new.create(x: x, y: y, infested: infested)
             store.save(new_rows)
             new_rows
           end

    self.new(id: id, rows: rows, store: store)
  end

  def delete
    store.delete
  end

  def status
    Aisweeper::Board::Status.new(board: self)
  end

  def stats
    Aisweeper::Board::Stats.new(board: self).call
  end

  def left_click(x : Int8, y : Int8)
    return if status.ended?

    target_tile = rows[y][x]

    return if target_tile.flagged? || target_tile.questionmarked?

    target_tile.explore!
    cascade_explore_neighborhood(x: x, y: y, start_of_cycle: true)
    store.save(rows)
  end

  private def cascade_explore_neighborhood(x : Int8, y : Int8, start_of_cycle : Bool = false)
    root_tile = tile_at(x: x, y: y)

    if root_tile
      return if root_tile.infected?

      if !start_of_cycle
        return if root_tile.state.explored?
        return if root_tile.infested?

        root_tile.explore!
      end

      return if neighbouring_infested_tiles(x: x, y: y).any?

      cascade_explore_neighborhood(x: x - 1, y: y - 1)
      cascade_explore_neighborhood(x: x, y: y - 1)
      cascade_explore_neighborhood(x: x + 1, y: y - 1)
      cascade_explore_neighborhood(x: x - 1, y: y)
      cascade_explore_neighborhood(x: x + 1, y: y)
      cascade_explore_neighborhood(x: x - 1, y: y + 1)
      cascade_explore_neighborhood(x: x, y: y + 1)
      cascade_explore_neighborhood(x: x + 1, y: y + 1)
    end
  end

  def right_click(x : Int8, y : Int8)
    tile = tile_at(x: x, y: y)

    if tile
      tile.mark!
      store.save(rows)
    end
  end

  def tile_at(x : Int8, y : Int8)
    return nil if x < 0             # left side out of bound
    return nil if y < 0             # top side out of bound
    return nil if x >= rows[0].size # right side out of bound
    return nil if y >= rows.size    # bottom side out of bound

    rows[y][x]
  end

  def neighbouring_tiles(x : Int8, y : Int8)
    [
      tile_at(x - 1, y - 1), # nw
      tile_at(x, y - 1),     # nn
      tile_at(x + 1, y - 1), # ne
      tile_at(x - 1, y),     # ww
      tile_at(x + 1, y),     # ee
      tile_at(x - 1, y + 1), # sw
      tile_at(x, y + 1),     # ss
      tile_at(x + 1, y + 1), # se
    ].compact
  end

  def neighbouring_infested_tiles(x : Int8, y : Int8)
    neighbouring_tiles(x: x, y: y).select &.infested?
  end
end
