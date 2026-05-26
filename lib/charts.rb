# frozen_string_literal: true

DAYS_TO_SHOW = 45.freeze

DIRECTORY = 'db'.freeze

require_relative '../config/values'
require_relative 'util'

def print_progress_charts(person)
  person = person.downcase

  # Workout data structure: { exercise => { date => { 'weight' => weight, 'success' => true/false } } }
  workouts = {}

  Dir.glob(File.join(DIRECTORY, "#{person}_*-*-*.json")).each do |workout_file|
    workout_data = JSON.parse(File.read(workout_file))
    workout_date = Date.iso8601(workout_file.match(/#{DIRECTORY}\/#{person}_(\d{4}-\d{2}-\d{2})\.json/)[1])
    if workout_date >= Date.today - DAYS_TO_SHOW
      workout_data['workout'].each do |exercise|
        workouts[exercise] ||= {}
        workouts[exercise][workout_date] ||= {
          'weight' => workout_data['workout_weights'][person][exercise],
          'success' => workout_data['successful_reps'][exercise][WORKING_SETS_LABEL].values.all? { |s| s['actual'] >= s['target'] }
        }
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
      weight_str = '#' * (workout['weight'] / weight_per_character).round + " #{workout['weight']} kg"
      weight_str = workout['success'] ? colourise(weight_str, :green) : colourise(weight_str, :red)
      puts "  │ #{date.iso8601}: #{weight_str}"
    end
  end
end
