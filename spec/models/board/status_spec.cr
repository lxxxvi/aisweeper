require "../../spec_helper"

describe Aisweeper::Board::Status do
  it "not_started" do
    with_tempdir do |tempdir|
      rows = [
        [
          Aisweeper::Tile.new,
          Aisweeper::Tile.new,
        ],
        [
          Aisweeper::Tile.new,
          Aisweeper::Tile.new,
        ],
      ]

      board_store = Aisweeper::BoardStore.new(id: "2x2", storage_base_path: tempdir)
      board = Aisweeper::Board.new(id: "2x2", rows: rows, store: board_store)

      service = Aisweeper::Board::Status.new(board: board)

      service.name.should eq("not_started")
      service.not_started?.should eq(true)
      service.ongoing?.should eq(false)
      service.won?.should eq(false)
      service.lost?.should eq(false)
      service.ended?.should eq(false)
      service.icon.should eq("🆕")
      service.label.should eq("Not started")
      service.render_as_output.should eq("<output class=\"board-status board-status--not_started\">Not started 🆕</output>")
    end
  end

  it "ongoing" do
    with_tempdir do |tempdir|
      rows = [
        [
          Aisweeper::Tile.new(infested: true),
          Aisweeper::Tile.new(state: Aisweeper::Tile::State::Explored),
        ],
        [
          Aisweeper::Tile.new,
          Aisweeper::Tile.new,
        ],
      ]

      board_store = Aisweeper::BoardStore.new(id: "2x2", storage_base_path: tempdir)
      board = Aisweeper::Board.new(id: "2x2", rows: rows, store: board_store)

      service = Aisweeper::Board::Status.new(board: board)

      service.name.should eq("ongoing")
      service.not_started?.should eq(false)
      service.ongoing?.should eq(true)
      service.won?.should eq(false)
      service.lost?.should eq(false)
      service.ended?.should eq(false)
      service.icon.should eq("⏳")
      service.label.should eq("Ongoing")
      service.render_as_output.should eq("<output class=\"board-status board-status--ongoing\">Ongoing ⏳</output>")
    end
  end

  it "won" do
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

      service = Aisweeper::Board::Status.new(board: board)

      service.name.should eq("won")
      service.not_started?.should eq(false)
      service.ongoing?.should eq(false)
      service.won?.should eq(true)
      service.lost?.should eq(false)
      service.ended?.should eq(true)
      service.icon.should eq("🏆")
      service.label.should eq("Won")
      service.render_as_output.should eq("<output class=\"board-status board-status--won\">Won 🏆</output>")
    end
  end

  it "lost" do
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

      service = Aisweeper::Board::Status.new(board: board)

      service.name.should eq("lost")
      service.not_started?.should eq(false)
      service.ongoing?.should eq(false)
      service.won?.should eq(false)
      service.lost?.should eq(true)
      service.ended?.should eq(true)
      service.icon.should eq("🙁")
      service.label.should eq("Lost")
      service.render_as_output.should eq("<output class=\"board-status board-status--lost\">Lost 🙁</output>")
    end
  end
end
