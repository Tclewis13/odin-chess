require_relative 'piece'

class Pawn < Piece
  attr_accessor :color, :spawn_pos, :move_set, :transformed, :symbol

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.transformed = false
    self.symbol = 'P'
  end
end
