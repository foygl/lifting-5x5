# frozen_string_literal: true

require_relative '../config/values'
require_relative 'util'

DAYS_TO_SHOW = 45

DIRECTORY = 'db'

SUCCESS_LEVELS = {
  'success' => :green,
  'some_failed' => :yellow,
  'all_failed' => :red,
  'previous_pr' => :grey
}.freeze

def print_progress_charts(person, persistence)
  person = person.downcase

  # Workout data structure: { exercise => { date => { 'weight' => weight, 'success' => SUCCESS_LEVELS } } }
  workouts = {}

  workout_files = Dir.glob(File.join(DIRECTORY, "#{person}_*-*-*.json"))

  puts colourise("No progress files found", :grey) if workout_files.empty?

  workout_files.each do |workout_file|
    workout_data = JSON.parse(File.read(workout_file))
    workout_date = Date.iso8601(workout_file.match(/#{DIRECTORY}\/#{person}_(\d{4}-\d{2}-\d{2})\.json/)[1])
    if workout_date >= Date.today - DAYS_TO_SHOW
      next unless workout_data.key?('workout')
      workout_data['workout'].each do |exercise|
        next unless workout_data.key?('workout_weights')
        next unless workout_data['workout_weights'].key?(person)
        next unless workout_data['workout_weights'][person].key?(exercise)
        next unless workout_data.key?('successful_reps')
        next unless workout_data['successful_reps'].key?(exercise)
        next unless workout_data['successful_reps'][exercise].key?(WORKING_SETS_LABEL)

        workouts[exercise] ||= {}
        workouts[exercise][workout_date] ||= {
          'weight' => workout_data['workout_weights'][person][exercise],
          'success' => if workout_data['successful_reps'][exercise][WORKING_SETS_LABEL].values.all? { |s| s['actual'] >= s['target'] }
                         'success'
                       elsif workout_data['successful_reps'][exercise][WORKING_SETS_LABEL].values.any? { |s| s['actual'] >= s['target'] }
                         'some_failed'
                       else
                         'all_failed'
                       end
        }

        previous_pr = persistence.previous_pr(exercise)
        if previous_pr.key?('date') && previous_pr.key?('weight')
          workouts[exercise][Date.iso8601(previous_pr['date'])] ||= {
            'weight' => previous_pr['weight'].to_f,
            'success' => 'previous_pr'
          }
        end
      end
    end
  end

  terminal_width = `tput cols`.to_i
  max_weight = workouts.values.map { |exercise_workouts| exercise_workouts.values.map { |w| w['weight'] }.max }.max || 0
  weight_per_character = max_weight / (terminal_width / 2)
  workouts.each do |exercise, exercise_workouts|
    puts
    puts "  #{exercise} progress over the last #{DAYS_TO_SHOW} days:"
    exercise_workouts.sort_by { |date, _| date }.each do |date, workout|
      weight_str = '#' * (workout['weight'] / weight_per_character).round + " #{workout['weight']} #{$unit}"
      weight_str = colourise(weight_str, SUCCESS_LEVELS[workout['success']])
      puts "  │ #{date.iso8601}: #{weight_str}"
    end
  end
end
