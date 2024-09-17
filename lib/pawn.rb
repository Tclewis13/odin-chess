require_relative 'piece'

class Pawn < Piece
  attr_accessor :color, :spawn_pos, :move_set, :transformed, :symbol

  def initialize(color, spawn_pos, move_set)
    super(color, spawn_pos, move_set)
    self.transformed = false
    self.symbol = 'P'
  end

  def get_moves(board_array)
    legal_moves = []
    # single move
    if board_array[@current_pos[0] + @move_set[0]][@current_pos[1] + @move_set[1]].piece.nil?
      legal_moves << [@current_pos[0] + @move_set[0], @current_pos[1] + @move_set[1]]
    end
    # double_first move
    if board_array[@current_pos[0] + @move_set[0]][@current_pos[1] + @move_set[1]].piece.nil? && board_array[@current_pos[0] + @move_set[0] + @move_set[0]][@current_pos[1] + @move_set[1] + @move_set[1]].piece.nil? && @first_move == true
      legal_moves << [@current_pos[0] + @move_set[0] + @move_set[0], @current_pos[1] + @move_set[1] + @move_set[1]]
    end

    # take move
    if @color == :white

      take_pos = [@current_pos[0] - 1, @current_pos[1] + 1]
      if !board_array[take_pos[0]][take_pos[1]].nil? && !board_array[take_pos[0]][take_pos[1]].piece.nil? && board_array[take_pos[0]][take_pos[1]].piece.color == :green && take_pos[0].between?(0, 7) && take_pos[1].between?(0, 7) then legal_moves << take_pos end # rubocop:disable Layout/LineLength
      take_pos = [@current_pos[0] - 1, @current_pos[1] - 1]
      if !board_array[take_pos[0]][take_pos[1]].nil? && !board_array[take_pos[0]][take_pos[1]].piece.nil? && board_array[take_pos[0]][take_pos[1]].piece.color == :green && take_pos[0].between?(0, 7) && take_pos[1].between?(0, 7) then legal_moves << take_pos end # rubocop:disable Layout/LineLength
    elsif @color == :green
      take_pos = [@current_pos[0] + 1, @current_pos[1] + 1]
      if !board_array[take_pos[0]][take_pos[1]].nil? && !board_array[take_pos[0]][take_pos[1]].piece.nil? && board_array[take_pos[0]][take_pos[1]].piece.color == :white && take_pos[0].between?(0, 7) && take_pos[1].between?(0, 7) then legal_moves << take_pos end # rubocop:disable Layout/LineLength
      take_pos = [@current_pos[0] + 1, @current_pos[1] - 1]
      if !board_array[take_pos[0]][take_pos[1]].nil? && !board_array[take_pos[0]][take_pos[1]].piece.nil? && board_array[take_pos[0]][take_pos[1]].piece.color == :white && take_pos[0].between?(0, 7) && take_pos[1].between?(0, 7) then legal_moves << take_pos end # rubocop:disable Layout/LineLength
    end
    legal_moves
  end
end
