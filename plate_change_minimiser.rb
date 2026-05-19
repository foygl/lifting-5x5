#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'values'

DEBUG = false

def minimise_plate_changes(sets)
  sets.each do |set|
    set['valid_plate_combinations'] = calculate_all_plate_combinations(set['weight'])
  end
  #pp sets if DEBUG
  tree = build_plate_change_tree(sets).first
  pp tree if DEBUG
  sets.each_with_index do |set, index|
    # Just pick the first valid minimum path if there are multiple with the same value
    set['plates'] = set['valid_plate_combinations'][tree.keys.first]
    tree = tree.values.first
    # We don't need this anymore as we have calculated the best plate combination
    set.delete('valid_plate_combinations')
  end

  # Should have traversed the whole tree at this point and so "tree" should be a leaf
  raise "Invalid plate change tree generated" unless tree.is_a?(Float) || tree.is_a?(Integer)

  sets
end

def calculate_all_plate_combinations(weight)
  # For this calculation, consider just half the weight, since the same plates will be on both sides of the bar
  plate_weight = (weight - BAR_WEIGHT) / 2
  @available_plates ||= PLATES.map { |weight, count| [weight] * (count / 2) }.flatten.sort.reverse

  combinations = calculate_plate_combinations(@available_plates, plate_weight)

  # Get all permutations of each combination to account for different plate arrangements on the bar
  combinations.flat_map { |combination| combination.permutation.to_a.uniq }
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
  # Remove any common prefix of plates from the two arrays
  until current_plates.empty? || target_plates.empty? || current_plates.first != target_plates.first
    current_plates = current_plates[1..]
    target_plates = target_plates[1..]
  end

  # The number of plates that would have to be put on or taken off will be prioritised
  # The total weight of plates that would have to be put on or taken off will be used as a tiebreaker
  (target_plates.length + current_plates.length).to_f * 10**6 + (target_plates.sum + current_plates.sum)
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
# Then the (unpruned) tree would look like:
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
# And the pruned tree would look like:
# {0 => {0 => {2 => 3}}}
def build_plate_change_tree(sets, branch_number = nil, previous_plate_combination = [], path_value = 0)
  current_set = sets.first
  remaining_sets = sets[1..]

  unless current_set.key?('valid_plate_combinations')
    raise "Expected 'valid_plate_combinations' to have been pre-calculated for each set before building the tree"
  end

  valid_plate_combinations = current_set['valid_plate_combinations']

  if !valid_plate_combinations.flatten.empty?
    lowest_discovered_change_value = Float::INFINITY

    subtrees = valid_plate_combinations.each_with_index.map do |plate_combination, current_branch_number|
      change_value = calculate_plate_changes(previous_plate_combination, plate_combination)

      # This branch cannot be part of the optimal path, so skip it
      next if change_value > lowest_discovered_change_value

      lowest_discovered_change_value = change_value

      if remaining_sets.empty?
        [{ current_branch_number => path_value + change_value }, path_value + change_value]
      else
        build_plate_change_tree(
          remaining_sets,
          current_branch_number,
          plate_combination,
          path_value + change_value
        )
      end
    end.compact

    # Prune the tree as we build it to only include the path(s) with the lowest total plate change value
    min_value = subtrees.map(&:last).min
    subtree = subtrees.select { |_, value| value == min_value }.map(&:first).reduce(:merge)

    if branch_number.nil?
      [subtree, min_value]
    else
      [{ branch_number => subtree }, min_value]
    end
  elsif remaining_sets.empty?
    # This will be an empty bar set that is also the last set
    # Setting the current branch number to 0 as there is only one option for the plate combination (no plates)
    if branch_number.nil?
      [{ 0 => path_value }, path_value]
    else
      [{ branch_number => { 0 => path_value } }, path_value]
    end
  else
    # This will be an empty bar set which has no plates
    build_plate_change_tree(remaining_sets, 0, [], path_value)
  end
end
