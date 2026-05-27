# frozen_string_literal: true

SQUAT = 'Squat'
BENCH_PRESS = 'Bench Press'
OVERHEAD_PRESS = 'Overhead Press'
BARBELL_ROW = 'Barbell Row'
DEADLIFT = 'Deadlift'

WORKOUT_A = [SQUAT, BENCH_PRESS, BARBELL_ROW].freeze
WORKOUT_B = [SQUAT, OVERHEAD_PRESS, DEADLIFT].freeze

# Women's Olympic barbell: 15 kg
# Men's Olympic barbell: 20 kg
# Override this in db/<username>_profile.json { "config" : { "BAR_WEIGHT" : ... } }
$bar_weight = 20

# Override this in db/<username>_profile.json { "config" : { "PLATES" : ... } }
$plates = {
  0.25 => 0, # Should max this at 8
  1.25 => 4, # Should max this at 4
  2.5 => 4,  # Should max this at 4
  5 => 4,    # Should max this at 4
  10 => 4,   # Should max this at 4
  15 => 0,   # Should max this at 4
  20 => 2,   # Should max this at 20
  25 => 0    # Should max this at 20
}

PLATE_COLOURS = {
  0.25 => :bright_red,
  1.25 => :bright_magenta,
  2.5 => :bright_cyan,
  5 => :bright_white,
  10 => :bright_green,
  15 => :bright_yellow,
  20 => :bright_blue,
  25 => :red
}.freeze

def minimum_increment()
  $plates.keys.min * 2
end

# We don't need precise fractional plates for warmups, so this keeps things simple
MINIMUM_WARMUP_INCREMENT = 5

# The threshold at which we start adding warmup sets
ADD_WARMUPS_THRESHOLD = 30

# This is used to ensure that the maximum warmup weight is at least this much less than the target weight
MIN_WARMUP_WEIGHT_DIFFERENCE = 10

WARMUP = 30

COOLDOWN_SECONDS_ON_SUCCESS = 90

COOLDOWN_SECONDS_ON_FAILURE = 300

SETS = {
  SQUAT => {
    'sets' => 5,
    'reps' => 5
  },
  BENCH_PRESS => {
    'sets' => 5,
    'reps' => 5
  },
  OVERHEAD_PRESS => {
    'sets' => 5,
    'reps' => 5
  },
  BARBELL_ROW => {
    'sets' => 5,
    'reps' => 5
  },
  DEADLIFT => {
    'sets' => 1,
    'reps' => 5
  }
}.freeze

DEFAULT_PROGRESSION = {
  SQUAT => {
    'initial_weight' => 20,
    'increment' => 2.5,
    'successes_before_increment' => 1,
    'deload_percentage' => 10,
    'failures_before_deload' => 3
  },
  BENCH_PRESS => {
    'initial_weight' => 20,
    'increment' => 2.5,
    'successes_before_increment' => 1,
    'deload_percentage' => 10,
    'failures_before_deload' => 3
  },
  OVERHEAD_PRESS => {
    'initial_weight' => 20,
    'increment' => 2.5,
    'successes_before_increment' => 1,
    'deload_percentage' => 10,
    'failures_before_deload' => 3
  },
  BARBELL_ROW => {
    'initial_weight' => 30,
    'increment' => 2.5,
    'successes_before_increment' => 1,
    'deload_percentage' => 10,
    'failures_before_deload' => 3
  },
  DEADLIFT => {
    'initial_weight' => 40,
    'increment' => 5,
    'successes_before_increment' => 1,
    'deload_percentage' => 10,
    'failures_before_deload' => 3
  }
}.freeze

# Based on https://github.com/nmunson/warmup-reps/blob/master/programs/program_2.json
WARMUP_SETS = {
  SQUAT => [
    {
      'name' => 'Warmup 1',
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0
    }, {
      'name' => 'Warmup 2',
      'sets' => 1,
      'reps' => 5,
      'multiplier' => 0.4
    }, {
      'name' => 'Warmup 3',
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.6
    }, {
      'name' => 'Warmup 4',
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.8
    }
  ],
  BENCH_PRESS => [
    {
      'name' => 'Warmup 1',
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0
    }, {
      'name' => 'Warmup 2',
      'sets' => 1,
      'reps' => 5,
      'multiplier' => 0.5
    }, {
      'name' => 'Warmup 3',
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.7
    }, {
      'name' => 'Warmup 4',
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.9
    }
  ],
  OVERHEAD_PRESS => [
    {
      'name' => 'Warmup 1',
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0
    }, {
      'name' => 'Warmup 2',
      'sets' => 1,
      'reps' => 5,
      'multiplier' => 0.55
    }, {
      'name' => 'Warmup 3',
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.7
    }, {
      'name' => 'Warmup 4',
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.85
    }
  ],
  BARBELL_ROW => [
    {
      'name' => 'Warmup 1',
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0.4
    }, {
      'name' => 'Warmup 2',
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.7
    }, {
      'name' => 'Warmup 3',
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.9
    }
  ],
  DEADLIFT => [
    {
      'name' => 'Warmup 1',
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0.4
    }, {
      'name' => 'Warmup 2',
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.6
    }, {
      'name' => 'Warmup 3',
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.85
    }
  ]
}.freeze

WORKING_SETS_LABEL = 'Working sets'.freeze
