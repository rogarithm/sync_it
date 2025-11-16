class PathLoader
  BUNDLE_DIR = 'bundle_root'

  attr_accessor :path, :root_dir

  def initialize path, root_dir = '..'
    @path = path
    @root_dir = root_dir
  end

  def load
    # 이 파일은 lib 안에 있지만, 아래 경로는 최상위 폴더를 기준으로 찾는다
    File.read(File.expand_path(File.join('.', path))).strip.split("\n")
  end

  def bundle_dir dir
    File.join('..' + '/..' * (dir.split('/').size - 1), BUNDLE_DIR, dir)
  end
end
