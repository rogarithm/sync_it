#!/usr/bin/env ruby

dir_lst = %w[moderation_parent/moderation moderation_parent/dataset moderation_parent/req_results notes sync_it]

SOURCE_MACHINE = ENV['SOURCE_MACHINE']
BUNDLE_DIR = 'bundle_root'

dir_lst.each do |dir|
  # 번들 파일 경로
  bundle_path = File.join('bundle_root', dir)
  bundle_file = File.join(bundle_path, "#{SOURCE_MACHINE}.bundle")

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

  # 대상 디렉토리로 이동
  Dir.chdir(File.join('..', dir)) do
    puts "Current directory: #{Dir.pwd}"

    # 번들에서 어떤 브랜치가 있는지 확인
    refs = %x[git bundle list-heads ../../sync_it/#{bundle_file}].strip
    puts "Bundle contains:\n#{refs}"

    # main 브랜치가 있는지 확인하고 pull
    if refs.include?('refs/heads/main')
      puts "Pulling from bundle..."
      %x[git pull ../../sync_it/#{bundle_file} refs/heads/main:main]

      if $?.success?
        puts "Successfully applied bundle"
        puts "Repository updated\n\n"
      else
        puts "ERROR: Failed to apply bundle"
      end
    else
      puts "WARNING: Bundle does not contain refs/heads/main"
    end
  end
end
