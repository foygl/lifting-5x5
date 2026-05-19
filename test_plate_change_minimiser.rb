#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'plate_change_minimiser'

#for i in 15..400
#  puts "Checking valid plate combinations for #{i}kg"
#  puts "❌ No valid plate combinations for #{i}kg" if calculate_all_plate_combinations(i).length == 0
#  puts "Checking valid plate combinations for #{i}.5kg"
#  puts "❌ No valid plate combinations for #{i}.5kg" if calculate_all_plate_combinations(i + 0.5).length == 0
#end

DEBUG = true

test1 = [{"weight" => 15.0},
         {"weight" => 40.0},
         {"weight" => 60.0},
         {"weight" => 80.0},
         {"weight" => 100.0}]

test1_expected = [{"weight" => 15.0, "plates" => []},
                  {"weight" => 40.0, "plates" => [10, 2.5]},
                  {"weight" => 60.0, "plates" => [10, 2.5, 10]},
                  {"weight" => 80.0, "plates" => [10, 2.5, 20]},
                  {"weight" => 100.0, "plates" => [10, 2.5, 20, 10]}]


test2 = [{"weight" => 15.0},
         {"weight" => 20.0},
         {"weight" => 30.0},
         {"weight" => 45.0},
         {"weight" => 56.5}]

test2_expected = [{"weight" => 15.0, "plates" => []},
                  {"weight" => 20.0, "plates" => [2.5]},
                  {"weight" => 30.0, "plates" => [2.5, 5]},
                  {"weight" => 45.0, "plates" => [2.5, 10, 2.5]},
                  {"weight" => 56.5, "plates" => [2.5, 10, 2.5, 5, 0.25, 0.25, 0.25]}]

test3 = [{"weight" => 15.0},
         {"weight" => 40.0},
         {"weight" => 60.0}]

test3_expected = [{"weight" => 15.0, "plates" => []},
                  {"weight" => 40.0, "plates" => [10, 2.5]},
                  {"weight" => 60.0, "plates" => [10, 2.5, 10]}]

test4 = [{"weight" => 15.0}]

test4_expected = [{"weight" => 15.0, "plates" => []}]

test5 = [{"weight" => 20.0},
         {"weight" => 25.0},
         {"weight" => 30.0}]

test5_expected = [{"weight" => 20.0, "plates" => [2.5]},
                  {"weight" => 25.0, "plates" => [2.5, 2.5]},
                  {"weight" => 30.0, "plates" => [2.5, 2.5, 1.25, 1.25]}]

test6 = [{"weight" => 15.0},
         {"weight" => 15.0}]

test6_expected = [{"weight" => 15.0, "plates" => []},
                  {"weight" => 15.0, "plates" => []}]

test7 = [{"weight" => 120.0}]

test7_expected = [{"weight" => 120.0, "plates" => [20, 10, 10, 5, 5, 2.5]}]

test8 = [
  {"weight" => 15.0},
  {"weight" => 45.0},
  {"weight" => 70.0},
  {"weight" => 95.0},
  {"weight" => 120.0}
]

test8_expected = [
  {"weight" => 15.0, "plates" => []},
  {"weight" => 45.0, "plates" => [10, 5]},
  {"weight" => 70.0, "plates" => [10, 5, 2.5, 10]},
  {"weight" => 95.0, "plates" => [10, 5, 2.5, 20, 2.5]},
  {"weight" => 120.0, "plates" => [10, 5, 2.5, 20, 2.5, 10, 1.25, 1.25]}
]

# 126 seems fine ([20, 10, 10, 5, 5, 2.5, 2.5]), but 128.5 gets stuck calculating
# "Found 5670 valid combinations for 126"
# "Found 226800 valid combinations for 128.5"
# "Found 1247400 valid combinations for 132"
# Added in a simplified permutation calculator for when we reach this threshold
test9 = [{"weight" => 132.0}]

test9_expected = [{"weight" => 132, "plates" => [20, 10, 10, 5, 5, 2.5, 2.5, 1.25, 1.25, 0.25, 0.25, 0.25, 0.25]}]

def test_minimise_plate_changes(test_title, test_input, test_expected)
  puts "#{test_title}:"
  test_result =  minimise_plate_changes(test_input)
  pp test_result
  puts test_result == test_expected ? "✅ Test passed" : "❌ Test failed"
  puts
end

test_minimise_plate_changes("Example 1", test1, test1_expected)
test_minimise_plate_changes("Example 2", test2, test2_expected)
test_minimise_plate_changes("Example 3", test3, test3_expected)
test_minimise_plate_changes("Example 4", test4, test4_expected)
test_minimise_plate_changes("Example 5", test5, test5_expected)
test_minimise_plate_changes("Example 6", test6, test6_expected)
test_minimise_plate_changes("Example 7", test7, test7_expected)
test_minimise_plate_changes("Example 8", test8, test8_expected)
test_minimise_plate_changes("Example 9", test9, test9_expected)

#calculate_all_plate_combinations test1.last['plates']


puts calculate_plate_changes([5, 2.5], [5, 5, 2.5, 2.5])
puts
puts calculate_plate_changes([5, 2.5], [10, 2.5, 2.5])
puts
puts calculate_plate_changes([5, 2.5], [10, 5])
puts
puts calculate_plate_changes([5, 2.5, 2.5], [5, 5, 2.5, 2.5])

#pp calculate_all_plate_combinations(30)
#pp calculate_all_plate_combinations(35)
#pp calculate_all_plate_combinations(37)
#pp calculate_all_plate_combinations(40)
#pp calculate_all_plate_combinations(132)
