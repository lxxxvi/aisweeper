class Aisweeper::Board::Status
  STATUS_MAPPINGS = {
    "not_started" => {"icon" => "🆕", "label" => "Not started"},
    "ongoing"     => {"icon" => "⏳", "label" => "Ongoing"},
    "won"         => {"icon" => "🏆", "label" => "Won"},
    "lost"        => {"icon" => "🙁", "label" => "Lost"},
  }

  private getter board : Aisweeper::Board

  def initialize(@board : Aisweeper::Board)
  end

  def name
    find_name
  end

  def not_started?
    name == "not_started"
  end

  def ongoing?
    name == "ongoing"
  end

  def won?
    name == "won"
  end

  def lost?
    name == "lost"
  end

  def ended?
    lost? || won?
  end

  def icon
    STATUS_MAPPINGS.dig(name, "icon")
  end

  def label
    STATUS_MAPPINGS.dig(name, "label")
  end

  def render_as_output
    <<-HTML
    <output class="board-status board-status--#{name}">#{label} #{icon}</output>
    HTML
  end

  private def find_name
    return "lost" if any_infected?
    return "won" if all_uninfested_explored?
    return "ongoing" if any_explored?

    "not_started"
  end

  private def any_infected?
    board.rows.flatten.any?(&.infected?)
  end

  private def all_uninfested_explored?
    board.rows.flatten.reject(&.infested?).all? do |tile|
      tile.state.explored?
    end
  end

  private def any_explored?
    board.rows.flatten.any?(&.state.explored?)
  end
end
