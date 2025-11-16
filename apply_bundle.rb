#!/usr/bin/env ruby

require 'date'
require_relative 'lib/path_loader'

pl = PathLoader.new('repo_paths')
dir_lst = pl.load

BUNDLED_AT = %x[git config user.email].strip == 'sehoongim@gmail.com' ? 'office' : 'home'

dir_lst.each do |dir|
  # 대상 디렉토리로 이동
  Dir.chdir(File.join(pl.root_dir, dir)) do
    puts "At #{Dir.pwd}"

    # 번들 파일 경로
    bundle_dir = pl.bundle_dir(dir)
    bundle_filename = Dir.entries(bundle_dir).filter { |entry|
      entry.end_with?('.bundle')
    }.sort_by { |bundle|
      bs = bundle.split('.')
      Date.parse("20#{bs[1]}-#{bs[2]}-#{bs[3]}")
    }.reverse.first
    bundle_path = File.join(bundle_dir, bundle_filename) if bundle_filename

    if not File.exist?(bundle_path)
      puts "ERROR: Bundle file not found: #{bundle_path}"
      next
    end

    puts " Processing repository: #{dir}"

    # 번들 검증
    print " Verifying bundle... "
    %x[git bundle verify #{bundle_path}]

    if not $?.success?
      puts "failed!"
      next
    end
    puts "ok!"

    # 번들에서 어떤 브랜치가 있는지 확인
    refs = %x[git bundle list-heads #{bundle_path}].strip
    print " Checking bundle have main branch... "

    # main 브랜치가 있는지 확인
    if not refs.include?('refs/heads/main')
      puts "failed!"
      next
    end
    puts "ok!"

    print " Fetching from bundle... "
    # fetch를 사용하여 브랜치만 가져옴 (태그는 나중에 별도로 가져옴)
    %x[git fetch --no-tags #{bundle_path} refs/heads/main:refs/remotes/bundle/main]

    if not $?.success?
      puts "failed!"
      next
    end
    puts "ok!"

    cmts = %x[git log --oneline ..refs/remotes/bundle/main].strip.split("\n")
    if cmts.empty?
      print " Merging changes... "
    else
      new_cm, old_cm = cmts.first, cmts.last
      print " Merging changes... #{old_cm}..#{new_cm} "
    end
    %x[git merge refs/remotes/bundle/main]

    if $?.success?
      puts "ok!"
    else
      puts "failed!"
      next
    end

    print " Fetching tags from bundle... "
    # bundled_at/office와 bundled_at/home 태그를 제외하고 가져옴
    all_tags = %x[git bundle list-heads #{bundle_path}].strip.split("\n")
      .map { |line| line.split(/\s+/, 2)[1] }
      .compact
      .uniq
      .select { |ref| ref.start_with?('refs/tags/') }
      .reject { |ref| ref == 'refs/tags/bundled_at/office' || ref == 'refs/tags/bundled_at/home' }

    if all_tags.empty?
      puts "no tags to fetch!"
    else
      fetch_result = all_tags.map { |tag|
        result = system("git fetch --no-tags #{bundle_path} '#{tag}:#{tag}' 2>&1 > /dev/null")
        result
      }.all?

      if fetch_result
        puts "ok!"
      else
        puts "failed!"
      end
    end
  end
end
