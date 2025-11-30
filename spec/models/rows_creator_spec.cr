require "../spec_helper"

describe Aisweeper::RowsCreator do
  it "#create" do
    rows = Aisweeper::RowsCreator.new.create(x: 4, y: 5, infested: 6)

    rows.size.should eq(5)
    rows.first.size.should eq(4)
    rows.flatten.count(&.infested?).should eq(6)
  end
end
