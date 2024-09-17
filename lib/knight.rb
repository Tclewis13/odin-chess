require_relative 'piece'
require 'pry-byebug'

class Knight < Piece
  attr_accessor :color, :spawn_pos, :move_set, :symbol

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.symbol = 'N'
  end

  def get_moves(board_array)
    legal_moves = []
    move_set.each do |offset|
      possible_move = []
      possible_move[0] = current_pos[0] + offset[0]
      possible_move[1] = current_pos[1] + offset[1]
      if possible_move[0].between?(0, 7) && possible_move[1].between?(0, 7)
        if board_array[possible_move[0]][possible_move[1]].piece.nil?
          legal_moves << possible_move
        elsif board_array[possible_move[0]][possible_move[1]].piece.color != @color
          legal_moves << possible_move
        end
      end
    end
    legal_moves
  end
end
