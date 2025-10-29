#!/usr/bin/env ruby

dir_lst = File.read(File.join('repo_paths')).strip.split("\n")

BUNDLED_AT = %x[git config user.email].strip == 'sehoongim@gmail.com' ? 'home' : 'office'
BUNDLE_DIR = 'bundle_root'

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do
    puts "Processing repository: #{dir}"

    # 동기화 태그 이름
    sync_tag = "bundled_at/#{BUNDLED_AT}"

    # 마지막 동기화 지점 확인
    last_sync = %x[git rev-parse #{sync_tag} 2>/dev/null].strip
    last_sync = nil unless $?.success?

    # 번들 파일 경로
    bundle_path = File.join('..' + '/..' * (dir.split('/').size - 1), BUNDLE_DIR, dir)
    bundle_file = File.join(bundle_path, "#{BUNDLED_AT}.bundle")

    # 번들 디렉토리 생성
    %x[mkdir -p #{bundle_path}] if not Dir.exist?(bundle_path)

    # 번들 생성 범위 결정
    if last_sync.nil?
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
      range = "#{last_sync}..main"
    end

    # 번들 생성 (태그 포함)
    puts "Creating bundle: #{bundle_file}"
    %x[git bundle create #{bundle_file} #{range} #{sync_tag}]

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
