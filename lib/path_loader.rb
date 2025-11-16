class PathLoader
  attr_accessor :path

  def initialize path
    @path = path
  end

  def load
    # 이 파일은 lib 안에 있지만, 아래 경로는 최상위 폴더를 기준으로 찾는다
    File.read(File.expand_path(File.join('.', path))).strip.split("\n")
  end
end
