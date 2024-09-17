require_relative 'board'
require 'pry-byebug'

class Game
  attr_writer :board, :setup, :turn, :green_manifest, :white_manifest

  def initialize(board, setup = 'nil')
    self.board = board
    self.setup = setup
    board.print_board(board.board_array)
    self.turn = :white
    self.green_manifest = []
    self.white_manifest = []
    generate_piece_manifest(@board.board_array)

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
    # if destination is empty
    if destination_space.piece.nil?
      destination_space.piece = moving_piece
      @board.board_array[moving_piece.current_pos[0]][moving_piece.current_pos[1]].piece = nil
      moving_piece.current_pos = [destination_space.board_x, destination_space.board_y]
      moving_piece.first_move = false
    # if destination is occupied
    else
      if @turn == :white
        @green_manifest.delete(destination_space.piece)
      elsif @turn == :green
        @white_manifest.delete(destination_space.piece)
      end

      destination_space.piece.taken = true
      destination_space.piece.current_pos = [nil, nil]
      destination_space.piece = moving_piece
      @board.board_array[moving_piece.current_pos[0]][moving_piece.current_pos[1]].piece = nil
      moving_piece.current_pos = [destination_space.board_x, destination_space.board_y]
      moving_piece.first_move = false
    end

    @board.print_board(@board.board_array)
    check_for_check
    game_flow
  end

  def check_for_check
    if @turn == :green
      green_legal_moves = []
      @green_manifest.each do |piece|
        temp_moves = piece.get_moves(@board.board_array)
        temp_moves.each { |move| green_legal_moves << move }
      end
      puts 'Check!' if green_legal_moves.include?(@board.white_king.current_pos)
    elsif @turn == :white
      white_legal_moves = []
      @white_manifest.each do |piece|
        temp_moves = piece.get_moves(@board.board_array)
        temp_moves.each { |move| white_legal_moves << move }
      end
      puts 'Check!' if white_legal_moves.include?(@board.green_king.current_pos)
    end
  end

  def generate_piece_manifest(board_array)
    2.times do |i|
      8.times do |j|
        @green_manifest << board_array[i][j].piece
        @white_manifest << board_array[i + 6][j].piece
      end
    end
  end
end
