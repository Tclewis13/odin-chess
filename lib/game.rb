require_relative 'board'
require_relative 'space'
require 'pry-byebug'

class Game
  attr_writer :board, :setup, :turn, :green_manifest, :white_manifest, :check

  def initialize(board, setup = 'nil')
    self.board = board
    self.setup = setup
    board.print_board(board.board_array)
    self.turn = :white
    self.green_manifest = []
    self.white_manifest = []
    self.check = false
    generate_piece_manifest(@board.board_array, setup)

    game_flow
  end

  def game_flow
    if @check && check_for_checkmate
      puts 'Checkmate!'
      exit
    end

    # check for stalemate
    if check_for_stalemate
      puts 'Stalemate!'
      exit
    end

    # get piece to move from user
    puts "#{@turn} turn. Select piece to move."
    notation_piece = gets.chomp
    notation_piece = notation_piece.upcase
    coord_piece = @board.notation_to_coord(notation_piece)
    moving_piece = @board.board_array[coord_piece[0]][coord_piece[1]].piece
    if coord_piece.nil? || moving_piece.nil? || moving_piece.color != @turn
      puts 'Invalid input.'
      game_flow
    end

    # get destination space from user
    puts "#{@turn} is moving piece at #{notation_piece}. Select destination."
    notation_dest = gets.chomp
    notation_dest = notation_dest.upcase
    coord_dest = @board.notation_to_coord(notation_dest)
    if coord_dest.nil? || !@board.move_legal?(moving_piece, coord_dest)
      puts 'Invalid input.'
      game_flow
    end
    destination_space = @board.board_array[coord_dest[0]][coord_dest[1]]

    # if last turn triggered check we need to make sure this move will remove check
    # make deep copies of board state so that we can check the validity of the proposed move
    projected_board = Marshal.load(Marshal.dump(@board))
    proj_green_manifest = @green_manifest.clone
    proj_white_manifest = @white_manifest.clone
    proj_destination_space = projected_board.board_array[destination_space.board_x][destination_space.board_y]
    proj_moving_piece = (proj_green_manifest | proj_white_manifest).select { |piece| piece.current_pos[0] == moving_piece.current_pos[0] && piece.current_pos[1] == moving_piece.current_pos[1] } # rubocop:disable Layout/LineLength
    proj_moving_piece = proj_moving_piece[0]
    proj_moving_piece = Marshal.load(Marshal.dump(proj_moving_piece))
    if check_resolution(projected_board, proj_green_manifest, proj_white_manifest, proj_destination_space, proj_moving_piece) # rubocop:disable Layout/LineLength
      @check ? (puts 'This move does not resolve check!') : (puts 'This piece is pinned!')
      game_flow
    end

    # Prevent a King from moving into check
    if moving_piece.symbol == 'K' && !check_king_move(destination_space, moving_piece)
      puts 'King cannot move into check!'
      game_flow
    end

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

    # check to see if this move checked the other king
    if check_for_check(@board, @green_manifest, @white_manifest, @turn)
      puts "#{@turn} King is in check!"
      @check = true
    end

    # pass turn
    if @turn == :white
      @turn = :green
    elsif @turn == :green
      @turn = :white
    end

    game_flow
  end

  def check_king_move(destination_space, moving_piece)
    # make deep copies of board state so that we can check the validity of the proposed move
    projected_board = Marshal.load(Marshal.dump(@board))
    proj_green_manifest = @green_manifest.clone
    proj_white_manifest = @white_manifest.clone
    proj_destination_space = projected_board.board_array[destination_space.board_x][destination_space.board_y]
    proj_moving_piece = (proj_green_manifest | proj_white_manifest).select { |piece| piece.current_pos[0] == moving_piece.current_pos[0] && piece.current_pos[1] == moving_piece.current_pos[1] } # rubocop:disable Layout/LineLength
    proj_moving_piece = proj_moving_piece[0]
    proj_moving_piece = Marshal.load(Marshal.dump(proj_moving_piece))
    # Need to reassign projected board's king to our projected king after deserialization
    if proj_moving_piece.color == :green
      projected_board.green_king = proj_moving_piece
    elsif proj_moving_piece.color == :white
      projected_board.white_king = proj_moving_piece
    end
    unless check_resolution(projected_board, proj_green_manifest, proj_white_manifest, proj_destination_space,
                            proj_moving_piece)
      return true
    end

    false
  end

  def check_for_checkmate
    mate_manifest = []
    legal_moves = []
    if @turn == :green
      mate_manifest = @green_manifest
    elsif @turn == :white
      mate_manifest = @white_manifest
    end
    mate_manifest.each do |defender|
      # Pawns threaten spaces differently than other pieces
      defender.symbol == 'P' ? (legal_moves = defender.get_check_moves(@board.board_array)) : (legal_moves = defender.get_moves(@board.board_array)) # rubocop:disable Layout/LineLength
      legal_moves.each do |move|
        projected_board = Marshal.load(Marshal.dump(@board))
        proj_green_manifest = @green_manifest.clone
        proj_white_manifest = @white_manifest.clone
        proj_destination_space = projected_board.board_array[move[0]][move[1]]
        proj_moving_piece = mate_manifest.select { |piece| piece.current_pos[0] == defender.current_pos[0] && piece.current_pos[1] == defender.current_pos[1] } # rubocop:disable Layout/LineLength
        proj_moving_piece = proj_moving_piece[0]
        proj_moving_piece = Marshal.load(Marshal.dump(proj_moving_piece))
        next if defender.symbol == 'K' && !check_king_move(proj_destination_space, proj_moving_piece)
        unless check_resolution(projected_board, proj_green_manifest, proj_white_manifest, proj_destination_space, proj_moving_piece) # rubocop:disable Layout/LineLength
          return false
        end
      end
    end
    true
  end

  def check_for_check(board, green_manifest, white_manifest, turn)
    # get all legal moves of opposing pieces. If friendly king's position is among their legal moves, we have check
    if turn == :green
      green_legal_moves = []
      green_manifest.each do |piece|
        temp_moves = piece.get_moves(board.board_array)
        temp_moves.each { |move| green_legal_moves << move }
      end
      return true if green_legal_moves.include?(board.white_king.current_pos)
    elsif turn == :white
      white_legal_moves = []
      white_manifest.each do |piece|
        temp_moves = piece.get_moves(board.board_array)
        temp_moves.each { |move| white_legal_moves << move }
      end
      return true if white_legal_moves.include?(board.green_king.current_pos)
    end
    false
  end

  def check_resolution(projected_board, proj_green_manifest, proj_white_manifest, destination_space, moving_piece)
    # if destination empty
    if destination_space.piece.nil?
      destination_space.piece = moving_piece
      projected_board.board_array[moving_piece.current_pos[0]][moving_piece.current_pos[1]].piece = nil
      moving_piece.current_pos = [destination_space.board_x, destination_space.board_y]
      moving_piece.first_move = false
    # if destination is occupied
    else
      # code here is modified because of destination_piece being a pointer to a pawn of original board state, but functionally the same as game_flow's code # rubocop:disable Layout/LineLength
      if @turn == :white
        deleted_piece = proj_green_manifest.select { |piece| piece.current_pos[0] == destination_space.board_x && piece.current_pos[1] == destination_space.board_y } # rubocop:disable Layout/LineLength
        proj_green_manifest.delete(deleted_piece[0])
      elsif @turn == :green
        deleted_piece = proj_white_manifest.select { |piece| piece.current_pos[0] == destination_space.board_x && piece.current_pos[1] == destination_space.board_y } # rubocop:disable Layout/LineLength
        proj_white_manifest.delete(deleted_piece[0])
      end

      destination_space.piece.taken = true
      destination_space.piece.current_pos = [nil, nil]
      destination_space.piece = moving_piece
      projected_board.board_array[moving_piece.current_pos[0]][moving_piece.current_pos[1]].piece = nil
      moving_piece.current_pos = [destination_space.board_x, destination_space.board_y]
      moving_piece.first_move = false
    end
    # Now that we have our projected board state, check if the proposed state would resolve check
    check_for_check(projected_board, proj_green_manifest, proj_white_manifest, opposite_turn(@turn))
  end

  def check_for_stalemate
    manifest = []
    if @turn == :green
      manifest = @green_manifest
    elsif @turn == :white
      manifest = @white_manifest
    end

    manifest.each do |piece|
      legal_moves = piece.get_moves(@board.board_array)
      actually_legal_moves = legal_moves.clone
      if piece.symbol == 'K'
        legal_moves.each_with_index do |move, index|
          destination_space = @board.board_array[move[0]][move[1]]
          actually_legal_moves.delete(move) unless check_king_move(destination_space, piece)
        end
      end
      return false unless actually_legal_moves.empty?
    end
    true
  end

  def opposite_turn(turn)
    if turn == :white
      :green
    elsif turn == :green
      :white
    end
  end

  def generate_piece_manifest(board_array, setup)
    if setup == 'default'
      2.times do |i|
        8.times do |j|
          @green_manifest << board_array[i][j].piece
          @white_manifest << board_array[i + 6][j].piece
        end
      end
    elsif setup == 'stalemate'
      @green_manifest << board_array[3][2].piece
      @white_manifest << board_array[2][1].piece
      @white_manifest << board_array[2][3].piece
      @white_manifest << board_array[7][1].piece
      @white_manifest << board_array[0][0].piece
    elsif setup == 'pin'
      @green_manifest << board_array[2][3].piece
      @white_manifest << board_array[6][3].piece
      @white_manifest << board_array[5][3].piece
      @green_manifest << board_array[0][0].piece
    end
  end
end
