#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'values'

def minimise_plate_changes(sets)
  # TODO implement this
  #sets.each do |set|
  #  puts "Calculating combinations for weight #{set['weight']} with plates #{set['plates']}"
  #  pp calculate_all_plate_combinations(set['plates'])
  #end
  sets
end

def calculate_all_plate_combinations(plates)
  # For this calculation, consider just half the weight, since the same plates will be on both sides of the bar
  plate_weight = plates.map { |weight, count| weight * (count / 2) }.sum
  @available_plates ||= PLATES.map { |weight, count| [weight] * (count / 2) }.flatten.sort.reverse

  combinations = calculate_plate_combinations(@available_plates, plate_weight)

  # pp combinations
end

def calculate_plate_combinations(plates, target_weight)
  # Base case: if the target weight is 0, we found a valid combination
  return [[]] if target_weight == 0

  # Base case: if the target weight is negative or we have no plates left, no valid combination
  return [] if target_weight < 0 || plates.empty?

  # Recursive case: include the first plate and exclude it
  first_plate = plates.first
  remaining_plates = plates[1..]

  # Include the first plate
  with_first = calculate_plate_combinations(remaining_plates, target_weight - first_plate).map { |combination| [first_plate] + combination }

  # Exclude the first plate
  without_first = calculate_plate_combinations(remaining_plates, target_weight)

  # Combine results and remove duplicates
  (with_first + without_first).uniq
end

