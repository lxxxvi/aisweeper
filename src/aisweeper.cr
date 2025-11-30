require "kemal"
require "./models/tile.cr"
require "./models/tiles_creator.cr"
require "./models/board.cr"
require "./models/board/form.cr"
require "./models/board/stats.cr"
require "./models/board/status.cr"
require "./models/board_store.cr"
require "./models/rows_creator.cr"

get "/" do
  boards = Aisweeper::Board.all
  render "src/views/boards/index.ecr", "src/views/layouts/layout.ecr"
end

get "/boards/:id/" do |env|
  board = Aisweeper::Board.find(id: env.params.url["id"])
  render "src/views/boards/show.ecr", "src/views/layouts/layout.ecr"
end

get "/boards/new" do |env|
  form = Aisweeper::Board::Form.new
  render "src/views/boards/new.ecr", "src/views/layouts/layout.ecr"
end

post "/boards" do |env|
  form = Aisweeper::Board::Form.new(
    rows: env.params.body["rows"].to_u8,
    columns: env.params.body["columns"].to_u8,
    infested: env.params.body["infested"].to_u8
  )

  if form.valid?
    board = form.create_new_board
    env.redirect "/boards/#{board.id}/"
  else
    render "src/views/boards/new.ecr", "src/views/layouts/layout.ecr"
  end
end

post "/boards/:id" do |env|
  http_method = env.params.body["_method"]

  if http_method.downcase == "delete"
    board = Aisweeper::Board.find(id: env.params.url["id"])
    board.delete
    env.redirect "/"
  end
end

post "/boards/:id/tile/:coordinates" do |env|
  x, y = env.params.url["coordinates"].as(String).split(",").map &.to_i8
  action = env.params.body["action"]
  board = Aisweeper::Board.find(id: env.params.url["id"])

  if action == "left"
    board.left_click(x: x, y: y)
  else
    board.right_click(x: x, y: y)
  end

  env.redirect "/boards/#{board.id}/"
end

Kemal.run
