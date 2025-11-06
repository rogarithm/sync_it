#!/usr/bin/env ruby
require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require 'time'

class TestCreateBundle < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir('bundle_test')
    @repo_dir = File.join(@test_dir, 'test_repo')

    Dir.mkdir(@repo_dir)
    Dir.chdir(@repo_dir) do
      system('git init -q')
      system('git config user.email "test@example.com"')
      system('git config user.name "Test User"')
      File.write('test.txt', 'initial')
      system('git add test.txt')
      system('git commit -q -m "Initial commit"')
    end
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_get_next_version_returns_date_based_tag
    Dir.chdir(@repo_dir) do
      version = get_next_version('home')
      # v.25.11.06 형식 확인
      assert_match(/^v\.\d{2}\.\d{2}\.\d{2}$/, version)
    end
  end

  def test_get_next_version_increments_when_same_day
    Dir.chdir(@repo_dir) do
      today_version = get_next_version('home')
      system("git tag bundled_at/home/#{today_version}")

      next_version = get_next_version('home')
      assert_match(/^v\.\d{2}\.\d{2}\.\d{2}\.\d+$/, next_version)
    end
  end

  private

  def get_next_version(location)
    tag_prefix = "bundled_at/#{location}/"
    today = Time.now.strftime('%y.%m.%d')
    base_version = "v.#{today}"

    # 오늘 날짜로 시작하는 태그 찾기
    tags = `git tag -l "#{tag_prefix}#{base_version}*"`.lines.map(&:strip)

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
end
