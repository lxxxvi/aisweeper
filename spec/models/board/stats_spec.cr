require "../../spec_helper"

describe Aisweeper::Board::Stats do
  context "#call" do
    it "contains rows, columns, total_cells, infested, infested_ratio, explored_ratio, questionmarked" do
      with_temp_fixture("boards/4x4/data.yml") do |_temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("4x4", storage_base_path: tempdir.join("boards"))
        stats = Aisweeper::Board::Stats.new(board: board).call

        stats["rows"].should eq(4)
        stats["columns"].should eq(4)
        stats["total_cells"].should eq(16)
        stats["infested"].should eq(2)
        stats["infested_ratio"].should eq(12.5)
        stats["explored_ratio"].should eq(7.142857142857143)
        stats["flagged"].should eq(1)
      end
    end
  end
end
