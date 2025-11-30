class Aisweeper::Board::Form
  DEFAULT_ROWS     = 10.to_u8
  DEFAULT_COLUMNS  = 10.to_u8
  DEFAULT_INFESTED = 10.to_u8

  getter errors : Array(String)
  getter rows : UInt8
  getter columns : UInt8
  getter infested : UInt8
  private getter storage_base_path : Path

  def initialize(@rows = DEFAULT_ROWS, @columns = DEFAULT_COLUMNS, @infested = DEFAULT_INFESTED, @storage_base_path = Aisweeper::BoardStore::DEFAULT_BASE_PATH)
    @errors = [] of String
  end

  def valid?
    validate
    errors.none?
  end

  def create_new_board
    Aisweeper::Board.find_or_create(x: columns, y: rows, infested: infested, storage_base_path: storage_base_path)
  end

  private def validate
    validate_rows
    validate_columns
    validate_infested
  end

  private def validate_rows
    if rows < 3
      errors << "Rows must be at least 3"
    elsif rows > 100
      errors << "Rows cannot be more than 100"
    end
  end

  private def validate_columns
    if columns < 3
      errors << "Columns must be at least 3"
    elsif columns > 100
      errors << "Columns cannot be more than 100"
    end
  end

  private def validate_infested
    return if errors.any?

    if infested < 1
      errors << "Infested must be at least 1"
    else
      maximum_infested = (rows.to_i16 * columns.to_i16) * 0.2

      if infested > maximum_infested
        errors << "Infested cannot be more than 20% (maximum #{maximum_infested.to_u8} for #{rows}x#{columns})"
      end
    end
  end
end
