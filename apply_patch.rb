#!/usr/bin/env/ruby

# dir_lst = %w[moderation_parent/moderation moderation_parent/dataset notes]
dir_lst = %w[moderation_parent/moderation]

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do |work_dir|
    puts "we're now in: #{work_dir}"
    patch_dir = File.join('..' + '/..' * (dir.split('/').size - 1), 'patch_root', dir)
    puts "apply patch files #{patch_dir} -> #{work_dir}"

    patches=%x[ls #{patch_dir}/*.patch | sort].strip.split("\n")
    puts "patches: #{patches}"
    cmt_hashs= patches.map {|patch|
      %x[cat #{patch} | git patch-id].strip.split(" ")[1]
    }
    puts "cmt_hashs: #{cmt_hashs}"

    apply_from=nil
    cmt_hashs.each.with_index {|cmt_hash, idx|
      %x[git cat-file -e #{cmt_hash}^{commit} 2>/dev/null]
      next if $?.success?
      apply_from=idx
      break
    }
    puts "apply_from: #{apply_from}"

    if apply_from.nil?
      puts "all patches already applied"
      exit
    end

    puts "patches to apply:"
    puts patches[apply_from..-1]
    patches[apply_from..-1].each {|patch|
      # %x[git am #{patch}]
    }
  end
end
