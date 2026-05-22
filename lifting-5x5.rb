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

PLATE_SEPARATOR = '│'
SHOW_MINIMUM_PLATES = false

def calculate_plates(weight)
  if weight < BAR_WEIGHT
    puts colourise("Weight must be greater than or equal to #{BAR_WEIGHT} kg.", :red)
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
    puts colourise("Cannot achieve the desired weight with the available plates for weight #{weight}.", :yellow)
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

def calculate_warmup_sets(exercise, target_weight, lifter)
  return [] if target_weight < ADD_WARMUPS_THRESHOLD

  warmup_sets = WARMUP_SETS[exercise]

  warmup_sets.map do |set|
    warmup_weight = sanitise_weight_to_lift(target_weight * set['multiplier'], MINIMUM_WARMUP_INCREMENT, target_weight - MIN_WARMUP_WEIGHT_DIFFERENCE)

    # Skip warmup sets that are just the bar, unless it's the first set with no multiplier as the weight is too light to be useful
    next if warmup_weight == BAR_WEIGHT && set['multiplier'] > 0

    {
      'lifter' => lifter,
      'name' => set['name'],
      'sets' => set['sets'],
      'reps' => set['reps'],
      'weight' => warmup_weight.to_f,
      'minimum_plates' => calculate_plates(warmup_weight)
    }
  end.compact
end

def calculate_workout(exercise, target_weight, buddy_target_weights = [])
  start_time = Time.now

  target_weight = sanitise_weight_to_lift(target_weight, MINIMUM_INCREMENT)

  buddy_target_weights.each_with_index do |buddys_target_weight, i|
    buddy_target_weights[i] = sanitise_weight_to_lift(buddys_target_weight, MINIMUM_INCREMENT)
  end

  workout_sets = SETS[exercise]

  workout = calculate_warmup_sets(exercise, target_weight, :me) + [{
              'lifter' => :me,
              'name' => 'Working sets',
              'sets' => workout_sets['sets'],
              'reps' => workout_sets['reps'],
              'weight' => target_weight.to_f,
              'minimum_plates' => calculate_plates(target_weight)
            }]

  # If the target weight is just the bar then there are no warmups and no plate changes so we can skip all the buddy calculations
  return minimise_plate_changes(workout) if target_weight == BAR_WEIGHT

  buddy_workouts = buddy_target_weights.map do |buddys_target_weight|
    calculate_warmup_sets(exercise, buddys_target_weight, :buddy) + [{
      'lifter' => :buddy,
      'name' => 'Working sets',
      'sets' => workout_sets['sets'],
      'reps' => workout_sets['reps'],
      'weight' => buddys_target_weight.to_f,
      'minimum_plates' => calculate_plates(buddys_target_weight)
    }]
  end

  # Interleave all workouts
  interleaved_workouts = []
  WARMUP_SETS[exercise].each do |set|
    set_name = set['name']
    workout_set = workout.find { |s| s['name'] == set_name }
    interleaved_workouts << workout_set unless workout_set.nil?
    buddy_workouts.each do |buddy_workout|
      buddy_workout_set = buddy_workout.find { |s| s['name'] == set_name }
      interleaved_workouts << buddy_workout_set unless buddy_workout_set.nil? || buddy_workout_set['weight'] == BAR_WEIGHT
    end
  end
  interleaved_workouts << workout.find { |s| s['name'] == 'Working sets' }
  buddy_workouts.each do |buddy_workout|
    buddy_workout_set = buddy_workout.find { |s| s['name'] == 'Working sets' }
    interleaved_workouts << buddy_workout_set unless buddy_workout_set.nil? || buddy_workout_set['weight'] == BAR_WEIGHT
  end

  interleaved_workouts.sort_by! { |s| [s['name'], s['weight']] }

  # Remove buddy sets that are the same weight as an adjacent me set to simplify the minimisation algorithm
  # Note that most warmups are only one set so we don't really need to do anything more complex for minimisation
  interleaved_workouts.each_with_index do |set, index|
    next if index == 0

    previous_set = interleaved_workouts[index - 1]
    next unless set['lifter'] == :buddy || previous_set['lifter'] == :buddy

    if set['weight'] == previous_set['weight']
      set['remove'] = true if set['lifter'] == :buddy
      previous_set['remove'] = true if previous_set['lifter'] == :buddy
    end
  end
  interleaved_workouts.reject! { |set| set['remove'] }

  workout = minimise_plate_changes(interleaved_workouts).select { |w| w['lifter'] == :me }

  puts colourise("Calculated workout sets in #{Time.now - start_time} seconds", :grey)

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

print 'Who is lifting?: '
whoami = gets.chomp
whoami = 'Anon' if whoami.empty?

buddies = []
while true
  print 'Add a buddy: '
  buddy = gets&.chomp

  break if buddy.nil? || buddy.empty?

  buddies << buddy
end

puts
puts "#{whoami} is lifting#{" with " unless buddies.empty?}#{buddies.join(', ')}"
puts

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
              puts colourise('Invalid choice. Please enter 1 or 2.', :yellow)
              next
            end
  break
end

puts
puts colourise("Selected workout: #{workout.join(', ')}", :grey)

workout_weights = {}

puts

workout.each do |exercise|
  for person in [whoami] + buddies
    print "Enter #{person}'s target weight for #{exercise} (kg): "
    target_weight = gets.chomp.to_f
    target_weight = sanitise_weight_to_lift(target_weight, MINIMUM_INCREMENT)

    workout_weights[person] ||= {}
    workout_weights[person][exercise] = target_weight
  end
end

workout.each do |exercise|
  target_weight = workout_weights[whoami][exercise]

  puts
  puts "Exercise: #{exercise} at #{target_weight} kg"

  sets = calculate_workout(exercise, target_weight, buddies.map { |b| workout_weights[b][exercise] })

  puts "  ┌────────────── Exercise Summary ──────────────┐"
  sets.each do |set|
    # Need to calculate the displayed text width separately because of the later addition of colour codes
    text_width = set['name'].length + 2 + set['sets'].to_s.length + 9 + set['reps'].to_s.length + 9 + set['weight'].to_s.length + 3
    set['summary'] = "#{set['name']}: #{colourise("#{set['sets']} sets", :green)} of #{colourise("#{set['reps']} reps", :yellow)} at #{set['weight']} kg"
    puts "  │ #{set['summary']}#{" "* (45 - text_width)}│"
  end
  puts "  └──────────────────────────────────────────────┘"


  sets.each_with_index do |set, set_number|
    puts set['summary']
    display_bar_and_plates('Recommended plates per side', set['plates']) unless set['plates'].empty?
    if SHOW_MINIMUM_PLATES && !set['minimum_plates'].empty? && set['minimum_plates'].sort != set['plates'].sort
      puts "  │"
      display_bar_and_plates('Minimum plates per side', set['minimum_plates'])
    end

    set_completion_results = []

    for i in 1..set['sets']
      print "  │ Successful reps for set #{i} of #{set['sets']} [#{set['reps']}]: "
      successful_reps = gets.chomp
      successful_reps = set['reps'] if successful_reps.empty?
      successful_reps = successful_reps.to_i

      if successful_reps < set['reps']
        puts colourise("  │ Only #{successful_reps} reps completed. Consider reducing the weight next time.", :red)
      end

      set_completion_results << successful_reps

      unless set_number == sets.length
        cooldown_time = successful_reps < set['reps'] ? COOLDOWN_SECONDS_ON_FAILURE : COOLDOWN_SECONDS_ON_SUCCESS

        begin
          cooldown_time.downto(1).each do |t|
            print "  │ Wait #{colourise(t, :bright_white)} seconds before next set (ctrl+c to interrupt)\033[0K\r"
            sleep(1)
            # Clear the contents of the current line
            print "\033[0K\r"
          end
        rescue Interrupt
          puts "\n  │ Cooldown interrupted. Proceeding to next set."
        end

        `command -v espeak && espeak "Time for the next set #{whoami}"`
      end
    end
    puts "  │ #{colourise("Finished sets: #{set_completion_results.join(', ')}", :cyan)}"
  end
end
