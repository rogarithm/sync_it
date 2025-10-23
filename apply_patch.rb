#!/usr/bin/env/ruby

dir_lst = %w[moderation_parent/moderation moderation_parent/dataset notes]

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do |work_dir|
    puts "we're now in: #{work_dir}"
    patch_dir = File.join('..' + '/..' * (dir.split('/').size - 1), 'patch_root', dir)
    puts "apply patch files #{patch_dir} -> #{work_dir}"
    `git am #{patch_dir}/* 2>&1`
    if File.exist? '.git/rebase-apply'
      `git am --skip 2>&1`
    end
  end
end
