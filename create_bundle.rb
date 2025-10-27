#!/usr/bin/env ruby

dir_lst = %w[moderation_parent/moderation moderation_parent/dataset moderation_parent/req_results notes sync_it]

TARGET_MACHINE = ENV['TARGET_MACHINE']
BUNDLE_DIR = 'bundle_root'

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do
    puts "Processing repository: #{dir}"

    # 동기화 태그 이름
    sync_tag = "sync/#{TARGET_MACHINE}"

    # 마지막 동기화 지점 확인
    last_sync = %x[git rev-parse #{sync_tag} 2>/dev/null].strip

    # 번들 파일 경로
    bundle_path = File.join('..' + '/..' * (dir.split('/').size - 1), BUNDLE_DIR, dir)
    bundle_file = File.join(bundle_path, "#{TARGET_MACHINE}.bundle")

    # 번들 디렉토리 생성
    %x[mkdir -p #{bundle_path}] if not Dir.exist?(bundle_path)

    # 번들 생성 범위 결정
    if last_sync.empty?
      puts "First sync - creating bundle with all commits"
      range = "--all"
    else
      puts "Last sync tag: #{last_sync}"
      # 새로운 커밋이 있는지 확인
      current_head = %x[git rev-parse HEAD].strip
      if current_head == last_sync
        puts "No new commits since last sync"
        next
      end
      range = "#{last_sync}..HEAD"
    end

    # 번들 생성
    puts "Creating bundle: #{bundle_file}"
    %x[git bundle create #{bundle_file} #{range}]

    if not $?.success?
      puts "ERROR: Failed to create bundle"
      next
    end

    # 동기화 태그 업데이트
    %x[git tag -f #{sync_tag} HEAD]

    if $?.success?
      puts "Updated sync tag: #{sync_tag} -> HEAD"
      puts "Bundle created successfully\n\n"
    else
      puts "ERROR: Failed to update sync tag"
    end
  end
end
