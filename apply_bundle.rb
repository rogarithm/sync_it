#!/usr/bin/env ruby

dir_lst = %w[moderation_parent/moderation moderation_parent/dataset moderation_parent/req_results notes]

BUNDLED_AT = %x[git config user.email].strip == 'sehoongim@gmail.com' ? 'office' : 'home'
BUNDLE_DIR = 'bundle_root'

dir_lst.each do |dir|
  # 대상 디렉토리로 이동
  Dir.chdir(File.join('..', dir)) do
    puts "Current directory: #{Dir.pwd}"

    # 번들 파일 경로
    bundle_path = File.join('..' + '/..' * (dir.split('/').size - 1), BUNDLE_DIR, dir)
    bundle_file = File.join(bundle_path, "#{BUNDLED_AT}.bundle")

    if not File.exist?(bundle_file)
      puts "Bundle file not found: #{bundle_file}"
      next
    end

    puts "Processing repository: #{dir}"
    puts "Bundle file: #{bundle_file}"

    # 번들 검증
    puts "Verifying bundle..."
    %x[git bundle verify #{bundle_file}]

    if not $?.success?
      puts "ERROR: Bundle verification failed"
      next
    end

    puts "Bundle is valid"

    # 번들에서 어떤 브랜치가 있는지 확인
    refs = %x[git bundle list-heads #{bundle_file}].strip
    puts "Bundle contains:\n#{refs}"

    # main 브랜치가 있는지 확인
    if not refs.include?('refs/heads/main')
      puts "WARNING: Bundle does not contain refs/heads/main"
      next
    end

    puts "Fetching from bundle..."
    # fetch를 사용하여 브랜치와 태그를 모두 가져옴
    %x[git fetch #{bundle_file} refs/heads/main:refs/remotes/bundle/main]

    if not $?.success?
      puts "ERROR: Failed to fetch from bundle"
      next
    end

    puts "Merging changes..."
    %x[git merge refs/remotes/bundle/main]

    if $?.success?
      puts "Successfully merged bundle changes"
    else
      puts "ERROR: Failed to merge bundle"
      next
    end

    puts "Fetching tags from bundle..."
    %x[git fetch #{bundle_file} 'refs/tags/*:refs/tags/*']

    if $?.success?
      puts "Successfully fetched tags"
      puts "Repository updated\n\n"
    else
      puts "WARNING: Failed to fetch tags"
    end
  end
end
