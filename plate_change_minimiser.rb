#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'values'

# Monkey patch to calculate the difference/intersection between two arrays, taking into account duplicates
class Array
  def difference(other)
    h = other.each_with_object(Hash.new(0)) { |e,h| h[e] += 1  }
    reject { |e| h[e] > 0 && h[e] -= 1 }
  end

  def intersection(other)
    h = other.each_with_object(Hash.new(0)) { |e,h| h[e] += 1  }
    select { |e| h[e] > 0 && h[e] -= 1 }
  end
end

def minimise_plate_changes(sets)
  sets.each do |set|
    set['valid_plate_combinations'] = calculate_all_plate_combinations(set['plates'])
  end
  calculate_all_plate_changes(sets)
  pp build_plate_change_tree(sets)
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

def calculate_all_plate_changes(sets)
  sets.each_with_index do |set, index|
    if index > 0
      previous_set = sets[index - 1]
      previous_set['valid_plate_combinations'].each_with_index do |previous_combination, previous_combination_idx|
        set['valid_plate_combinations'].each_with_index do |current_combination, current_combination_idx|
          set['plate_changes'] ||= {}
          set['plate_changes'][previous_combination_idx] ||= {}
          set['plate_changes'][previous_combination_idx][current_combination_idx] = calculate_plate_changes(previous_combination, current_combination)
        end
      end
    end
  end
end

def calculate_plate_changes(current_plates, target_plates)
  shared_plates = current_plates.intersection(target_plates)
  current_plates_diff = current_plates.difference(shared_plates)
  target_plates_diff = target_plates.difference(shared_plates)

  # The number of plates that would have to be put on or taken off
  target_plates_diff.length + current_plates_diff.length
end

def build_plate_change_tree(sets, tree = {}, path_value = 0)
  # TODO: Implement me
#  return path_value if sets.empty?
#
#  current_set = sets.first
#  remaining_sets = sets[1..]
#
#  return build_plate_change_tree(remaining_sets) unless current_set.key?('plate_changes')
#
#  current_set['plate_changes'].each do |previous_combination_idx, changes|
#    tree[previous_combination_idx] ||= {}
#    changes.each do |current_combination_idx, change_count|
#      puts build_plate_change_tree(remaining_sets, tree[previous_combination_idx][current_combination_idx] ||= {}, path_value + change_count)
#    end
#  end
end
