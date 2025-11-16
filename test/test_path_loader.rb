require 'minitest/autorun'

require_relative '../lib/path_loader'

class TestPathLoader < Minitest::Test
  def test_load_path
    repo_paths = PathLoader.new('repo_paths').load
    assert_equal(repo_paths, %w[moderation_parent/moderation moderation_parent/dataset moderation_parent/req_results notes sync_it])
  end

  def test_config_root_dir
    # sync_it의 상위 폴더를 동기화 대상 폴더와 번들 생성 폴더를 찾을 기준점으로 잡으면 테스트하기 어렵다
    # /tmp 하위에 테스트용 동기화 대상 폴더 및 번들 생성 폴더를 만들도록 설정하기 위해, root_dir를 바꿀 수 있도록 한다
    pl = PathLoader.new('repo_paths')
    assert_equal(pl.root_dir, '..')

    pl = PathLoader.new('repo_paths', '/tmp')
    assert_equal(pl.root_dir, '/tmp')
  end

  def test_load_bundle_dir
    pl = PathLoader.new('repo_paths')
    assert_equal pl.bundle_dir('moderation_parent/moderation'), '../../bundle_root/moderation_parent/moderation'
    assert_equal pl.bundle_dir('notes'), '../bundle_root/notes'

    pl = PathLoader.new('repo_paths', '/tmp')
    assert_equal pl.bundle_dir('moderation_parent/moderation'), '/tmp/../bundle_root/moderation_parent/moderation'
    assert_equal pl.bundle_dir('notes'), '/tmp/bundle_root/notes'
  end
end
