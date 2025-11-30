require "../spec_helper"
require "file_utils"

describe Aisweeper::Board do
  context ".all" do
    it "gets all boards available in storage" do
      with_tempdir do |tempdir|
        ccc_board = Aisweeper::Board.find_or_create(id: "ccc", x: 3, y: 3, infested: 3, storage_base_path: tempdir)
        bbb_board = Aisweeper::Board.find_or_create(id: "bbb", x: 3, y: 3, infested: 3, storage_base_path: tempdir)
        aaa_board = Aisweeper::Board.find_or_create(id: "aaa", x: 3, y: 3, infested: 3, storage_base_path: tempdir)

        all_boards = Aisweeper::Board.all(storage_base_path: tempdir)

        all_boards.size.should eq(3)
        all_boards[0].id.should eq("aaa")
        all_boards[1].id.should eq("bbb")
        all_boards[2].id.should eq("ccc")
      end
    end
  end

  context ".find" do
    it "laods the board if exists" do
      with_temp_fixture("boards/4x4/data.yml") do |_temp_fixture_file, tempdir|
        board = Aisweeper::Board.find(id: "4x4", storage_base_path: tempdir.join("boards"))

        board.rows.size.should eq(4)
        board.rows[0].size.should eq(4)
      end
    end

    it "raises if the board does not exist" do
      with_tempdir do |tempdir|
        ex = expect_raises(File::NotFoundError) do
          Aisweeper::Board.find(id: "4x4", storage_base_path: tempdir)
        end

        ex.message.should match(/^Error opening file with mode 'r'/)
      end
    end
  end

  context ".find_or_create" do
    it "creates a new file" do
      with_tempdir do |tempdir|
        board = Aisweeper::Board.find_or_create(id: "xyz", x: 4, y: 4, infested: 3, storage_base_path: tempdir)

        expected_file_path = tempdir.join("xyz/data.yml")

        File.exists?(expected_file_path).should eq(true)
        board.id.should eq("xyz")
        board.rows.size.should eq(4)
      end
    end

    it "loads from file" do
      with_temp_fixture("boards/4x4/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("4x4", storage_base_path: tempdir.join("boards"))

        board.id.should eq("4x4")
        board.rows.size.should eq(4)
        board.rows[0][0].infested.should eq(true)
        board.rows[0][1].infested.should eq(false)
        board.rows[1][0].infested.should eq(true)
        board.rows[1][1].infested.should eq(false)

        board.rows[0][0].state.should eq(Aisweeper::Tile::State::Flagged)
        board.rows[0][1].state.should eq(Aisweeper::Tile::State::Questionmarked)
        board.rows[1][0].state.should eq(Aisweeper::Tile::State::Unexplored)
        board.rows[1][1].state.should eq(Aisweeper::Tile::State::Explored)
      end
    end
  end

  context "#delete" do
    it "deletes a board" do
      with_temp_fixture("boards/4x4/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("4x4", storage_base_path: tempdir.join("boards"))

        File.exists?(tempdir.join("boards/4x4")).should eq(true)
        File.exists?(tempdir.join("boards")).should eq(true)
        board.delete
        File.exists?(tempdir.join("boards")).should eq(true)
        File.exists?(tempdir.join("boards/4x4")).should eq(false)
      end
    end
  end

  context "#left_click" do
    it "infects if infested" do
      with_temp_fixture("boards/3x3/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("3x3", storage_base_path: tempdir.join("boards"))

        board.status.lost?.should eq(false)
        board.rows[1][1].infected?.should eq(false)
        board.left_click(x: 1, y: 1)
        board.rows[1][1].infected?.should eq(true)
        board.status.lost?.should eq(true)

        board.rows[0].map(&.state.explored?).should eq([false, false, false])
        board.rows[1].map(&.state.explored?).should eq([false, true, false])
        board.rows[2].map(&.state.explored?).should eq([false, false, false])
      end
    end

    it "explores itself and none in neighborhood" do
      with_temp_fixture("boards/3x3/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("3x3", storage_base_path: tempdir.join("boards"))

        board.status.lost?.should eq(false)
        board.left_click(x: 0, y: 0)
        board.status.lost?.should eq(false)

        board.rows[0].map(&.state.explored?).should eq([true, false, false])
        board.rows[1].map(&.state.explored?).should eq([false, false, false])
        board.rows[2].map(&.state.explored?).should eq([false, false, false])
      end
    end

    it "explores itself and some neighborhood" do
      with_temp_fixture("boards/3x3/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("3x3", storage_base_path: tempdir.join("boards"))

        # relocate infested tile from CE to SE
        board.rows[1][1] = Aisweeper::Tile.new(infested: false)
        board.rows[2][2] = Aisweeper::Tile.new(infested: true)

        board.left_click(x: 0, y: 0)

        board.rows[0].map(&.state.explored?).should eq([true, true, true])
        board.rows[1].map(&.state.explored?).should eq([true, true, true])
        board.rows[2].map(&.state.explored?).should eq([true, true, false])

        board.status.won?.should eq(true)
      end
    end

    it "ignores click when flagged or questionmarked" do
      with_tempdir do |tempdir|
        rows = [
          [
            Aisweeper::Tile.new(state: Aisweeper::Tile::State::Flagged),
            Aisweeper::Tile.new,
          ],
          [
            Aisweeper::Tile.new,
            Aisweeper::Tile.new(infested: true),
          ],
        ]

        board_store = Aisweeper::BoardStore.new(id: "2x2", storage_base_path: tempdir)
        board = Aisweeper::Board.new(id: "2x2", rows: rows, store: board_store)

        board.rows[0].map(&.state.explored?).should eq([false, false])
        board.rows[1].map(&.state.explored?).should eq([false, false])

        board.left_click(x: 0, y: 0)

        board.rows[0].map(&.state.explored?).should eq([false, false])
        board.rows[1].map(&.state.explored?).should eq([false, false])

        board.rows[0][0] = Aisweeper::Tile.new(state: Aisweeper::Tile::State::Questionmarked)

        board.left_click(x: 0, y: 0)

        board.rows[0].map(&.state.explored?).should eq([false, false])
        board.rows[1].map(&.state.explored?).should eq([false, false])
      end
    end

    it "ignores click when won" do
      with_tempdir do |tempdir|
        rows = [
          [
            Aisweeper::Tile.new(infested: true),
            Aisweeper::Tile.new(state: Aisweeper::Tile::State::Explored),
          ],
          [
            Aisweeper::Tile.new(state: Aisweeper::Tile::State::Explored),
            Aisweeper::Tile.new(state: Aisweeper::Tile::State::Explored),
          ],
        ]

        board_store = Aisweeper::BoardStore.new(id: "2x2", storage_base_path: tempdir)
        board = Aisweeper::Board.new(id: "2x2", rows: rows, store: board_store)

        board.status.won?.should eq(true)

        board.rows[0].map(&.state.explored?).should eq([false, true])
        board.rows[1].map(&.state.explored?).should eq([true, true])

        board.left_click(x: 0, y: 0)

        board.rows[0].map(&.state.explored?).should eq([false, true])
        board.rows[1].map(&.state.explored?).should eq([true, true])
      end
    end

    it "ignores click when lost" do
      with_tempdir do |tempdir|
        rows = [
          [
            Aisweeper::Tile.new(infested: true, state: Aisweeper::Tile::State::Explored),
            Aisweeper::Tile.new,
          ],
          [
            Aisweeper::Tile.new,
            Aisweeper::Tile.new,
          ],
        ]

        board_store = Aisweeper::BoardStore.new(id: "2x2", storage_base_path: tempdir)
        board = Aisweeper::Board.new(id: "2x2", rows: rows, store: board_store)

        board.status.lost?.should eq(true)

        board.rows[0].map(&.state.explored?).should eq([true, false])
        board.rows[1].map(&.state.explored?).should eq([false, false])

        board.left_click(x: 0, y: 0)

        board.rows[0].map(&.state.explored?).should eq([true, false])
        board.rows[1].map(&.state.explored?).should eq([false, false])
      end
    end
  end

  #  ↖️ NW | ⬆️ NN | ↗️ NE
  #  ⬅️ WW | ⏺️ CE | ➡️ EE
  #  ↙️ SW | ⬇️ SS | ↘️ SE
  context "#neighbouring_tiles" do
    it "checks every constellation on a 3x3 field" do
      with_temp_fixture("boards/3x3/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("3x3", storage_base_path: tempdir.join("boards"))

        tile_nw, tile_nn, tile_ne = board.rows[0]
        tile_ww, tile_ce, tile_ee = board.rows[1]
        tile_sw, tile_ss, tile_se = board.rows[2]

        # root tile is in NW
        neighbouring_tiles = board.neighbouring_tiles(x: 0, y: 0)
        neighbouring_tiles.size.should eq(3)
        neighbouring_tiles.should contain(tile_nn)
        neighbouring_tiles.should contain(tile_ww)
        neighbouring_tiles.should contain(tile_ce)

        # root tile is in NN
        neighbouring_tiles = board.neighbouring_tiles(x: 1, y: 0)
        neighbouring_tiles.size.should eq(5)
        neighbouring_tiles.should contain(tile_nw)
        neighbouring_tiles.should contain(tile_ne)
        neighbouring_tiles.should contain(tile_ww)
        neighbouring_tiles.should contain(tile_ce)
        neighbouring_tiles.should contain(tile_ee)

        # root tile is in NE
        neighbouring_tiles = board.neighbouring_tiles(x: 2, y: 0)
        neighbouring_tiles.size.should eq(3)
        neighbouring_tiles.should contain(tile_nn)
        neighbouring_tiles.should contain(tile_ce)
        neighbouring_tiles.should contain(tile_ee)

        # root tile is in WW
        neighbouring_tiles = board.neighbouring_tiles(x: 0, y: 1)
        neighbouring_tiles.size.should eq(5)
        neighbouring_tiles.should contain(tile_nw)
        neighbouring_tiles.should contain(tile_nn)
        neighbouring_tiles.should contain(tile_ce)
        neighbouring_tiles.should contain(tile_sw)
        neighbouring_tiles.should contain(tile_ss)

        # root tile is in CE
        neighbouring_tiles = board.neighbouring_tiles(x: 1, y: 1)
        neighbouring_tiles.size.should eq(8)
        neighbouring_tiles.should contain(tile_nw)
        neighbouring_tiles.should contain(tile_nn)
        neighbouring_tiles.should contain(tile_ne)
        neighbouring_tiles.should contain(tile_ww)
        neighbouring_tiles.should contain(tile_ee)
        neighbouring_tiles.should contain(tile_sw)
        neighbouring_tiles.should contain(tile_ss)
        neighbouring_tiles.should contain(tile_se)

        # root tile is in EE
        neighbouring_tiles = board.neighbouring_tiles(x: 2, y: 1)
        neighbouring_tiles.size.should eq(5)
        neighbouring_tiles.should contain(tile_nn)
        neighbouring_tiles.should contain(tile_ne)
        neighbouring_tiles.should contain(tile_ce)
        neighbouring_tiles.should contain(tile_ss)
        neighbouring_tiles.should contain(tile_se)

        # root tile is in SW
        neighbouring_tiles = board.neighbouring_tiles(x: 0, y: 2)
        neighbouring_tiles.size.should eq(3)
        neighbouring_tiles.should contain(tile_ww)
        neighbouring_tiles.should contain(tile_ce)
        neighbouring_tiles.should contain(tile_ss)

        # root tile is in SS
        neighbouring_tiles = board.neighbouring_tiles(x: 1, y: 2)
        neighbouring_tiles.size.should eq(5)
        neighbouring_tiles.should contain(tile_ww)
        neighbouring_tiles.should contain(tile_ce)
        neighbouring_tiles.should contain(tile_ee)
        neighbouring_tiles.should contain(tile_sw)
        neighbouring_tiles.should contain(tile_se)

        # root tile is in SE
        neighbouring_tiles = board.neighbouring_tiles(x: 2, y: 2)
        neighbouring_tiles.size.should eq(3)
        neighbouring_tiles.should contain(tile_ce)
        neighbouring_tiles.should contain(tile_ee)
        neighbouring_tiles.should contain(tile_ss)
      end
    end

    it "a root tile centered in a 4x4, should yield exact 8 fields" do
      with_temp_fixture("boards/3x3/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("4x4", storage_base_path: tempdir.join("boards"))

        neighbouring_tiles = board.neighbouring_tiles(x: 2, y: 2)
        neighbouring_tiles.size.should eq(8)
        neighbouring_tiles.should contain(board.rows[1][1])
        neighbouring_tiles.should contain(board.rows[1][2])
        neighbouring_tiles.should contain(board.rows[1][3])
        neighbouring_tiles.should contain(board.rows[2][1])
        neighbouring_tiles.should contain(board.rows[2][3])
        neighbouring_tiles.should contain(board.rows[3][1])
        neighbouring_tiles.should contain(board.rows[3][2])
        neighbouring_tiles.should contain(board.rows[3][3])
      end
    end
  end

  context "#neighbouring_infested_tiles" do
    it "checks every constellation on a 3x3 field" do
      with_temp_fixture("boards/3x3/data.yml") do |temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("3x3", storage_base_path: tempdir.join("boards"))

        # reset board

        # ⬜️⬜️⬜️
        # ⬜️⬜️⬜️
        # ⬜️⬜️⬜️

        board.rows[1][1] = Aisweeper::Tile.new(infested: false)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(0)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(0)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(0)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(0)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(0)

        # 🎈1️⃣⬜️
        # 1️⃣1️⃣⬜️
        # ⬜️⬜️⬜️

        board.rows[0][0] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(1)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(0)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(1)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(0)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(0)

        # 🎈🎈1️⃣
        # 2️⃣2️⃣1️⃣
        # ⬜️⬜️⬜️

        board.rows[0][1] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(1)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(1)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(1)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(0)

        # 🎈🎈🎈
        # 2️⃣3️⃣2️⃣
        # ⬜️⬜️⬜️

        board.rows[0][2] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(1)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(3)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(0)

        # 🎈🎈🎈
        # 🎈4️⃣2️⃣
        # 1️⃣1️⃣⬜️

        board.rows[1][0] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(3)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(1)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(1)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(0)

        # 🎈🎈🎈
        # 🎈5️⃣🎈
        # 1️⃣2️⃣1️⃣

        board.rows[1][2] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(5)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(1)

        # 🎈🎈🎈
        # 🎈6️⃣🎈
        # 🎈3️⃣1️⃣

        board.rows[2][0] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(3)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(6)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(3)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(1)

        # 🎈🎈🎈
        # 🎈7️⃣🎈
        # 🎈🎈2️⃣

        board.rows[2][1] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(4)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(7)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(3)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(3)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(2)

        # 🎈🎈🎈
        # 🎈8️⃣🎈
        # 🎈🎈🎈

        board.rows[2][2] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(4)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(8)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(4)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(2)

        # 2️⃣🎈2️⃣
        # 🎈4️⃣🎈
        # 2️⃣🎈2️⃣

        board.rows[0][0] = Aisweeper::Tile.new(infested: false)
        board.rows[0][2] = Aisweeper::Tile.new(infested: false)
        board.rows[1][1] = Aisweeper::Tile.new(infested: false)
        board.rows[2][0] = Aisweeper::Tile.new(infested: false)
        board.rows[2][2] = Aisweeper::Tile.new(infested: false)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(2)

        # 🎈🎈2️⃣
        # 🎈5️⃣🎈
        # 2️⃣🎈2️⃣

        board.rows[0][0] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(3)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(3)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(5)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(2)

        # 🎈🎈2️⃣
        # 🎈6️⃣🎈
        # 2️⃣🎈🎈

        board.rows[2][2] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(3)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(3)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(6)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(3)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(3)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(2)

        # 🎈4️⃣🎈
        # 🎈6️⃣🎈
        # 🎈4️⃣🎈

        board.rows[0][1] = Aisweeper::Tile.new(infested: false)
        board.rows[0][2] = Aisweeper::Tile.new(infested: true)
        board.rows[2][0] = Aisweeper::Tile.new(infested: true)
        board.rows[2][1] = Aisweeper::Tile.new(infested: false)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(1)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(6)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(1)

        # 🎈2️⃣🎈
        # 2️⃣4️⃣2️⃣
        # 🎈2️⃣🎈

        board.rows[1][0] = Aisweeper::Tile.new(infested: false)
        board.rows[1][2] = Aisweeper::Tile.new(infested: false)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(0)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(2)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(4)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(2)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(0)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(0)

        # 🎈🎈🎈
        # 4️⃣6️⃣4️⃣
        # 🎈🎈🎈

        board.rows[0][1] = Aisweeper::Tile.new(infested: true)
        board.rows[2][1] = Aisweeper::Tile.new(infested: true)

        board.neighbouring_infested_tiles(x: 0, y: 0).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 0).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 0).size.should eq(1)

        board.neighbouring_infested_tiles(x: 0, y: 1).size.should eq(4)
        board.neighbouring_infested_tiles(x: 1, y: 1).size.should eq(6)
        board.neighbouring_infested_tiles(x: 2, y: 1).size.should eq(4)

        board.neighbouring_infested_tiles(x: 0, y: 2).size.should eq(1)
        board.neighbouring_infested_tiles(x: 1, y: 2).size.should eq(2)
        board.neighbouring_infested_tiles(x: 2, y: 2).size.should eq(1)
      end
    end
  end

  context "stats" do
    it "contains rows, columns, total_cells, infested, infested_ratio, explored_ratio, questionmarked" do
      with_temp_fixture("boards/4x4/data.yml") do |_temp_fixture_file, tempdir|
        board = Aisweeper::Board.find_or_create("4x4", storage_base_path: tempdir.join("boards"))
        stats = board.stats

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
