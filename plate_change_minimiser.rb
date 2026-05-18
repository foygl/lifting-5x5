#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'values'

# Monkey patch to calculate the difference/intersection between two arrays, taking into account duplicates
class Array
  def difference(other)
    h = other.each_with_object(Hash.new(0)) { |e, h| h[e] += 1 }
    reject { |e| h[e] > 0 && h[e] -= 1 }
  end

  def intersection(other)
    h = other.each_with_object(Hash.new(0)) { |e, h| h[e] += 1 }
    select { |e| h[e] > 0 && h[e] -= 1 }
  end
end

def minimise_plate_changes(sets)
  sets.each do |set|
    set['valid_plate_combinations'] = calculate_all_plate_combinations(set['plates'])
  end
  pp build_plate_change_tree(sets)
  sets
end

def calculate_all_plate_combinations(plates)
  # For this calculation, consider just half the weight, since the same plates will be on both sides of the bar
  plate_weight = plates.map { |weight, count| weight * (count / 2) }.sum
  @available_plates ||= PLATES.map { |weight, count| [weight] * (count / 2) }.flatten.sort.reverse

  calculate_plate_combinations(@available_plates, plate_weight)
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
  with_first = calculate_plate_combinations(
    remaining_plates,
    target_weight - first_plate
  ).map { |combination| [first_plate] + combination }

  # Exclude the first plate
  without_first = calculate_plate_combinations(remaining_plates, target_weight)

  # Combine results and remove duplicates
  (with_first + without_first).uniq
end

def calculate_plate_changes(current_plates, target_plates)
  shared_plates = current_plates.intersection(target_plates)
  current_plates_diff = current_plates.difference(shared_plates)
  target_plates_diff = target_plates.difference(shared_plates)

  # The number of plates that would have to be put on or taken off
  target_plates_diff.length + current_plates_diff.length
end

# If the input sets are:
# [{"weight" => 15.0, "valid_plate_combinations" => [[]]},
#  {"weight" => 40.0,
#   "valid_plate_combinations" =>
#    [[10, 2.5],
#    [10, 1.25, 1.25],
#    [5, 5, 2.5],
#    [5, 5, 1.25, 1.25],
#    [5, 2.5, 2.5, 1.25, 1.25]]},
#  {"weight" => 60.0,
#   "valid_plate_combinations" =>
#    [[20, 2.5],
#     [20, 1.25, 1.25],
#     [10, 10, 2.5],
#     [10, 10, 1.25, 1.25],
#     [10, 5, 5, 2.5],
#     [10, 5, 5, 1.25, 1.25],
#     [10, 5, 2.5, 2.5, 1.25, 1.25]]}]
# Then the tree would look like:
# {
#   0 => {
#     0 => {
#       0 => 4,
#       1 => 7,
#       2 => 3, <- best path [10, 2.5] -> [10, 10, 2.5]
#       3 => 6,
#       4 => 4,
#       5 => 7,
#       6 => 6
#     },
#     1 => {
#       0 => 8,
#       1 => 5,
#       2 => 7,
#       3 => 4,
#       4 => 8,
#       5 => 5,
#       6 => 6
#     },
#     2 => {
#       0 => 6,
#       1 => 9,
#       2 => 7,
#       3 => 10,
#       4 => 4, <- unusual short path [5, 5, 2.5] -> [10, 5, 5, 2.5]
#       5 => 7,
#       6 => 8
#     },
#     3 => {
#       0 => 10,
#       1 => 7,
#       2 => 11,
#       3 => 8,
#       4 => 8,
#       5 => 5,
#       6 => 8
#     },
#     4 => {
#       0 => 10,
#       1 => 9,
#       2 => 11,
#       3 => 10,
#       4 => 10,
#       5 => 9,
#       6 => 6
#     }
#   },
# }
def build_plate_change_tree(sets, branch_number = 0, previous_plate_combination = [], path_value = 0)
  current_set = sets.first
  remaining_sets = sets[1..]

  unless current_set.key?('valid_plate_combinations')
    raise "Expected 'valid_plate_combinations' to have been pre-calculated for each set before building the tree"
  end

  valid_plate_combinations = current_set['valid_plate_combinations']

  if !valid_plate_combinations.flatten.empty?
    subtree = valid_plate_combinations.each_with_index.map do |plate_combination, current_branch_number|
      change_value = calculate_plate_changes(previous_plate_combination, plate_combination)
      if remaining_sets.empty?
        { current_branch_number => path_value + change_value }
      else
        build_plate_change_tree(
          remaining_sets,
          current_branch_number,
          plate_combination,
          path_value + change_value
        )
      end
    end.reduce(:merge)

    # If there are no remaining sets prune away all but the best paths from the leaf nodes to simplify
    # later best path calculations
    if remaining_sets.empty?
      min_value = subtree.values.min
      subtree.select! { |_, value| value == min_value }
    end

    { branch_number => subtree }
  elsif remaining_sets.empty?
    # This will be an empty bar set that is also the last set
    { branch_number => path_value }
  else
    # This will be an empty bar set which has no plates
    build_plate_change_tree(remaining_sets, branch_number, [], path_value)
  end
end
