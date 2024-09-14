require 'colorize'
require_relative 'space'

class Board
  attr_accessor :setup, :board_array

  def initialize(setup)
    self.setup = setup
    self.board_array = Array.new(8) { Array.new(8) }
    self.board_array = setup_spaces(@board_array)
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

  def print_board(board_array)
    board_array.each do |row|
      puts ''
      row.each do |column|
        print '[]'.colorize(column.color)
      end
    end
  end
end
