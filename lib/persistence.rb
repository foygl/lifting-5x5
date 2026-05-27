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
      @@date = Date.today
    else
      # Validate that this is in the right format
      begin
        @@date = Date.iso8601(date)
      rescue Date::Error
        puts colourise("Invalid date '#{date}'. Please use format YYYY-MM-DD", :red)
        exit 1
      end
    end

    @@workout_filename = "#{@@directory}/#{@@lifter}_#{@@date.iso8601}.json"
    get_workout_state
    @@profile_filename = profile_filename(@@lifter)
    get_profile_state

    if @@profile_state.key?('config')
      config = @@profile_state['config']
      $bar_weight = config['BAR_WEIGHT'] if config.key?('BAR_WEIGHT')
      if config.key?('PLATES')
        $plates.keys.each { |k| $plates[k] = 0 }
        config['PLATES'].each do |plate, count|
          if $plates.key?(plate.to_f)
            $plates[plate.to_f] = count
          elsif $plates.key?(plate.to_i)
            $plates[plate.to_i] = count
          else
            puts colourise("Warning: Ignoring unknown plate size #{plate} in profile config", :yellow)
          end
        end
      end
    end
  end

  def profile_filename(lifter)
    "#{@@directory}/#{lifter}_profile.json"
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
    if lifter.downcase == @@lifter
      target_weight_from_profile(@@profile_state, exercise)
    else
      if File.exist?(profile_filename(lifter.downcase))
        buddy_profile_state = JSON.parse(File.read(profile_filename(lifter.downcase)))
        target_weight_from_profile(buddy_profile_state, exercise)
      else
        DEFAULT_PROGRESSION[exercise]['initial_weight']
      end
    end
  end

  def target_weight_from_profile(profile, exercise)
    profile['progression'] ||= DEFAULT_PROGRESSION

    p = profile['progression'][exercise]
    c = current_progress(profile, exercise)

    if c.key?('successes') && c['successes'] >= p['successes_before_increment']
      puts colourise("Incrementing weight for #{exercise} by #{p['increment']} kg", :grey)
      c['last_weight'] + p['increment']
    elsif c.key?('failures') && c['failures'] >= p['failures_before_deload']
      puts colourise("Decrementing weight for #{exercise} by #{p['deload_percentage']}%", :grey)
      c['last_weight'] - (c['last_weight'] * p['deload_percentage'] / 100.0)
    elsif c.key?('failures') && c['failures'] > 0
      puts colourise("Keeping weight for #{exercise} the same due to previous failure", :grey)
      c['last_weight']
    elsif c.key?('successes') || c.key?('failures')
      c['last_weight']
    else
      p['initial_weight']
    end
  end

  def current_progress(profile, exercise)
    profile['current_progress'] ||= {}
    profile['current_progress'][exercise] ||= {}
  end

  def exercise_successful(exercise, weight)
    c = current_progress(@@profile_state, exercise)

    # Don't update the record if it has already been written
    return if !c['last_date'].nil? && Date.iso8601(c['last_date']) >= @@date

    c['last_date'] = @@date.iso8601
    if c['last_weight'] == weight
      c['successes'] += 1
    else
      c['last_weight'] = weight
      c['successes'] = 1
    end
    c['failures'] = 0
  end

  def exercise_unsuccessful(exercise, weight)
    c = current_progress(@@profile_state, exercise)

    # Don't update the record if it has already been written
    return if !c['last_date'].nil? && Date.iso8601(c['last_date']) >= @@date

    c['last_date'] = @@date.iso8601
    if c['last_weight'] == weight
      c['failures'] += 1
    else
      c['last_weight'] = weight
      c['failures'] = 1
    end
    c['successes'] = 0
  end

  def next_workout()
    return nil unless @@profile_state.key?('current_progress')

    last_barbell_row_date = @@profile_state['current_progress'][BARBELL_ROW]['last_date'] rescue nil
    last_deadlift_date = @@profile_state['current_progress'][DEADLIFT]['last_date'] rescue nil

    if last_barbell_row_date.nil?
      return WORKOUT_A
    elsif last_deadlift_date.nil?
      return WORKOUT_B
    else
      if Date.iso8601(last_barbell_row_date) > Date.iso8601(last_deadlift_date)
        return WORKOUT_B
      else
        return WORKOUT_A
      end
    end
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
      f.write JSON.pretty_generate(@@profile_state)
    end
  end
end
