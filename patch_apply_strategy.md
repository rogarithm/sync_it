# 패치 적용 후 patch_root 디렉토리 내부 파일은 삭제

# 이메일로 보내주고, 이메일로부터 패치 적용할 수 있도록 수정하기

# Patch 적용 자동화 전략
## 핵심 아이디어

패치 파일의 커밋 해시를 추출하여, 이미 적용된 커밋은 제외하고 적용

## Plumbing 명령

Git의 plumbing 명령은 스크립팅을 위한 저수준 명령어입니다.

```bash
# 커밋이 저장소에 존재하는지 확인
git rev-parse --verify <commit-hash>
# 존재: 해시 반환, exit code 0
# 없음: 에러, exit code 128
```

이는 `git status` 같은 porcelain(사용자용) 명령과 달리:
- 출력 형식이 안정적 (버전 간 변경 없음)
- 스크립트에서 파싱하기 쉬움
- 언어 독립적

## Ruby 구현

```ruby
#!/usr/bin/env/ruby

def extract_commit_hash(patch_file)
  first_line = File.open(patch_file) { |f| f.readline }
  first_line[/^From ([0-9a-f]{40})/, 1]  # "From <hash> ..." 에서 해시 추출
end

def commit_exists?(commit_hash)
  system("git rev-parse --verify #{commit_hash} >/dev/null 2>&1")
end

dir_lst = %w[notes]

dir_lst.each do |dir|
  Dir.chdir(File.join('..', dir)) do |work_dir|
    puts "we're now in: #{work_dir}"
    patch_dir = File.join('..' + '/..' * (dir.split('/').size - 1), 'patch_root', dir)

    all_patches = Dir.glob("#{patch_dir}/*.patch").sort
    new_patches = all_patches.reject do |patch|
      hash = extract_commit_hash(patch)
      hash && commit_exists?(hash)  # 커밋이 이미 있으면 제외
    end

    if new_patches.empty?
      puts "All patches already applied"
    else
      puts "Applying #{new_patches.size} patches..."
      system("git am #{new_patches.join(' ')}")
    end
  end
end
```

## 장점

- `git am --skip` 수동 처리 불필요
- 이미 적용된 패치는 아예 제외
- 명확하고 예측 가능
