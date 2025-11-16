require 'minitest/autorun'

require_relative '../lib/path_loader'

class TestPathLoader < Minitest::Test
  def test_load_path
    repo_paths = PathLoader.new('repo_paths').load
    assert_equal(repo_paths, %w[moderation_parent/moderation moderation_parent/dataset moderation_parent/req_results notes sync_it])
  end
end
