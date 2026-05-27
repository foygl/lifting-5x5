#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'config/values'
require_relative 'lib/charts'
require_relative 'lib/persistence'
require_relative 'lib/plate_change_minimiser'
require_relative 'lib/util'

require 'io/console'
require 'monitor'

PLATE_SEPARATOR = '│'
SHOW_MINIMUM_PLATES = false

def calculate_plates(weight)
  if weight < $bar_weight[$unit]
    puts colourise("Weight must be greater than or equal to #{$bar_weight[$unit]} #{$unit}.", :red)
    return nil
  end

  @plates_cache ||= {}
  return @plates_cache[weight] if @plates_cache.key?(weight)

  remaining_weight = weight - $bar_weight[$unit]
  plates_needed = {}

  $plates[$unit].sort.reverse.each do |plate_weight, quantity|
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
  weight = ((weight - $bar_weight[$unit]) / minimum_increment).floor * minimum_increment + $bar_weight[$unit]
  weight = [weight, $bar_weight[$unit]].max

  while calculate_plates(weight) == nil || (max_weight && weight > max_weight)
    weight -= minimum_increment
  end

  weight
end

def calculate_warmup_sets(exercise, target_weight, lifter)
  return [] if target_weight < ADD_WARMUPS_THRESHOLD[$unit]

  warmup_sets = WARMUP_SETS[exercise]

  warmup_sets.map do |set|
    warmup_weight = sanitise_weight_to_lift(target_weight * set['multiplier'], MINIMUM_WARMUP_INCREMENT[$unit], target_weight - MIN_WARMUP_WEIGHT_DIFFERENCE[$unit])

    # Skip warmup sets that are just the bar, unless it's the first set with no multiplier as the weight is too light to be useful
    next if warmup_weight == $bar_weight[$unit] && set['multiplier'] > 0

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

  target_weight = sanitise_weight_to_lift(target_weight, minimum_increment)

  buddy_target_weights.each_with_index do |buddys_target_weight, i|
    buddy_target_weights[i] = sanitise_weight_to_lift(buddys_target_weight, minimum_increment)
  end

  workout_sets = SETS[exercise]

  workout = calculate_warmup_sets(exercise, target_weight, :me) + [{
              'lifter' => :me,
              'name' => WORKING_SETS_LABEL,
              'sets' => workout_sets['sets'],
              'reps' => workout_sets['reps'],
              'weight' => target_weight.to_f,
              'minimum_plates' => calculate_plates(target_weight)
            }]

  # If the target weight is just the bar then there are no warmups and no plate changes so we can skip all the buddy calculations
  return minimise_plate_changes(workout) if target_weight == $bar_weight[$unit]

  buddy_workouts = buddy_target_weights.map do |buddys_target_weight|
    calculate_warmup_sets(exercise, buddys_target_weight, :buddy) + [{
      'lifter' => :buddy,
      'name' => WORKING_SETS_LABEL,
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
      interleaved_workouts << buddy_workout_set unless buddy_workout_set.nil? || buddy_workout_set['weight'] == $bar_weight[$unit]
    end
  end
  interleaved_workouts << workout.find { |s| s['name'] == WORKING_SETS_LABEL }
  buddy_workouts.each do |buddy_workout|
    buddy_workout_set = buddy_workout.find { |s| s['name'] == WORKING_SETS_LABEL }
    interleaved_workouts << buddy_workout_set unless buddy_workout_set.nil? || buddy_workout_set['weight'] == $bar_weight[$unit]
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

def display_bar_and_plates(title, plates)
  bar_weight_label = " #{$bar_weight[$unit]} #{$unit} "
  bar_length = [9, bar_weight_label.length].max

  bar = colourise(' ' * bar_length, :grey, true)
  no_bar = ' ' * bar_length
  bar_weight = colourise("#{' ' * ((bar_length - bar_weight_label.length) / 2.0).floor}#{bar_weight_label}#{' ' * ((bar_length - bar_weight_label.length) / 2.0).ceil}", :grey)

  plate_titles_display = plates.map { |plate| colourise("#{plate} #{$unit}", PLATE_COLOURS[$unit][plate]) }.join(PLATE_SEPARATOR)
  plates_display = plates.map { |plate| colourise(" " * (plate.to_s.length + 1 + $unit.length), PLATE_COLOURS[$unit][plate], true) }.join(PLATE_SEPARATOR)

  puts "  │ #{title}:"
  puts "  │   #{no_bar}#{plate_titles_display}"
  1.upto(2).each do |_|
    puts "  │   #{no_bar}#{plates_display}"
  end
  puts "  │   #{bar_weight}#{plates_display}"
  puts "  │   #{bar}#{plates_display}"
  1.upto(3).each do |_|
    puts "  │   #{no_bar}#{plates_display}"
  end
end

def format_set_completion_results(set_completion_results)
  set_completion_results.map do |r|
    colourise("#{r['actual']}/#{r['target']}", r['actual'] < r['target'] ? :red : :green)
  end.join(', ')
end

whoami = ARGV[0] if ARGV.length >= 1
date = ARGV[1] if ARGV.length >= 2
ARGV.clear

if whoami.nil?
  print 'Who is lifting?: '
  whoami = gets.chomp
  whoami = 'Anon' if whoami.empty?
end

p = Persistence.new(whoami, date)

# Validate plate configuration (kg)
raise 'Too many 0.25 kg plates' if $plates['kg'][0.25] > 8
raise 'Too many 1.25 kg plates' if $plates['kg'][1.25] > 4
raise 'Too many 2.5 kg plates' if $plates['kg'][2.5] > 4
raise 'Too many 5 kg plates' if $plates['kg'][5] > 4
raise 'Too many 10 kg plates' if $plates['kg'][10] > 4
raise 'Too many 15 kg plates' if $plates['kg'][15] > 4
raise 'Too many 20 kg plates' if $plates['kg'][20] > 20
raise 'Too many 25 kg plates' if $plates['kg'][25] > 20
# Validate plate configuration (lbs)
raise 'Too many 2.5 lbs plates' if $plates['lbs'][2.5] > 4
raise 'Too many 5 lbs plates' if $plates['lbs'][5] > 4
raise 'Too many 10 lbs plates' if $plates['lbs'][10] > 4
raise 'Too many 25 lbs plates' if $plates['lbs'][25] > 4
raise 'Too many 35 lbs plates' if $plates['lbs'][35] > 4
raise 'Too many 45 lbs plates' if $plates['lbs'][45] > 20
raise 'Too many 55 lbs plates' if $plates['lbs'][55] > 20

puts "Welcome #{whoami}. Here is your current progress:"

print_progress_charts(whoami)
puts

if p.buddies.empty? && p.workout.nil?
  while true
    print 'Add a buddy: '
    buddy = gets&.chomp

    break if buddy.nil? || buddy.empty?

    p.buddies << buddy
  end
  p.flush_workout_state
end

puts
puts "#{whoami} is lifting#{" with " unless p.buddies.empty?}#{p.buddies.join(', ')}"

if p.workout.nil?
  puts
  puts 'Select workout:'
  puts " 1. Workout A (#{WORKOUT_A.join(', ')})"
  puts " 2. Workout B (#{WORKOUT_B.join(', ')})"
  print "Enter 1 or 2#{p.next_workout.nil? ? '' : " [#{p.next_workout == WORKOUT_A ? 1 : 2}]"}: "
  while true
    workout_choice = gets.chomp.to_i
    p.workout = case workout_choice
                when 1
                  WORKOUT_A
                when 2
                  WORKOUT_B
                else
                  if !p.next_workout.nil? && workout_choice == 0
                    p.next_workout
                  else
                    puts colourise('Invalid choice. Please enter 1 or 2.', :yellow)
                    next
                  end
                end
    break
  end
  p.flush_workout_state
end

puts
puts colourise("Selected workout: #{p.workout.join(', ')}", :grey)

if p.workout_weights.empty?
  puts

  p.workout.each do |exercise|
    for person in [whoami] + p.buddies
      proposed_target_weight = p.target_weight(exercise, person)
:qa
      print "Enter #{person}'s target weight for #{exercise} (#{$unit}) [#{proposed_target_weight}]: "
      target_weight = gets.chomp
      target_weight = proposed_target_weight if target_weight.empty?
      target_weight = sanitise_weight_to_lift(target_weight.to_f, minimum_increment)

      p.workout_weights[person.downcase] ||= {}
      p.workout_weights[person.downcase][exercise] = target_weight
    end
  end
  p.flush_workout_state
end

p.workout.each do |exercise|
  target_weight = p.workout_weights[whoami.downcase][exercise]

  puts
  puts "Exercise: #{exercise} at #{target_weight} #{$unit}"

  p.sets[exercise] ||= calculate_workout(exercise, target_weight, p.buddies.map { |b| p.workout_weights[b.downcase][exercise] })

  puts "  ┌────────────── Exercise Summary ──────────────┐"
  p.sets[exercise].each do |set|
    set['summary'] = "#{set['name']}: #{colourise("#{set['sets']} sets", :green)} of #{colourise("#{set['reps']} reps", :yellow)} at #{set['weight']} #{$unit}"
    puts "  │ #{set['summary']}#{" " * (45 - decolourise(set['summary']).length)}│"
  end
  puts "  └──────────────────────────────────────────────┘"

  p.flush_workout_state

  p.sets[exercise].each do |set|
    puts set['summary']
    display_bar_and_plates('Recommended plates per side', set['plates']) unless set['plates'].empty?
    if SHOW_MINIMUM_PLATES && !set['minimum_plates'].empty? && set['minimum_plates'].sort != set['plates'].sort
      puts "  │"
      display_bar_and_plates('Minimum plates per side', set['minimum_plates'])
    end

    set_completion_results = []

    for i in 1..set['sets']
      p.successful_reps[exercise] ||= {}
      p.successful_reps[exercise][set['name']] ||= {}

      p.successful_reps[exercise][set['name']][i.to_s] ||= begin
        print "  │ Successful reps for set #{i} of #{set['sets']} [#{set['reps']}]: "
        successful_reps = gets.chomp
        successful_reps = set['reps'] if successful_reps.empty?
        successful_reps = successful_reps.to_i

        if successful_reps < set['reps']
          puts colourise("  │ Only #{successful_reps} reps completed. Consider reducing the weight next time.", :red)
        end

        unless i == set['sets']
          cooldown_time = successful_reps < set['reps'] ? COOLDOWN_SECONDS_ON_FAILURE : COOLDOWN_SECONDS_ON_SUCCESS

          pressed_keys = []
          pressed_keys_lock = Monitor.new
          t = Thread.new do
            while true
              c = STDIN.getch
              pressed_keys_lock.synchronize do
                pressed_keys << c
              end
            end
          end

          begin
            countdown = cooldown_time
            while countdown > 0
              print "  │ Wait #{colourise(countdown.floor, :bright_white)} seconds before next set (ctrl+c to interrupt)\033[0K\r"
              sleep(0.1)
              countdown -= 0.1
              # Clear the contents of the current line
              print "\033[0K\r"

              # Check if any keys were pressed while we were waiting
              pressed_keys_lock.synchronize do
                while pressed_key = pressed_keys.shift
                  case pressed_key
                  when "\u0003", 'x', 'q'
                    countdown = 0
                    puts "  │ Cooldown interrupted. Proceeding to next set."
                    print "\033[0K\r"
                    pressed_keys.clear
                  when "\e"
                    case pressed_keys.shift
                    when nil # Escape key
                      countdown = 0
                      puts "  │ Cooldown interrupted. Proceeding to next set."
                      print "\033[0K\r"
                    when '['
                      case next_key = pressed_keys.shift
                      when 'A' # Up arrow
                        countdown += 30
                      when 'B' # Down arrow
                        countdown -= 30
                      when '5' # Page up
                        countdown += 60
                      when '6' # Page down
                        countdown -= 60
                      end
                    end
                    # Clear anything recorded after the escape sequence to avoid weirdness
                    pressed_keys.clear unless pressed_keys.first == "\e"
                  when '+', '='
                    countdown += 30
                  when '-', '_'
                    countdown -= 30
                  end
                end
              end
            end
          rescue Interrupt
            puts "\n  │ Cooldown interrupted. Proceeding to next set."
          end

          t.kill

          `command -v espeak && espeak "Time for the next set #{whoami}"`
        end

        { 'actual' => successful_reps, 'target' => set['reps'] }
      end

      p.flush_workout_state

      set_completion_results << p.successful_reps[exercise][set['name']][i.to_s]
    end
    puts "  │ #{colourise("Finished sets: #{format_set_completion_results(set_completion_results)}", :cyan)}"
  end

  if p.successful_reps[exercise][WORKING_SETS_LABEL].values.any? { |s| s['actual'] < s['target'] }
    p.exercise_unsuccessful(exercise, target_weight)
  else
    p.exercise_successful(exercise, target_weight)
  end
end

puts

box_right_padding = 59
puts "  ┌─────────────────── Post-Workout Summary ───────────────────┐"
p.successful_reps.each_with_index do |exercise_results, i|
  puts "  ├────────────────────────────────────────────────────────────┤" unless i == 0
  exercise = exercise_results.first
  set_groups = exercise_results.last
  puts "  │ #{exercise}:#{" " * (box_right_padding - exercise.length - 1)}│"
  set_groups.each do |set_group, sets|
    weight = p.sets[exercise].find { |s| s['name'] == set_group }['weight']
    set_group_formatted = "  #{colourise("#{set_group} (#{weight} #{$unit}):", set_group == WORKING_SETS_LABEL ? :none : :grey)} #{format_set_completion_results(sets.map { |_, r| r })}"
    puts "  │ #{set_group_formatted}#{" " * (box_right_padding - decolourise(set_group_formatted).length)}│"
  end
end
puts "  └────────────────────────────────────────────────────────────┘"

p.flush_profile_state

print_progress_charts(whoami)
