# app.rb
require './classes/item'
require './classes/book'
require './classes/label'
require './classes/game'
require './classes/source'
require './classes/author'
require './classes/movie'
require 'json'
class Saveload
  def load_data(filename)
    if File.exist?(filename)
      file = File.read(filename)
      JSON.parse(file)
    else
      puts "File #{filename} does not exist."
      File.write(filename, '[]')
      []
    end
  end

  def save_data(filename, data)
    File.write(filename, JSON.pretty_generate(data))
  end
end

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/PerceivedComplexity
class App
  def initialize
    @books = Saveload.new.load_data('data/books.json') || []
    @labels = Saveload.new.load_data('data/labels.json') || []
    @authors = Saveload.new.load_data('data/authors.json') || []
    @movies = Saveload.new.load_data('data/movies.json') || []
    @sources = Saveload.new.load_data('data/sources.json') || []
    @genres = Saveload.new.load_data('data/genres.json') || []
    @games = Saveload.new.load_data('data/games.json') || []
    @music_albums = Saveload.new.load_data('data/music_albums.json') || []
  end
  # rubocop:enable Metrics/PerceivedComplexity

  # list methods
  def list_all_books
    puts "\nListing all books:"
    if @books.empty?
      puts 'No books found.'
    else
      @books.each do |book|
        puts "ID: #{book.id}, Author: #{book.author.full_name}, Publisher: #{book.publisher},
        Cover state: #{book.cover_state}"
      end
    end
  end

  def list_all_movies
    if @movies.empty?
      puts 'No movies were found'
    else
      @movies.each do |movie|
        puts "ID: #{movie.id}, Genre: #{movie.genre}, Author: #{movie.author}, Source: #{movie.source}, Date-Published: #{movie.publish_date}"
      end
    end
  end

  def list_all_sources
    if @sources.empty?
      puts 'No sources were found'
    else
      @sources.each do |source|
        puts "ID: #{source.id}, Source: #{source.name}"
      end
    end
  end

  def list_all_labels
    @labels = Saveload.new.load_data('data/labels.json')
    puts "\nListing all labels:"
    if @labels.empty?
      puts 'No labels found.'
    else
      @labels.each do |label|
        puts "Title: #{label['title']}, Color: #{label['color']}"
      end
    end
  end

  def list_all_games
    puts "\nListing all games:"
    if @games.empty?
      puts 'No games found.'
    else
      @games.each do |game|
        puts "#{game.id}. #{game.label} (Genre: #{game.genre}, Author: #{game.author.full_name})"
      end
    end
  end

  def list_all_authors
    puts "\nListing all authors:"
    if @authors.empty?
      puts 'No authors found.'
    else
      @authors.each do |author|
        puts "ID: #{author.id}, Full Name: #{author.full_name}, Items Count: #{author.items.count}"
      end
    end
  end

  # add methods
  def add_movie
    # puts 'Enter Label: '
    # label = gets.chomp.to_s
    puts 'Enter genre: '
    genre = gets.chomp.to_s
    puts 'Enter Author: '
    author = gets.chomp.to_s
    puts 'Enter source: '

    source_name = gets.chomp.to_s
    source = @sources.find { |s| s.name == source_name }

    unless source
      source = Source.new(source_name)
      @sources << source
    end
    puts 'Enter publish_date (YYYY-MM-DD): '
    publish_date_str = gets.chomp.to_s
    publish_date = Date.parse(publish_date_str)

    print 'Is it silent? (true/false): '
    silent = gets.chomp.downcase == 'true'
    movie = Movie.new(genre, author, source, publish_date, silent)
    choose_label(movie)
    source.add_item(movie)

    @movies << movie

    puts 'Movie added successfully!'
  end

  def add_book
    puts 'Published by:'
    publisher = gets.chomp.to_s
    puts 'Cover state (good or bad):'
    loop do
      @cover_state = gets.chomp.to_s
      break if %w[good bad].include?(@cover_state)
      return if @cover_state == 'exit'

      puts 'Invalid cover state. Please try again or type exit to return to the main menu.'
    end

    puts 'Published date (YYYY-MM-DD):'
    loop do
      @publish_date = gets.chomp
      break if @publish_date.match?(/\d{4}-\d{2}-\d{2}/)
      return if @publish_date == 'exit'

      puts 'Invalid date format. Please try again.'
    end

    book = Book.new(
      publisher,
      @cover_state,
      @publish_date
    )
    choose_genre(book)
    choose_label(book)
    choose_author(book)
    choose_source(book)

    @books << book

    # Save each chosen element to JSON files

    json = Saveload.new
    json.save_data('data/books.json', @books)
    json.save_data('data/genres.json', @genres)
    json.save_data('data/labels.json', @labels)
    json.save_data('data/authors.json', @authors)
    json.save_data('data/sources.json', @sources)
  end

  def add_game
    puts '===== Add a Game ====='
    print 'Enter genre: '
    genre = gets.chomp
    print 'Enter author (full name): '
    author_name = gets.chomp

    # Modified code: Find or create the author based on full name
    author = find_or_create_author(author_name)

    print 'Enter source: '
    source = gets.chomp
    print 'Enter label: '
    label = gets.chomp
    print 'Enter publish date (YYYY-MM-DD): '
    publish_date = gets.chomp
    print 'Is it multiplayer? (true/false): '
    multiplayer = gets.chomp.downcase == 'true'
    print 'Enter last played date (YYYY-MM-DD): '
    last_played_at = gets.chomp

    game = Game.new(genre, author, source, label, publish_date, multiplayer, last_played_at)
    game.move_to_archive if game.can_be_archived?

    @games << game

    puts 'Game added successfully!'
  end

  # rubocop:enable Metrics/ClassLength

  private

  # Modified code: Method to find or create an author based on full name
  def find_or_create_author(full_name)
    first_name, last_name = full_name.split
    author = @authors.find { |a| a.first_name == first_name && a.last_name == last_name }

    unless author
      author = Author.new(first_name: first_name, last_name: last_name)
      @authors << author
    end

    author
  end

  def choose_label(item)
    puts 'Label title:'
    title = gets.chomp.to_s
    puts 'Label color:'
    color = gets.chomp.to_s

    label_hash = { 'id' => Random.rand(1..1000), 'title' => title, 'color' => color }

    label = @labels.find { |l| l['title'] == title } || label_hash
    @labels << label_hash unless @labels.include?(label_hash)
    item.label = label
  end

  def choose_author(item)
    puts 'Authors first name:'
    first_name = gets.chomp.to_s
    puts 'Authors last name:'
    last_name = gets.chomp.to_s
    author = @authors.find { |a| a.first_name == first_name && a.last_name == last_name } ||
             Author.new(first_name: first_name, last_name: last_name)
    @authors << author unless @authors.include?(author)
    item.author = author
  end
end
