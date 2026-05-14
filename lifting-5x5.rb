#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'values'

def calculate_plates(weight)
  if weight < BAR_WEIGHT
    puts "Weight must be greater than or equal to #{BAR_WEIGHT} kg."
    return nil
  end

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

  plates_needed
end

def minimise_plate_changes(previous_set_plates, target_set_plates)
  # TODO implement this
  target_set_plates
end

def sanitise_weight_to_lift(weight, minimum_increment)
  weight = (weight / minimum_increment).floor * minimum_increment
  weight = [weight, BAR_WEIGHT].max

  while calculate_plates(weight) == nil
    weight -= minimum_increment
  end

  weight
end

def calculate_warmup_sets(exercise, target_weight)
  warmup_sets = WARMUP_SETS[exercise]

  warmup_sets.map do |set|
    warmup_weight = sanitise_weight_to_lift(target_weight * set['multiplier'], MINIMUM_WARMUP_INCREMENT)

    # Skip warmup sets that are just the bar, unless it's the first set with no multiplier as the weight is too light to be useful
    next if warmup_weight == BAR_WEIGHT && set['multiplier'] > 0

    {
      'sets' => set['sets'],
      'reps' => set['reps'],
      'weight' => warmup_weight.to_f,
      'plates' => calculate_plates(warmup_weight)
    }
  end.compact
end

def calculate_workout(exercise, target_weight)
  target_weight = sanitise_weight_to_lift(target_weight, MINIMUM_INCREMENT)

  workout_sets = SETS[exercise]

  calculate_warmup_sets(exercise, target_weight) + [{
    'sets' => workout_sets['sets'],
    'reps' => workout_sets['reps'],
    'weight' => target_weight.to_f,
    'plates' => calculate_plates(target_weight)
  }]
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

workout.each do |exercise|
  puts
  print "Enter target weight for #{exercise} (kg): "
  target_weight = gets.chomp.to_f
  sets = calculate_workout(exercise, target_weight)

  previous_set_plates = {}

  sets.each do |set|
    set_plates = minimise_plate_changes(previous_set_plates, set['plates'])
    previous_set_plates = set_plates

    plates = " | Plates per side: #{set['plates'].map { |plate, quantity| "#{quantity / 2} x #{plate} kg" }.join(', ')}" unless set_plates.empty?
    puts "#{set['sets']} sets of #{set['reps']} reps at #{set['weight']} kg#{plates}"
  end
end
