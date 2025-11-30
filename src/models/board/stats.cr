class Aisweeper::Board::Stats
  private getter board : Aisweeper::Board

  def initialize(@board : Aisweeper::Board)
  end

  def call
    {
      rows:           rows,
      columns:        columns,
      total_cells:    total_cells,
      infested:       infested,
      infested_ratio: infested_ratio,
      explored_ratio: explored_ratio,
      flagged:        flagged,
    }
  end

  private def rows
    board.rows.size
  end

  private def columns
    board.rows.first.size
  end

  private def total_cells
    rows * columns
  end

  private def infested
    board.rows.flatten.count(&.infested?)
  end

  private def infested_ratio
    100.0 * infested / total_cells
  end

  private def explored_ratio
    100.0 * board.rows.flatten.count(&.explored?) / (total_cells - infested)
  end

  private def flagged
    board.rows.flatten.count(&.flagged?)
  end
end
