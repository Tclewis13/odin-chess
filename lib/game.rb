require_relative 'board'
require_relative 'space'
require 'pry-byebug'

class Game
  attr_writer :board, :setup, :turn, :green_manifest, :white_manifest, :check, :passant_pawn, :game_type

  def initialize(board, setup = 'nil')
    self.board = board
    self.setup = setup
    board.print_board(board.board_array)
    self.turn = :white
    self.green_manifest = []
    self.white_manifest = []
    self.check = false
    generate_piece_manifest(@board.board_array, setup)

    puts 'This chess. Here are rules.'
    puts 'Input piece selection and moves with board notation. Example: D5'
    puts 'To castle, input CASTLE when selecting a piece to move.'
    puts 'Input pvp for two player game. Input pve for game vs AI'
    self.game_type = gets.chomp

    unless @game_type == 'pve' || @game_type == 'pvp'
      puts 'Why are you being difficult >:('
      exit
    end

    game_flow
  end

  def game_flow
    # check for checkmate
    if @check && check_for_checkmate
      puts 'Checkmate!'
      exit
    end

    # check for stalemate
    if check_for_stalemate
      puts 'Stalemate!'
      exit
    end

    if @turn == :white || (@turn == :green && @game_type == 'pvp')
      # get piece to move from user
      puts "#{@turn} turn. Select piece to move."
      notation_piece = gets.chomp
      notation_piece = notation_piece.upcase
      if notation_piece == 'CASTLE'
        castle

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

        @board.print_board(@board.board_array)
        game_flow
      end
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
      if coord_dest.nil? || !@board.move_legal?(moving_piece, coord_dest, @passant_pawn)
        puts 'Invalid input.'
        game_flow
      end
      destination_space = @board.board_array[coord_dest[0]][coord_dest[1]]
    else
      ai_move = get_AI_move(:green)
      moving_piece = ai_move[0]
      destination = ai_move[1]
      destination_space = @board.board_array[destination[0]][destination[1]]
    end

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

      if moving_piece.symbol == 'P' && !@passant_pawn.nil? && (moving_piece.color == :white && @board.board_array[destination_space.board_x + 1][destination_space.board_y].piece == @passant_pawn)
        @passant_pawn.taken = true
        @board.board_array[@passant_pawn.current_pos[0]][@passant_pawn.current_pos[1]].piece = nil
        @passant_pawn.current_pos = [nil, nil]
        if @turn == :white
          @green_manifest.delete(@passant_pawn)
        elsif @turn == :green
          @white_manifest.delete(@passant_pawn)
        end
      end
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

    # if a pawn moved, check to see if it can transform
    if moving_piece.symbol == 'P' && moving_piece.color == :white
      moving_piece = transform_pawn(moving_piece) if moving_piece.current_pos[0] == 0
    elsif moving_piece.symbol == 'P' && moving_piece.color == :green
      moving_piece = transform_pawn(moving_piece) if moving_piece.current_pos[0] == 7
    end

    @passant_pawn = nil
    @passant_pawn = moving_piece if moving_piece.symbol == 'P' && moving_piece.double_moved == true

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

  def transform_pawn(pawn)
    if @turn == :green
      @green_manifest.delete(pawn)
    elsif @turn == :white
      @white_manifest.delete(pawn)
    end

    puts "Pawn at #{@board.coord_to_notation([pawn.current_pos[0], pawn.current_pos[1]])} can transform. Enter N for Knight and Q for Queen." # rubocop:disable Layout/LineLength
    transformation = gets.chomp
    transformation = transformation.upcase
    if transformation == 'N'
      transformed_pawn = @board.change_pawn(pawn, transformation)
      pawn.taken = true
      pawn.current_pos = [nil, nil]
      @board.board_array[transformed_pawn.current_pos[0]][transformed_pawn.current_pos[1]].piece = transformed_pawn
    elsif transformation == 'Q'
      transformed_pawn = @board.change_pawn(pawn, transformation)
      pawn.taken = true
      pawn.current_pos = [nil, nil]
      @board.board_array[transformed_pawn.current_pos[0]][transformed_pawn.current_pos[1]].piece = transformed_pawn
    end

    if transformed_pawn.color == :green then @green_manifest << transformed_pawn
    elsif transformed_pawn.color == :white then @white_manifest << transformed_pawn
    end
    transformed_pawn
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
    # check to see if any defending pieces have any moves that can resolve check
    mate_manifest.each do |defender|
      legal_moves = defender.get_moves(@board.board_array)
      legal_moves.each do |move|
        projected_board = Marshal.load(Marshal.dump(@board))
        proj_green_manifest = @green_manifest.clone
        proj_white_manifest = @white_manifest.clone
        proj_destination_space = projected_board.board_array[move[0]][move[1]]
        proj_moving_piece = mate_manifest.select { |piece| piece.current_pos[0] == defender.current_pos[0] && piece.current_pos[1] == defender.current_pos[1] } # rubocop:disable Layout/LineLength
        proj_moving_piece = proj_moving_piece[0]
        proj_moving_piece = Marshal.load(Marshal.dump(proj_moving_piece))
        # need to make sure defending king doesnt just move into another check position
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

  def space_check(board, green_manifest, white_manifest, turn, space)
    space_coord = [space.board_x, space.board_y]
    if turn == :green
      green_legal_moves = []
      green_manifest.each do |piece|
        temp_moves = piece.get_moves(board.board_array)
        temp_moves.each { |move| green_legal_moves << move }
      end
      return true if green_legal_moves.include?(space_coord)
    elsif turn == :white
      white_legal_moves = []
      white_manifest.each do |piece|
        temp_moves = piece.get_moves(board.board_array)
        temp_moves.each { |move| white_legal_moves << move }
      end
      return true if white_legal_moves.include?(space_coord)
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
    # check to see if current player has any moves that wouldn't result in check
    manifest.each do |piece|
      legal_moves = piece.get_moves(@board.board_array)
      actually_legal_moves = legal_moves.clone
      # if the considered piece is a king, remove moves that would make him move into check
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

  def castle
    # cannot castle if king in check
    if @check
      puts 'Cannot castle while King is in check!'
      return
    end

    puts 'Castle Queenside (Q) or Kingside? (K)'
    direction = gets.chomp
    direction = direction.upcase

    # Queenside
    if direction == 'Q'
      if @turn == :white
        # if king and rook have not moved
        if !@board.board_array[7][0].piece.nil? && @board.board_array[7][0].piece.first_move && !@board.board_array[7][4].piece.nil? && @board.board_array[7][0].piece.first_move
          # If the castling path is blocked
          if !@board.board_array[7][1].piece.nil? || !@board.board_array[7][2].piece.nil? || !@board.board_array[7][3].piece.nil? # rubocop:disable Layout/LineLength,Metrics/BlockNesting
            puts 'Cannot castle through pieces!'
            return nil
          end
          # make sure spaces king moves through are not in check
          if !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[7][2]) && !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[7][3]) # rubocop:disable Metrics/BlockNesting,Layout/LineLength
            # rules finally satisfied, we complete the castling
            @board.white_king.current_pos = [7, 2]
            @board.board_array[7][4].piece = nil
            @board.board_array[7][2].piece = @board.white_king
            rook = @board.board_array[7][0].piece
            rook.current_pos = [7, 3]
            @board.board_array[7][0].piece = nil
            @board.board_array[7][3].piece = rook
          else
            puts 'Castling spaces are in check!'
            return nil
          end
        else
          puts 'King or Rook has already moved!'
          return nil
        end
      end
      if @turn == :green
        # if king and rook have not moved
        if !@board.board_array[0][0].piece.nil? && @board.board_array[0][0].piece.first_move && !@board.board_array[0][4].piece.nil? && @board.board_array[0][0].piece.first_move
          # If the castling path is blocked
          if !@board.board_array[0][1].piece.nil? || !@board.board_array[0][2].piece.nil? || !@board.board_array[0][3].piece.nil? # rubocop:disable Layout/LineLength,Metrics/BlockNesting
            puts 'Cannot castle through pieces!'
            return nil
          end
          # make sure spaces king moves through are not in check
          if !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[0][2]) && !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[0][3]) # rubocop:disable Metrics/BlockNesting,Layout/LineLength
            # rules finally satisfied, we complete the castling
            @board.green_king.current_pos = [0, 2]
            @board.board_array[0][4].piece = nil
            @board.board_array[0][2].piece = @board.green_king
            rook = @board.board_array[0][0].piece
            rook.current_pos = [0, 3]
            @board.board_array[0][0].piece = nil
            @board.board_array[0][3].piece = rook
          else
            puts 'Castling spaces are in check!'
            return nil
          end
        else
          puts 'King or Rook has already moved!'
          return nil
        end
      end
    end

    # Kingside
    if direction == 'K'
      if @turn == :white # rubocop:disable Style/SoleNestedConditional
        # if king and rook have not moved
        if !@board.board_array[7][7].piece.nil? && @board.board_array[7][4].piece.first_move && !@board.board_array[7][4].piece.nil? && @board.board_array[7][7].piece.first_move
          # If the castling path is blocked
          if !@board.board_array[7][5].piece.nil? || !@board.board_array[7][6].piece.nil? # rubocop:disable Metrics/BlockNesting
            puts 'Cannot castle through pieces!'
            return nil
          end
          # make sure spaces king moves through are not in check
          if !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[7][5]) && !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[7][6]) # rubocop:disable Metrics/BlockNesting,Layout/LineLength
            # rules finally satisfied, we complete the castling
            @board.white_king.current_pos = [7, 6]
            @board.board_array[7][4].piece = nil
            @board.board_array[7][6].piece = @board.white_king
            rook = @board.board_array[7][7].piece
            rook.current_pos = [7, 5]
            @board.board_array[7][7].piece = nil
            @board.board_array[7][5].piece = rook
          else
            puts 'Castling spaces are in check!'
            return nil
          end
        else
          puts 'King or Rook has already moved!'
          return nil
        end
      end
    end
    if direction == 'K' # rubocop:disable Style/GuardClause
      if @turn == :green # rubocop:disable Style/GuardClause,Style/SoleNestedConditional
        # if king and rook have not moved
        if !@board.board_array[0][7].piece.nil? && @board.board_array[0][4].piece.first_move && !@board.board_array[0][4].piece.nil? && @board.board_array[0][7].piece.first_move
          # If the castling path is blocked
          if !@board.board_array[0][5].piece.nil? || !@board.board_array[0][6].piece.nil? # rubocop:disable Metrics/BlockNesting
            puts 'Cannot castle through pieces!'
            return nil
          end
          # make sure spaces king moves through are not in check
          if !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[0][5]) && !space_check(@board, @green_manifest, @white_manifest, opposite_turn(@turn), @board.board_array[0][6]) # rubocop:disable Metrics/BlockNesting,Layout/LineLength
            # rules finally satisfied, we complete the castling
            @board.green_king.current_pos = [0, 6]
            @board.board_array[0][4].piece = nil
            @board.board_array[0][6].piece = @board.green_king
            rook = @board.board_array[0][7].piece
            rook.current_pos = [0, 5]
            @board.board_array[0][7].piece = nil
            @board.board_array[0][5].piece = rook
          else
            puts 'Castling spaces are in check!'
            return nil # rubocop:disable Style/RedundantReturn
          end
        else
          puts 'King or Rook has already moved!'
          return nil # rubocop:disable Style/RedundantReturn
        end
      end
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

  def get_AI_move(color)
    manifest = []
    if color == :green
      manifest = @green_manifest
    elsif color == :white
      manifest = @white_manifest
    end

    piece = manifest.sample
    legal_moves = piece.get_moves(@board.board_array)
    if legal_moves.empty? then get_AI_move(:green) else
                                                     move = legal_moves.sample
                                                     [piece, move]
    end
  end
end
