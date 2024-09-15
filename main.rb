require_relative 'lib/game'
require_relative 'lib/board'
require 'pry-byebug'

board = Board.new('default')
game = Game.new(board)
