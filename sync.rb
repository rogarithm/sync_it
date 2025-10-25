#!/usr/bin/env/ruby

patch_root_dir = "../patch_root"

dir_lst = %w[moderation_parent/moderation moderation_parent/dataset notes]
dir_lst.each do |dir|
  `mkdir -p #{patch_root_dir}/#{dir}` if not Dir.exist?("#{patch_root_dir}/#{dir}")
end

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do |work_dir|
    puts "we're now in: #{work_dir}"
    cmts = `git rev-list --since="1 weekk ago" HEAD`.strip.split("\n")
    oldest, newest = cmts.last, cmts.first
    puts "save patch files to: #{File.join('..' + '/..' * (dir.split('/').size - 1), 'patch_root', dir)}"
    `git format-patch #{oldest}^..#{newest} -o #{File.join('..' + '/..' * (dir.split('/').size - 1), 'patch_root', dir)}`
  end
end

