#!/usr/bin/env ruby
require 'time'

dir_lst = PathLoader.new('repo_paths').load

BUNDLED_AT = %x[git config user.email].strip == 'sehoongim@gmail.com' ? 'home' : 'office'
BUNDLE_DIR = 'bundle_root'

def get_next_version(location)
  tag_prefix = "bundled_at/#{location}/"
  today = Time.now.strftime('%y.%m.%d')
  base_version = "v.#{today}"

  # 오늘 날짜로 시작하는 태그 찾기
  tags = %x[git tag -l "#{tag_prefix}#{base_version}*"].lines.map(&:strip)

  if tags.empty?
    base_version
  else
    # 가장 높은 번호 찾기
    max_num = tags.map { |t|
      if t.match(/#{Regexp.escape(base_version)}\.(\d+)$/)
        $1.to_i
      else
        0
      end
    }.max

    "#{base_version}.#{max_num + 1}"
  end
end

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do
    puts "Processing repository: #{dir}"

    # 태그 프리픽스
    tag_prefix = "bundled_at/#{BUNDLED_AT}/"

    # 마지막 동기화 태그 찾기
    last_tag = %x[git tag -l "#{tag_prefix}v.*" --sort=-version:refname].lines.first&.strip
    last_sync = last_tag ? %x[git rev-parse #{last_tag}].strip : nil

    # 번들 파일 경로
    bundle_path = File.join('..' + '/..' * (dir.split('/').size - 1), BUNDLE_DIR, dir)
    %x[mkdir -p #{bundle_path}] if not Dir.exist?(bundle_path)

    # 번들 생성 범위 결정
    if last_sync.nil?
      puts "First sync - creating bundle with all commits"
      range = "--all"
    else
      puts "Last sync tag: #{last_tag}"
      # 새로운 커밋이 있는지 확인
      current_head = %x[git rev-parse HEAD].strip
      if current_head == last_sync
        puts "No new commits since last sync"
        next
      end
      range = "#{last_sync}..HEAD"
    end

    # 새 버전 생성
    new_version = get_next_version(BUNDLED_AT)
    new_tag = "#{tag_prefix}#{new_version}"
    bundle_file = File.join(bundle_path, "#{BUNDLED_AT}_#{new_version}.bundle")

    # 커밋 목록 생성 (태그 메시지용)
    if last_sync
      commits = %x[git log --oneline #{last_sync}..HEAD].strip
    else
      commits = %x[git log --oneline].strip
    end

    # 태그 메시지 생성
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    tag_message = <<~MSG
      Bundle created at: #{timestamp}

      Commits included:
      #{commits}
    MSG

    # 어노테이션 태그 먼저 생성
    %x[git tag -a #{new_tag} -m "#{tag_message}" HEAD]

    if not $?.success?
      puts "ERROR: Failed to create sync tag"
      next
    end
    puts "Created sync tag: #{new_tag}"

    # 번들 생성 (태그를 포함)
    puts "Creating bundle: #{bundle_file}"
    if last_sync.nil?
      %x[git bundle create #{bundle_file} #{range} #{new_tag}]
    else
      # 이전 태그들과 새 태그 포함
      prev_tags = %x[git tag -l "#{tag_prefix}v.*"].lines.map(&:strip).join(' ')
      %x[git bundle create #{bundle_file} #{range} #{prev_tags}]
    end

    if $?.success?
      puts "Bundle created successfully\n\n"
    else
      puts "ERROR: Failed to create bundle"
    end
  end
end
