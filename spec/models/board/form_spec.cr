require "../../spec_helper"

describe Aisweeper::Board::Form do
  context "#valid?" do
    it "is valid" do
      form = Aisweeper::Board::Form.new(rows: 10, columns: 10, infested: 10)
      form.valid?.should eq(true)
      form.errors.should eq([] of String)
    end

    it "rows is too little" do
      form = Aisweeper::Board::Form.new(rows: 2, columns: 10, infested: 10)
      form.valid?.should eq(false)
      form.errors.should eq(["Rows must be at least 3"])
    end

    it "columns is too little" do
      form = Aisweeper::Board::Form.new(rows: 10, columns: 2, infested: 10)
      form.valid?.should eq(false)
      form.errors.should eq(["Columns must be at least 3"])
    end

    it "infested is too little" do
      form = Aisweeper::Board::Form.new(rows: 10, columns: 10, infested: 0)
      form.valid?.should eq(false)
      form.errors.should eq(["Infested must be at least 1"])
    end

    it "rows is too much" do
      form = Aisweeper::Board::Form.new(rows: 101, columns: 10, infested: 10)
      form.valid?.should eq(false)
      form.errors.should eq(["Rows cannot be more than 100"])
    end

    it "columns is too much" do
      form = Aisweeper::Board::Form.new(rows: 10, columns: 101, infested: 10)
      form.valid?.should eq(false)
      form.errors.should eq(["Columns cannot be more than 100"])
    end

    it "infested is too much" do
      form = Aisweeper::Board::Form.new(rows: 10, columns: 10, infested: 21)
      form.valid?.should eq(false)
      form.errors.should eq(["Infested cannot be more than 20% (maximum 20 for 10x10)"])
    end
  end

  context "#rows, #columns, #infested" do
    it "works" do
      form = Aisweeper::Board::Form.new(rows: 12, columns: 13, infested: 14)
      form.rows.should eq(12)
      form.columns.should eq(13)
      form.infested.should eq(14)
    end
  end

  context "#create_new_board" do
    with_tempdir do |tempdir|
      form = Aisweeper::Board::Form.new(rows: 15, columns: 16, infested: 17, storage_base_path: tempdir)

      board = form.create_new_board

      board.rows.size.should eq(15)
      board.rows.first.size.should eq(16)
      board.rows.flatten.count(&.infested?).should eq(17)
    end
  end
end
