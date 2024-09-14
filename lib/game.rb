require_relative 'board'

class Game
  attr_writer :board, :setup

  def initialize(board, setup = 'nil')
    self.board = board
    self.setup = setup
    board.print_board(board.board_array)
  end
end
