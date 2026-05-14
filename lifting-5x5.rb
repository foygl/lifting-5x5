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

def calculate_warmup_sets(exercise, target_weight)
  warmup_sets = WARMUP_SETS[exercise]

  warmup_sets.map do |set|
    warmup_weight = (target_weight * set['multiplier']).round(MINIMUM_INCREMENT)
    warmup_weight = [warmup_weight, BAR_WEIGHT].max

    while calculate_plates(warmup_weight) == nil
      warmup_weight -= MINIMUM_INCREMENT
    end

    # Skip warmup sets that are just the bar, unless it's the first set with no multiplier as the weight is too light to be useful
    next if warmup_weight == BAR_WEIGHT && set['multiplier'] > 0

    {
      'sets' => set['sets'],
      'reps' => set['reps'],
      'weight' => warmup_weight,
      'plates' => calculate_plates(warmup_weight)
    }
  end.compact
end

def calculate_workout(exercise, target_weight)
  target_weight = target_weight.round(MINIMUM_INCREMENT)
  target_weight = [target_weight, BAR_WEIGHT].max

  while calculate_plates(target_weight) == nil
    target_weight -= MINIMUM_INCREMENT
  end

  workout_sets = SETS[exercise]

  calculate_warmup_sets(exercise, target_weight) + [{
    'sets' => workout_sets['sets'],
    'reps' => workout_sets['reps'],
    'weight' => target_weight,
    'plates' => calculate_plates(target_weight)
  }]
end

#puts calculate_plates(ARGV[0].to_f)
puts calculate_workout(SQUAT, ARGV[0].to_f)
