# frozen_string_literal: true

require 'date'
require 'json'

require_relative 'util'

class Persistence

  @@directory = 'db'

  def initialize(lifter, date = nil)
    if date.nil?
      date = Date.today.iso8601
    else
      # Validate that this is in the right format
      begin
        date = Date.iso8601(date)
      rescue Date::Error
        puts colourise("Invalid date '#{date}'. Please use format YYYY-MM-DD", :red)
        exit 1
      end
    end

    @@filename = "#{@@directory}/#{lifter.downcase}_#{date}.json"
    get_state
  end

  def buddies
    @@state['buddies'] ||= []
  end

  def workout
    @@state['workout']
  end

  def workout=(workout)
    @@state['workout'] = workout
  end

  def workout_weights
    @@state['workout_weights'] ||= {}
  end

  def sets
    @@state['sets'] ||= {}
  end

  def successful_reps
    @@state['successful_reps'] ||= {}
  end

  def get_state
    if File.exist?(@@filename)
      puts colourise("Loaded existing state from #{@@filename}", :grey)
      @@state = JSON.parse(File.read(@@filename))
    else
      @@state = {}
    end
  end

  def flush_state
    Dir.mkdir(@@directory) unless File.exist?(@@directory)

    File.open(@@filename, File::CREAT|File::TRUNC|File::RDWR) do |f|
      f.write @@state.to_json
    end
  end
end
