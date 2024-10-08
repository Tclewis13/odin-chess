class Piece
  attr_accessor :taken, :current_pos, :first_move
  attr_writer :color, :spawn_pos, :move_set, :symbol

  def initialize(color, spawn_pos, move_set)
    self.color = color
    self.spawn_pos = spawn_pos
    self.move_set = move_set
    self.taken = false
    self.current_pos = spawn_pos
    self.first_move = true
  end
end
