require 'json'

class Game
  
  public
  def start_game
    load_dictionary
    choose_word
  end

  private
  def load_dictionary
    #loads dictionary and filters for words 5-12 characters inclusive
    @@dictionary = File.open('dictionary.txt', 'r').readlines(chomp: true)
    @@dictionary = @@dictionary.filter{|word| word.length > 4 && word.length < 13}
  end
  private
  def choose_word
    #chooses word from dictionary for the player to guess
    @@word_to_guess = @@dictionary[Random.new.rand(@@dictionary.length)].split("")
    p @@word_to_guess
    @@player = Player.new
    @@player.load_or_new
    @@player.guess
  end

  private
  def win
    puts @@player.correct_letters.join(" ")
    puts "You Win!"
    replay()
  end

  private
  def lose
    puts "Out of guesses, You Lose."
    replay()
  end

  def replay
    puts "would you like to play again?"
    answer = gets.chomp.downcase
    if answer == "y" || answer == "yes"
      choose_word()
    end
  end

end

class Player < Game
  attr_accessor :correct_letters

  public
  def initialize (guesses_remaining = 6, letters_words_guessed = [],
     correct_letters = Array.new(@@word_to_guess.length, '_'))
    @guesses_remaining = guesses_remaining
    @letters_words_guessed = letters_words_guessed
    @correct_letters = correct_letters
  end

  def guess
    if @letters_words_guessed.length > 0
      puts "Wrong Guess Remaining: #{@guesses_remaining}"
      puts "Guesses: #{@letters_words_guessed}\n"
      puts @correct_letters.join(" ")
    end
    save()
    take_guess()
    check_guess()
  end

  def take_guess
    #takes a word or letter for input as a guess
    print "Enter a letter or word to guess: "
    @current_guess = gets.chomp.downcase
    unless @current_guess =~ (/\A[a-z]+\z/)
      puts ""
      puts "Invalid entry, try again"
      guess()
    end
  end

  def check_guess
    # check if guess is a word or a letter and compares it to the answer
    #add word to letter to guessed array
    if @letters_words_guessed.include?(@current_guess)
      puts "You have already guessed the letter/word, try something else!"
      guess()
    end
    @letters_words_guessed.push(@current_guess)
    #check if input is a word
    if @current_guess.length > 1
      if @current_guess.split("") == @@word_to_guess
        @correct_letters = @@word_to_guess
        win()
      else
        wrong_guess()
      end
    #check if answer includes letter
    elsif @current_guess.length == 1
      if @@word_to_guess.include?(@current_guess)
        @@word_to_guess.each_with_index do |letter, idx|
          if letter == @current_guess 
            @correct_letters[idx] = letter
          end
        end
        if @correct_letters == @@word_to_guess
          puts @correct_letters.join(" ")
          win()
        else
          guess()
        end
      else
        wrong_guess()
      end
    
    end
  end

  def save
    puts "Would you like to save your progress (y or yes to save, otherwise continue without saving)?"
    answer = gets.chomp.downcase
    if answer == "y" || answer == "yes"
      name_file()
    end
  end

  def wrong_guess
    @guesses_remaining = @guesses_remaining - 1
    if @guesses_remaining == 0
      lose()
    else
      guess()
    end
  end

  def to_json
    JSON.dump({    
      :guesses_remaining => @guesses_remaining,
      :letters_words_guessed => @letters_words_guessed,
      :correct_letters => @correct_letters,
      :word_to_guess => @@word_to_guess
      })
  end

  def self.from_json(string)
    begin
      data = JSON.load(string)
      @@word_to_guess = data['word_to_guess']
      @@player = Player.new(data['guesses_remaining'], data['letters_words_guessed'], data['correct_letters'])
    rescue
      puts "loading file error, please select a valid save file."
      load()
    end
  end

  def name_file
    puts "What would you like to name your file? (letters, numbers and underscores only)"
    filename = gets.chomp
    if filename !~ /\A[a-zA-z0-9_]+\z/
      puts "Invalid file name. Try Again."
      name_file()
    elsif File.exist?('save_files/' + filename + ".txt")
      puts "File name exists already, please enter a different name."
      name_file()
    else
      filename ='save_files/' + filename + ".txt"
      Dir.mkdir('save_files') unless Dir.exist?('save_files')
      File.open(filename, "w") do |file|
        file.puts to_json()
      end
    end
  end

  def load_or_new
    puts "would you like to load a save file?"
    answer = gets.chomp
    if answer == "y" || answer == "yes"
      load()
    end
  end

  def load
    puts "enter file name (without file extension)"
    filename = 'save_files/' + gets.chomp + '.txt'
    if File.exist?(filename)
      file = File.open(filename, 'r').read
      Player.from_json(file)
    else
      puts "filename does not exist, please enter a valid text save file."
      load()
    end
  end

end

  



game = Game.new
game.start_game