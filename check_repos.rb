#!/usr/bin/env ruby

dir_lst = File.read(File.join('repo_paths')).strip.split("\n")

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do
    puts "Repo: #{dir}"
    stat = %x[git status --short].strip.split("\n").map {|s| s.split(" ")}
    pp stat
  end
end
