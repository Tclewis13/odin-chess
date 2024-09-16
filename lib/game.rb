require_relative 'board'
require 'pry-byebug'

class Game
  attr_writer :board, :setup, :turn

  def initialize(board, setup = 'nil')
    self.board = board
    self.setup = setup
    board.print_board(board.board_array)
    self.turn = :white

    game_flow
  end

  def game_flow
    puts "#{@turn} turn. Select piece to move."
    notation_piece = gets.chomp
    notation_piece = notation_piece.upcase
    coord_piece = @board.notation_to_coord(notation_piece)
    moving_piece = @board.board_array[coord_piece[0]][coord_piece[1]].piece
    if coord_piece.nil? || moving_piece.nil? || moving_piece.color != @turn
      puts 'Invalid input.'
      game_flow
    end

    puts "#{@turn} is moving piece at #{notation_piece}. Select destination."
    notation_dest = gets.chomp
    notation_dest = notation_dest.upcase
    coord_dest = @board.notation_to_coord(notation_dest)
    if coord_dest.nil? || !@board.move_legal?(moving_piece, coord_dest)
      puts 'Invalid input.'
      game_flow
    end
    destination_space = @board.board_array[coord_dest[0]][coord_dest[1]]
    if destination_space.piece.nil?
      destination_space.piece = moving_piece
      @board.board_array[moving_piece.current_pos[0]][moving_piece.current_pos[1]].piece = nil
      moving_piece.current_pos = [destination_space.board_x, destination_space.board_y]
    else
      destination_space.piece.taken = true
      destination_space.piece.current_pos = [nil, nil]
      destination_space.piece = moving_piece
      @board.board_array[moving_piece.current_pos[0]][moving_piece.current_pos[1]].piece = nil
      moving_piece.current_pos = [destination_space.board_x, destination_space.board_y]
    end

    @board.print_board(@board.board_array)
    game_flow
  end
end
