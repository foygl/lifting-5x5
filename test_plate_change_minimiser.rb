#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'plate_change_minimiser'

DEBUG = true

test1 = [{"weight" => 15.0},
         {"weight" => 40.0},
         {"weight" => 60.0},
         {"weight" => 80.0},
         {"weight" => 100.0}]

test1_expected = [{"weight" => 15.0, "plates" => {}},
                  {"weight" => 40.0, "plates" => {10 => 2, 2.5 => 2}},
                  {"weight" => 60.0, "plates" => {10 => 4, 2.5 => 2}},
                  {"weight" => 80.0, "plates" => {20 => 1, 10 => 4, 2.5 => 2}},
                  {"weight" => 100.0, "plates" => {20 => 2, 10 => 4, 2.5 => 2}}]


test2 = [{"weight" => 15.0},
         {"weight" => 20.0},
         {"weight" => 30.0},
         {"weight" => 45.0},
         {"weight" => 56.5}]

test2_expected = [{"weight" => 15.0, "plates" => {}},
                  {"weight" => 20.0, "plates" => {2.5 => 2}},
                  {"weight" => 30.0, "plates" => {5 => 2, 2.5 => 2}},
                  {"weight" => 45.0, "plates" => {10 => 2, 5 => 2}},
                  {"weight" => 56.5, "plates" => {10 => 2, 5 => 4, 0.25 => 6}}]

test3 = [{"weight" => 15.0},
         {"weight" => 40.0},
         {"weight" => 60.0}]

test3_expected = [{"weight" => 15.0, "plates" => {}},
                  {"weight" => 40.0, "plates" => {10 => 2, 2.5 => 2}},
                  {"weight" => 60.0, "plates" => {10 => 4, 2.5 => 2}}]

test4 = [{"weight" => 15.0}]

test4_expected = [{"weight" => 15.0, "plates" => {}}]

test5 = [{"weight" => 20.0},
         {"weight" => 25.0},
         {"weight" => 30.0}]

test5_expected = [{"weight" => 20.0, "plates" => [2.5]},
                  {"weight" => 25.0, "plates" => [2.5, 2.5]},
                  {"weight" => 30.0, "plates" => [2.5, 2.5, 1.25, 1.25]}]

test6 = [{"weight" => 15.0},
         {"weight" => 15.0}]

puts "Example 1:"
pp minimise_plate_changes(test1)
puts
puts "Example 2:"
pp minimise_plate_changes(test2)
puts
puts "Example 3:"
pp minimise_plate_changes(test3)
puts
puts "Example 4:"
pp minimise_plate_changes(test4)
puts
puts "Example 5:"
pp minimise_plate_changes(test5)
puts
puts "Example 6:"
pp minimise_plate_changes(test6)
puts

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
#pp calculate_all_plate_combinations(50)
