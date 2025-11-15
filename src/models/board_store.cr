require "yaml"

class Aisweeper::BoardStore
  DEFAULT_BASE_PATH = Path["./storage/boards"]
  DEFAULT_FILE_NAME = Path["data.yml"]

  getter storage_base_path : Path
  getter id : String

  def initialize(@id = Random.new.hex(3), @storage_base_path : Path = DEFAULT_BASE_PATH)
  end

  def save(rows : Array(Array(Aisweeper::Tile)))
    Dir.mkdir_p(board_file_path.dirname)
    File.write(board_file_path, rows_to_yaml(rows: rows))
  end

  def load
    yaml_content = File.read(board_file_path)

    YAML.parse(yaml_content).as_a.map do |rows|
      rows.as_a.map do |tile|
        infested = tile["infested"].as_bool
        state = Aisweeper::Tile::State.parse(tile["state"].as_s)
        Aisweeper::Tile.new(infested: infested, state: state)
      end
    end
  end

  def board_file_path
    storage_base_path.join(id, DEFAULT_FILE_NAME)
  end

  private def rows_to_yaml(rows : Array(Array(Aisweeper::Tile)))
    YAML.build do |yaml|
      yaml.sequence do
        rows.map do |row|
          yaml.sequence do
            row.map do |tile|
              yaml.mapping do
                yaml.scalar("infested")
                yaml.scalar(tile.infested)
                yaml.scalar("state")
                yaml.scalar(tile.state)
              end
            end
          end
        end
      end
    end
  end
end
