#!/usr/bin/env ruby

require_relative 'create_bundle'

BundleCreator.new(ARGV[0], ARGV[1]).run
