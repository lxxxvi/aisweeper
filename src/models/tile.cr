require "yaml"

class Aisweeper::Tile
  enum State
    Unexplored
    Flagged
    Questionmarked
    Explored
  end

  getter infested : Bool
  getter state : State

  def initialize(@infested = false, @state = State::Unexplored)
  end

  def infested?
    infested
  end

  def unexplored?
    state.explored?
  end

  def flagged?
    state.flagged?
  end

  def questionmarked?
    state.questionmarked?
  end

  def explored?
    state.explored?
  end

  def infected?
    infested? && state.explored?
  end

  def explore!
    @state = State::Explored
  end

  def mark!
    return @state = State::Flagged if state.unexplored?
    return @state = State::Questionmarked if state.flagged?
    return @state = State::Unexplored if state.questionmarked?
  end

  def to_yaml
    YAML.build do |yaml|
      yaml.mapping do
        yaml.scalar "infested"
        yaml.scalar infested
        yaml.scalar "state"
        yaml.scalar state
      end
    end
  end
end
