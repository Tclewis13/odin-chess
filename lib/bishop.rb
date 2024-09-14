class Bishop < Piece
  attr_accessor :color, :spawn_pos, :move_set, :feet_color

  def initialize(color, spawn_pos, move_set, feet_color)
    super(color, spawn_pos, move_set)
    self.feet_color = feet_color
  end
end
