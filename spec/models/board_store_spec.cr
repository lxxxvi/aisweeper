describe Aisweeper::BoardStore do
  context "#save" do
    it "saves the rows to file" do
      with_tempdir do |tempdir|
        board_store = Aisweeper::BoardStore.new(id: "wow", storage_base_path: tempdir)

        rows = [
          [
            Aisweeper::Tile.new(state: Aisweeper::Tile::State::Explored),
            Aisweeper::Tile.new(infested: true),
          ],
          [
            Aisweeper::Tile.new,
            Aisweeper::Tile.new,
          ],
        ]

        board_store.save(rows: rows)

        expected_yml = <<-YML
        ---
        - - infested: false
            state: Explored
          - infested: true
            state: Unexplored
        - - infested: false
            state: Unexplored
          - infested: false
            state: Unexplored

        YML

        File.read(Path[tempdir].join("wow/data.yml")).should eq(expected_yml)
      end
    end
  end

  context "#load" do
    it "load a file" do
      with_temp_fixture("boards/4x4/data.yml") do |_temp_fixture_file, tempdir|
        board_store = Aisweeper::BoardStore.new(id: "4x4", storage_base_path: tempdir.join("boards"))

        rows = board_store.load

        rows.size.should eq(4)
        rows[0][0].infested.should eq(true)
        rows[0][1].infested.should eq(false)
        rows[1][0].infested.should eq(true)
        rows[1][1].infested.should eq(false)

        rows[0][0].state.should eq(Aisweeper::Tile::State::Flagged)
        rows[0][1].state.should eq(Aisweeper::Tile::State::Questionmarked)
        rows[1][0].state.should eq(Aisweeper::Tile::State::Unexplored)
        rows[1][1].state.should eq(Aisweeper::Tile::State::Explored)
      end
    end
  end
end
