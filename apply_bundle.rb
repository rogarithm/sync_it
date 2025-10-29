#!/usr/bin/env ruby

dir_lst = File.read(File.join('repo_paths')).strip.split("\n")

BUNDLED_AT = %x[git config user.email].strip == 'sehoongim@gmail.com' ? 'office' : 'home'
BUNDLE_DIR = 'bundle_root'

dir_lst.each do |dir|
  # 대상 디렉토리로 이동
  Dir.chdir(File.join('..', dir)) do
    puts "At #{Dir.pwd}"

    # 번들 파일 경로
    bundle_path = File.join(File.join('..' + '/..' * (dir.split('/').size - 1), BUNDLE_DIR, dir), "#{BUNDLED_AT}.bundle")

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
    # fetch를 사용하여 브랜치와 태그를 모두 가져옴
    %x[git fetch #{bundle_path} refs/heads/main:refs/remotes/bundle/main]

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
    %x[git fetch #{bundle_path} 'refs/tags/*:refs/tags/*']

    if $?.success?
      puts "ok!"
    else
      puts "failed!"
    end
  end
end
