#!/usr/bin/env ruby

# frozen_string_literal: true

def colourise(text, colour, background = false)
  colours = {
    none: 0,
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

def decolourise(text)
  text.gsub(/\e\[\d+m/, '')
end

def debug(message)
  puts colourise(message, :grey) if DEBUG
end
