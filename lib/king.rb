class King < Piece
  attr_accessor :color, :spawn_pos, :move_set, :check, :checkmate, :castled

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.check = false
    self.checkmate = false
    self.castled = false
  end
end
