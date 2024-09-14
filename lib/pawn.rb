class Pawn < Piece
  attr_accessor :color, :spawn_pos, :move_set, :transformed

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.transformed = false
  end
end
