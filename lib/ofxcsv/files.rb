require 'fileutils'

module Files
  class Dir
    attr_reader :path

    def initialize(path)
      @path = path.strip.chomp '/'
      FileUtils.mkdir_p @path
      self
    end

    def open(file_name, access='w+', &block)
      File.open("#{path}/#{file_name}", access) { |file| block.call file }      
    end

    def sub_dir(sub_path)
      Dir.new "#{path}/#{sub_path.strip.chomp '/'}"
    end

    def to_s
      path
    end
  end
end
