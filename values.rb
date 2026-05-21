#!/usr/bin/env ruby

# frozen_string_literal: true

SQUAT = 'squat'
BENCH_PRESS = 'bench press'
OVERHEAD_PRESS = 'overhead press'
BARBELL_ROW = 'barbell row'
DEADLIFT = 'deadlift'

WORKOUT_A = [SQUAT, BENCH_PRESS, BARBELL_ROW].freeze
WORKOUT_B = [SQUAT, OVERHEAD_PRESS, DEADLIFT].freeze

BAR_WEIGHT = 15

PLATES = {
  0.25 => 8, # Should max this at 8
  1.25 => 4, # Should max this at 4
  2.5 => 4,  # Should max this at 4
  5 => 4,    # Should max this at 4
  10 => 4,   # Should max this at 4
  15 => 0,   # Should max this at 4
  20 => 2,   # Should max this at 20
  25 => 0    # Should max this at 20
}.freeze

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

MINIMUM_INCREMENT = PLATES.keys.min * 2

# We don't need precise fractional plates for warmups, so this keeps things simple
MINIMUM_WARMUP_INCREMENT = 5

# The threshold at which we start adding warmup sets
ADD_WARMUPS_THRESHOLD = 30

# This is used to ensure that the maximum warmup weight is at least this much less than the target weight
MIN_WARMUP_WEIGHT_DIFFERENCE = 10

WARMUP = 30

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

# Based on https://github.com/nmunson/warmup-reps/blob/master/programs/program_2.json
WARMUP_SETS = {
  SQUAT => [
    {
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0
    }, {
      'sets' => 1,
      'reps' => 5,
      'multiplier' => 0.4
    }, {
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.6
    }, {
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.8
    }
  ],
  BENCH_PRESS => [
    {
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0
    }, {
      'sets' => 1,
      'reps' => 5,
      'multiplier' => 0.5
    }, {
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.7
    }, {
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.9
    }
  ],
  OVERHEAD_PRESS => [
    {
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0
    }, {
      'sets' => 1,
      'reps' => 5,
      'multiplier' => 0.55
    }, {
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.7
    }, {
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.85
    }
  ],
  BARBELL_ROW => [
    {
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0.4
    }, {
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.7
    }, {
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.9
    }
  ],
  DEADLIFT => [
    {
      'sets' => 2,
      'reps' => 5,
      'multiplier' => 0.4
    }, {
      'sets' => 1,
      'reps' => 3,
      'multiplier' => 0.6
    }, {
      'sets' => 1,
      'reps' => 2,
      'multiplier' => 0.85
    }
  ]
}.freeze
