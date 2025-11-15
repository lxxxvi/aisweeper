describe Aisweeper::TilesCreator do
  describe ".new" do
    it "raises if there are too many AIs" do
      ex = expect_raises(ArgumentError) do
        Aisweeper::TilesCreator.new(tiles: 4, infested: 4)
      end

      ex.message.should eq("Too many AIs")
    end

    it "raises if there are too few AIs" do
      ex = expect_raises(ArgumentError) do
        Aisweeper::TilesCreator.new(tiles: 4, infested: 0)
      end

      ex.message.should eq("Too few AIs")
    end
  end

  describe "#shuffled" do
    it "creates the tiles" do
      tiles_creator = Aisweeper::TilesCreator.new(tiles: 10, infested: 2)
      tiles = tiles_creator.shuffled

      tiles.size.should eq(10)
      tiles.count { |tile| tile.infested }.should eq(2)
      tiles.count { |tile| !tile.infested }.should eq(8)
    end
  end
end
