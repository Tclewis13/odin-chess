require 'colorize'
require_relative 'pawn'
require_relative 'space'
require_relative 'rook'
require_relative 'bishop'
require_relative 'knight'
require_relative 'queen'
require_relative 'king'

class Board
  attr_accessor :setup, :board_array

  WHITE_PAWN_MOVESET = [-1, 0]
  GREEN_PAWN_MOVESET = [1, 0]
  BISHOP_MOVESET = [[-1, 1], [1, 1], [1, -1], [-1, -1]]
  KNIGHT_MOVESET = [[-2, -1], [-1, -2], [1, -2], [2, -1], [-2, 1], [-1, 2], [1, 2], [2, 1]]
  ROOK_MOVESET = [[-1, 0], [0, 1], [1, 0], [0, -1]]
  QUEEN_MOVESET = []
  KING_MOVESET = []

  def initialize(setup)
    self.setup = setup
    self.board_array = Array.new(8) { Array.new(8) }
    self.board_array = setup_spaces(@board_array)
    setup_board(self.setup)
  end

  def setup_spaces(board_array)
    color = :white
    board_array.each_with_index do |row, row_index|
      color = row_index.even? ? :white : :green
      row.each_with_index do |column, column_index|
        board_array[row_index][column_index] = Space.new(row_index, column_index, color)
        if color == :white then color = :green
        elsif color == :green then color = :white end
      end
    end
    board_array
  end

  def setup_board(setup)
    return if setup != 'default'

    setup_pawns(setup)
    setup_rooks(setup)
    setup_knights(setup)
    setup_bishops(setup)
    setup_queens(setup)
    setup_kings(setup)
  end

  def setup_pawns(setup)
    return if setup != 'default'

    (0..7).each do |pawn|
      @board_array[1][pawn].piece = Pawn.new(:green, [1, pawn], GREEN_PAWN_MOVESET)
      @board_array[6][pawn].piece = Pawn.new(:white, [6, pawn], WHITE_PAWN_MOVESET)
    end
  end

  def setup_rooks(setup)
    return if setup != 'default'

    [0, 7].each do |rook|
      @board_array[0][rook].piece = Rook.new(:green, [0, rook], ROOK_MOVESET)
      @board_array[7][rook].piece = Rook.new(:white, [7, rook], ROOK_MOVESET)
    end
  end

  def setup_knights(setup)
    return if setup != 'default'

    [1, 6].each do |knight|
      @board_array[0][knight].piece = Knight.new(:green, [0, knight], KNIGHT_MOVESET)
      @board_array[7][knight].piece = Knight.new(:white, [7, knight], KNIGHT_MOVESET)
    end
  end

  def setup_bishops(setup)
    return if setup != 'default'

    @board_array[0][2].piece = Bishop.new(:green, [0, 2], BISHOP_MOVESET, :white)
    @board_array[7][2].piece = Bishop.new(:white, [7, 2], BISHOP_MOVESET, :green)
    @board_array[0][5].piece = Bishop.new(:green, [0, 5], BISHOP_MOVESET, :green)
    @board_array[7][5].piece = Bishop.new(:white, [7, 5], BISHOP_MOVESET, :white)
  end

  def setup_queens(setup)
    return if setup != 'default'

    @board_array[0][3].piece = Queen.new(:green, [0, 3], QUEEN_MOVESET)
    @board_array[7][3].piece = Queen.new(:white, [0, 7], QUEEN_MOVESET)
  end

  def setup_kings(setup)
    return if setup != 'default'

    @board_array[0][4].piece = King.new(:green, [0, 4], KING_MOVESET)
    @board_array[7][4].piece = King.new(:white, [0, 4], KING_MOVESET)
  end

  def print_board(board_array)
    count = 9
    board_array.each do |row|
      count -= 1
      puts ''
      row.each do |column|
        print '['.colorize(column.color)
        column.piece.nil? ? (print ' ') : (print column.piece.symbol.colorize(column.piece.color))
        print ']'.colorize(column.color)
        print " #{count}".colorize(:red) if column.board_y == 7
      end
    end
    puts ''
    print ' A  B  C  D  E  F  G  H  '.colorize(:red)
    puts ''
  end

  def coord_to_notation(coordinates) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/AbcSize
    letter = ''
    number = ''
    case coordinates[0]
    when 0
      number = '8'
    when 1
      number = '7'
    when 2
      number = '6'
    when 3
      number = '5'
    when 4
      number = '4'
    when 5
      number = '3'
    when 6
      number = '2'
    when 7
      number = '1'
    end

    case coordinates[1]
    when 0
      letter = 'A'
    when 1
      letter = 'B'
    when 2
      letter = 'C'
    when 3
      letter = 'D'
    when 4
      letter = 'E'
    when 5
      letter = 'F'
    when 6
      letter = 'G'
    when 7
      letter = 'H'
    end

    letter + number
  end

  def notation_to_coord(notation) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    depth = nil
    length = nil
    case notation[0]
    when 'A'
      length = 0
    when 'B'
      length = 1
    when 'C'
      length = 2
    when 'D'
      length = 3
    when 'E'
      length = 4
    when 'F'
      legnth = 5
    when 'G'
      length = 6
    when 'H'
      length = 7
    else
      return nil
    end

    case notation[1]
    when '1'
      depth = 7
    when '2'
      depth = 6
    when '3'
      depth = 5
    when '4'
      depth = 4
    when '5'
      depth = 3
    when '6'
      depth = 2
    when '7'
      depth = 1
    when '8'
      depth = 0
    else return nil
    end

    [depth, length]
  end

  def move_legal?(piece, destination)
    legal_moves = piece.get_moves(@board_array)
    legal_moves.include?(destination)
  end
end
