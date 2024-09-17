require_relative 'piece'
require 'pry-byebug'

class Rook < Piece
  attr_accessor :color, :spawn_pos, :move_set, :symbol

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.symbol = 'R'
  end

  def get_moves(board_array)
    legal_moves = []
    move_set.each do |direction|
      7.times do |i|
        possible_move = []
        offset = []
        offset[0] = direction[0] * (i + 1)
        offset[1] = direction[1] * (i + 1)

        possible_move[0] = @current_pos[0] + offset[0]
        possible_move[1] = @current_pos[1] + offset[1]
        if possible_move[0].between?(0, 7) && possible_move[1].between?(0, 7) && board_array[possible_move[0]][possible_move[1]].piece.nil? # rubocop:disable Layout/LineLength
          # empty space
          legal_moves << possible_move
        elsif possible_move[0].between?(0, 7) && possible_move[1].between?(0, 7) && board_array[possible_move[0]][possible_move[1]].piece.color != @color # rubocop:disable Layout/LineLength
          # opposing piece space
          legal_moves << possible_move
          break
        else
          # friendly piece space
          break
        end
      end
    end
    legal_moves
  end
end
