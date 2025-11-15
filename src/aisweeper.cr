require "kemal"
require "./models/tile.cr"
require "./models/tiles_creator.cr"
require "./models/board.cr"
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

post "/boards" do |env|
  board = Aisweeper::Board.find_or_create

  env.redirect "/boards/#{board.id}/"
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
