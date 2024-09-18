module FixtureHelper
  DUMPED_FILE_PATH = File.join(__dir__, "fixtures", "test.dump")
  DUMPED_DATA = File.read(DUMPED_FILE_PATH)

  def fixture_data
    eval(File.read(File.join(__dir__, "fixtures", "data.rb"))) # rubocop:disable Security/Eval
  end

  def dumped_data
    DUMPED_DATA.dup
  end

  def with_dumped_file
    File.open(DUMPED_FILE_PATH, "r") do |io|
      yield io
    end
  end
end
