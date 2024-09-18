RSpec.describe Gdbmish::Read::AsciiDataIterator do
  it "iterates over decoded keys and values" do
    with_dumped_file do |io|
      read_data = Gdbmish::Read::AsciiDataIterator.new(io).to_h

      expect(read_data).to match(fixture_data)
    end
  end
end
