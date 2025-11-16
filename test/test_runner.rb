require 'minitest/autorun'

require_relative '../apply_bundle'
require_relative '../create_bundle'

class TestRunner < Minitest::Test
  def setup
    @sync_root = File.join('/tmp')
    @sync_it_at = File.join('/tmp', 'sync_it')
    FileUtils.mkdir_p(@sync_it_at)
    Dir.chdir(@sync_it_at) do
      File.write('repo_paths', "work/a\nwork/b\n")
    end

    @repo_dirs = [File.join(@sync_root, 'work', 'a'), File.join(@sync_root, 'work', 'b')]
    Dir.chdir(@sync_root) do
      @repo_dirs.each do |repo_dir|
        FileUtils.mkdir_p(repo_dir)
        Dir.chdir(repo_dir) do
          system('git init -q')
          system('git config user.email "t@a.b"')
          system('git config user.name "t"')
          File.write('test', 'initial')
          system('git add test')
          system('git commit -q -m "init"')
        end
      end
    end
  end

  def teardown
    FileUtils.rm_rf(@sync_it_at)
    @repo_dirs.each do |repo_dir|
      FileUtils.rm_rf(repo_dir)
    end
    FileUtils.rm_rf(File.join('/tmp', 'bundle_root'))
  end

  def test_run_bundle_creator
    Dir.chdir(@sync_it_at) do
      BundleCreator.new.run('repo_paths', '/tmp')
    end
  end

  def test_run_bundle_applier
    Dir.chdir(@sync_it_at) do
      BundleCreator.new.run('repo_paths', '/tmp')
      BundleApplier.new.run('repo_paths', '/tmp')
    end
  end
end
