class Space
  attr_accessor :board_x, :board_y, :color

  def initialize(board_x, board_y, color)
    self.board_x = board_x
    self.board_y = board_y
    self.color = color
  end
end
