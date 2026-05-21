#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'plate_change_minimiser'
require_relative 'values'

# Validate plate configuration
Raise 'Too many 0.25 kg plates' if PLATES[0.25] > 8
Raise 'Too many 1.25 kg plates' if PLATES[1.25] > 4
Raise 'Too many 2.5 kg plates' if PLATES[2.5] > 4
Raise 'Too many 5 kg plates' if PLATES[5] > 4
Raise 'Too many 10 kg plates' if PLATES[10] > 4
Raise 'Too many 15 kg plates' if PLATES[15] > 4
Raise 'Too many 20 kg plates' if PLATES[20] > 20
Raise 'Too many 25 kg plates' if PLATES[25] > 20

def calculate_plates(weight)
  if weight < BAR_WEIGHT
    puts "Weight must be greater than or equal to #{BAR_WEIGHT} kg."
    return nil
  end

  @plates_cache ||= {}
  return @plates_cache[weight] if @plates_cache.key?(weight)

  remaining_weight = weight - BAR_WEIGHT
  plates_needed = {}

  PLATES.sort.reverse.each do |plate_weight, quantity|
    break if remaining_weight <= 0

    plates_to_use = [quantity, 2 * (remaining_weight / (2 * plate_weight)).floor].min
    plates_needed[plate_weight] = plates_to_use if plates_to_use > 0
    remaining_weight -= plates_to_use * plate_weight
  end

  if remaining_weight > 0
    puts "Cannot achieve the desired weight with the available plates for weight #{weight}."
    return nil
  end

  # Convert the plate counts to a list of plates for each side of the bar
  @plates_cache[weight] = plates_needed.map { |weight, count| [weight] * (count / 2)  }.flatten.sort.reverse
end

def sanitise_weight_to_lift(weight, minimum_increment, max_weight = nil)
  weight = (weight / minimum_increment).floor * minimum_increment
  weight = [weight, BAR_WEIGHT].max

  while calculate_plates(weight) == nil || (max_weight && weight > max_weight)
    weight -= minimum_increment
  end

  weight
end

def calculate_warmup_sets(exercise, target_weight)
  return [] if target_weight < ADD_WARMUPS_THRESHOLD

  warmup_sets = WARMUP_SETS[exercise]

  warmup_sets.map do |set|
    warmup_weight = sanitise_weight_to_lift(target_weight * set['multiplier'], MINIMUM_WARMUP_INCREMENT, target_weight - MIN_WARMUP_WEIGHT_DIFFERENCE)

    # Skip warmup sets that are just the bar, unless it's the first set with no multiplier as the weight is too light to be useful
    next if warmup_weight == BAR_WEIGHT && set['multiplier'] > 0

    {
      'sets' => set['sets'],
      'reps' => set['reps'],
      'weight' => warmup_weight.to_f,
      'minimum_plates' => calculate_plates(warmup_weight)
    }
  end.compact
end

def calculate_workout(exercise, target_weight)
  start_time = Time.now

  target_weight = sanitise_weight_to_lift(target_weight, MINIMUM_INCREMENT)

  workout_sets = SETS[exercise]

  workout = minimise_plate_changes(
    calculate_warmup_sets(exercise, target_weight) + [{
      'sets' => workout_sets['sets'],
      'reps' => workout_sets['reps'],
      'weight' => target_weight.to_f,
      'minimum_plates' => calculate_plates(target_weight)
    }]
  )

  puts "Calculated workout sets in #{Time.now - start_time} seconds"

  workout
end

def colourise(text, colour, background = false)
  colours = {
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37,
    grey: 90,
    bright_red: 91,
    bright_green: 92,
    bright_yellow: 93,
    bright_blue: 94,
    bright_magenta: 95,
    bright_cyan: 96,
    bright_white: 97
  }
  colour_code = colours[colour] || 0
  colour_code += 10 if background
  "\e[#{colour_code}m#{text}\e[0m"
end

puts 'Select workout:'
puts " 1. Workout A (#{WORKOUT_A.join(', ')})"
puts " 2. Workout B (#{WORKOUT_B.join(', ')})"
while true
  workout_choice = gets.chomp.to_i
  workout = case workout_choice
            when 1
              WORKOUT_A
            when 2
              WORKOUT_B
            else
              puts 'Invalid choice. Please enter 1 or 2.'
              next
            end
  break
end

puts
puts "Selected workout: #{workout.join(', ')}"

PLATE_SEPARATOR = '│'
SHOW_MINIMUM_PLATES = false

def display_bar_and_plates(title, plates)
  bar_length = 8

  bar = colourise(' ' * bar_length, :grey, true)
  no_bar = ' ' * bar_length

  plate_titles_display = plates.map { |plate| colourise("#{plate} kg", PLATE_COLOURS[plate]) }.join(PLATE_SEPARATOR)
  plates_display = plates.map { |plate| colourise(" " * (plate.to_s.length + 3), PLATE_COLOURS[plate], true) }.join(PLATE_SEPARATOR)

  puts "  │ #{title}:"
  puts "  │   #{no_bar}#{plate_titles_display}"
  1.upto(3).each do |_|
    puts "  │   #{no_bar}#{plates_display}"
  end
  puts "  │   #{bar}#{plates_display}"
  1.upto(3).each do |_|
    puts "  │   #{no_bar}#{plates_display}"
  end
end

workout.each do |exercise|
  puts
  print "Enter target weight for #{exercise} (kg): "
  target_weight = gets.chomp.to_f
  sets = calculate_workout(exercise, target_weight)

  sets.each do |set|
    puts "#{colourise("#{set['sets']} sets", :green)} of #{colourise("#{set['reps']} reps", :yellow)} at #{set['weight']} kg"
    display_bar_and_plates('Recommended plates per side', set['plates']) unless set['plates'].empty?
    if SHOW_MINIMUM_PLATES && !set['minimum_plates'].empty? && set['minimum_plates'].sort != set['plates'].sort
      puts "  │"
      display_bar_and_plates('Minimum plates per side', set['minimum_plates'])
    end
  end
end
