require_relative 'piece'

class Queen < Piece
  attr_accessor :color, :spawn_pos, :move_set, :symbol

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.symbol = 'Q'
  end
end
