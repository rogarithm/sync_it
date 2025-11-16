#!/usr/bin/env ruby

require_relative 'apply_bundle'

BundleApplier.new(ARGV[0], ARGV[1]).run
