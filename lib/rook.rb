require_relative 'piece'

class Rook < Piece
  attr_accessor :color, :spawn_pos, :move_set, :symbol

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.symbol = 'R'
  end
end
