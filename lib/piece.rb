class Piece
  attr_accessor :taken
  attr_writer :color, :spawn_pos, :move_set

  def initialize(color, spawn_pos, move_set)
    self.color = color
    self.spawn_pos = spawn_pos
    self.move_set = move_set
    self.taken = false
  end
end
