# frozen_string_literal: true

require 'date'
require 'json'

require_relative '../config/values'
require_relative 'util'

class Persistence

  @@directory = 'db'

  def initialize(lifter, date = nil)
     @@lifter = lifter.downcase

    if date.nil?
      @@date = Date.today.iso8601
    else
      # Validate that this is in the right format
      begin
        @@date = Date.iso8601(date)
      rescue Date::Error
        puts colourise("Invalid date '#{date}'. Please use format YYYY-MM-DD", :red)
        exit 1
      end
    end

    @@workout_filename = "#{@@directory}/#{@@lifter}_#{@@date}.json"
    get_workout_state
    @@profile_filename = "#{@@directory}/#{@@lifter}_profile.json"
    get_profile_state
  end

  def date
    @@date
  end

  def buddies
    @@workout_state['buddies'] ||= []
  end

  def workout
    @@workout_state['workout']
  end

  def workout=(workout)
    @@workout_state['workout'] = workout
  end

  def workout_weights
    @@workout_state['workout_weights'] ||= {}
  end

  def sets
    @@workout_state['sets'] ||= {}
  end

  def successful_reps
    @@workout_state['successful_reps'] ||= {}
  end

  def target_weight(exercise, lifter)
    return DEFAULT_PROGRESSION[exercise]['initial_weight'] unless lifter.downcase == @@lifter

    @@profile_state['progression'] ||= DEFAULT_PROGRESSION

    @@profile_state['progression'][exercise]['initial_weight']
  end

  def get_workout_state
    if File.exist?(@@workout_filename)
      puts colourise("Loaded existing state from #{@@workout_filename}", :grey)
      @@workout_state = JSON.parse(File.read(@@workout_filename))
    else
      @@workout_state = {}
    end
  end

  def get_profile_state
    if File.exist?(@@profile_filename)
      puts colourise("Loaded existing state from #{@@profile_filename}", :grey)
      @@profile_state = JSON.parse(File.read(@@profile_filename))
    else
      @@profile_state = {}
    end
  end

  def flush_workout_state
    Dir.mkdir(@@directory) unless File.exist?(@@directory)

    File.open(@@workout_filename, File::CREAT|File::TRUNC|File::RDWR) do |f|
      f.write @@workout_state.to_json
    end
  end

  def flush_profile_state
    Dir.mkdir(@@directory) unless File.exist?(@@directory)

    File.open(@@profile_filename, File::CREAT|File::TRUNC|File::RDWR) do |f|
      f.write @@profile_state.to_json
    end
  end
end
