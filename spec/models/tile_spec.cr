require "../spec_helper"

describe Aisweeper::Tile do
  describe "infested?" do
    it "is not infested" do
      Aisweeper::Tile.new.infested?.should eq(false)
      Aisweeper::Tile.new(infested: false).infested?.should eq(false)
    end

    it "is infested?" do
      Aisweeper::Tile.new(infested: true).infested?.should eq(true)
    end
  end

  describe "infected?" do
    it "is not infected" do
      Aisweeper::Tile.new(infested: false, state: Aisweeper::Tile::State::Unexplored).infected?.should eq(false)
      Aisweeper::Tile.new(infested: false, state: Aisweeper::Tile::State::Flagged).infected?.should eq(false)
      Aisweeper::Tile.new(infested: false, state: Aisweeper::Tile::State::Questionmarked).infected?.should eq(false)
      Aisweeper::Tile.new(infested: false, state: Aisweeper::Tile::State::Explored).infected?.should eq(false)

      Aisweeper::Tile.new(infested: true, state: Aisweeper::Tile::State::Unexplored).infected?.should eq(false)
      Aisweeper::Tile.new(infested: true, state: Aisweeper::Tile::State::Flagged).infected?.should eq(false)
      Aisweeper::Tile.new(infested: true, state: Aisweeper::Tile::State::Questionmarked).infected?.should eq(false)
    end

    it "is infected" do
      Aisweeper::Tile.new(infested: true, state: Aisweeper::Tile::State::Explored).infected?.should eq(true)
    end
  end

  describe "state" do
    it "is unexplored" do
      Aisweeper::Tile.new.state.unexplored?.should eq(true)
      Aisweeper::Tile.new(state: Aisweeper::Tile::State::Unexplored).state.unexplored?.should eq(true)
    end

    it "is flagged" do
      Aisweeper::Tile.new(state: Aisweeper::Tile::State::Flagged).state.flagged?.should eq(true)
    end

    it "is questionmarked" do
      Aisweeper::Tile.new(state: Aisweeper::Tile::State::Questionmarked).state.questionmarked?.should eq(true)
    end

    it "is explored" do
      Aisweeper::Tile.new(state: Aisweeper::Tile::State::Explored).state.explored?.should eq(true)
    end
  end

  describe "mark!" do
    it "tests the cycle" do
      tile = Aisweeper::Tile.new

      tile.state.should eq(Aisweeper::Tile::State::Unexplored)
      tile.mark!
      tile.state.should eq(Aisweeper::Tile::State::Flagged)
      tile.mark!
      tile.state.should eq(Aisweeper::Tile::State::Questionmarked)
      tile.mark!
      tile.state.should eq(Aisweeper::Tile::State::Unexplored)
    end

    it "does nothing if the tile is explored" do
      tile = Aisweeper::Tile.new(state: Aisweeper::Tile::State::Explored)
      tile.mark!
      tile.state.should eq(Aisweeper::Tile::State::Explored)
    end
  end

  describe "#to_yaml" do
    tile = Aisweeper::Tile.new

    YAML.dump(tile).should eq("---\ninfested: false\nstate: Unexplored\n")
  end
end
