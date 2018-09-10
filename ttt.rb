require 'pry'

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9], # rows
                   [1, 4, 7], [2, 5, 8], [3, 6, 9],  # cols
                   [1, 5, 9], [3, 5, 7]].freeze      # diagonals

  def initialize
    @squares = {}
    reset
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  # returns winning marker or nil
  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def find_move(computer_marker, human_marker)
    move = best_move(computer_marker)
    move = best_move(human_marker) unless move
    move = center_square_if_available unless move
    move = random_move unless move
    move
  end

  def best_move(marker)
    best_moves = []
    WINNING_LINES.each do |combo|
      if (combo & get_board_spots(marker)).count == 2
        final_move = (combo - get_board_spots(marker))
        best_moves << final_move[0] if square_available?(final_move[0])
      end
    end
    best_moves.size.positive? ? best_moves[0] : nil
  end

  def random_move
    empty_squares.sample
  end

  def center_square_if_available
    5 if square_available?(5)
  end

  def square_available?(square)
    empty_squares.include? square
  end

  def get_board_spots(marker)
    @squares.select { |_, v| v.marker == marker }.keys
  end

  def empty_squares
    @squares.select { |_, v| v.marker == ' ' }.keys
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Square
  INITIAL_MARKER = " ".freeze
  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_accessor :score, :name, :marker

  def initialize
    @marker = ''
    @score = 0
    set_name
  end
end

class Human < Player
  def set_name
    n = ''
    loop do
      puts "What's your name?"
      n = gets.chomp
      break unless n.empty?
      puts 'Sorry, must enter a name.'
    end
    self.name = n
  end
end

class Computer < Player
  def set_name
    self.name = ['R2D2', 'Watson', 'Hal'].sample
  end
end

class TTTGame
  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
    set_turn_order
    @current_turn = nil
  end

  def play_round
    set_current_turn
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def play_game
    loop do
      display_board
      play_round
      update_score
      break if human.score == 5 || computer.score == 5
      reset
    end
  end

  def play
    display_welcome_message
    set_markers

    loop do
      play_game
      display_result
      exit unless play_again?
      display_play_again_message
      reset
    end
    display_goodbye_message
  end

  private

  def display_welcome_message
    puts "Welcome to Tic Tac Toe! First to 5 wins."
    puts ""
  end

  def set_current_turn
    @current_turn = @first_move
  end

  def set_turn_order
    turn_answer = ''
    loop do
      puts "Would you like to go first these games (y/n)?"
      turn_answer = gets.chomp.downcase
      break if %w(y n).include? turn_answer
      puts "Invalid, y or n only."
    end
    @first_move = (turn_answer == 'y' ? :human : :computer)
  end

  def set_markers
    marker = ''
    loop do
      puts "Would you like to be (X) or (O)?"
      marker = gets.chomp.downcase
      break if %w(x o).include? marker
      puts "Invalid marker - X or O only."
    end
    human.marker = marker.upcase
    computer.marker = (human.marker == 'X' ? 'O' : 'X')
  end

  def display_goodbye_message
    puts "Thanks for playing! Goodbye"
  end

  def clear
    system 'clear'
  end

  def display_board
    puts "Youre a #{human.marker}. Computer is a #{computer.marker}"
    display_score
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def joinor(value)
    ", or #{value}"
  end

  def unmarked_keys_joinor
    keys = board.unmarked_keys
    "#{keys[0..-2].join(', ')}#{joinor(keys.last)}"
  end

  def human_moves
    square = nil

    puts "Choose a square: (#{unmarked_keys_joinor}): "
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, thats not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    board[board.find_move(computer.marker, human.marker)] = computer.marker
  end

  def update_score
    case board.winning_marker
    when human.marker
      human.score += 1
    when computer.marker
      computer.score += 1
    end
  end

  def display_result
    display_board
    if human.score == 5
      puts "#{human.name} won!"
    else
      puts "#{computer.name} won!"
    end
  end

  def display_score
    puts "#{human.name}: #{human.score}, #{computer.name}: #{computer.score}"
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def reset
    board.reset
    @current_turn = @first_move
    system 'clear'
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def toggle_current_player
    @current_turn = (@current_turn == :human ? :computer : :human)
  end

  def human_turn?
    @current_turn == :human
  end

  def current_player_moves
    if human_turn?
      human_moves
    else
      computer_moves
    end
    toggle_current_player
  end
end

game = TTTGame.new
game.play
