RSpec.describe Gdbmish::Read::AsciiLineIterator do
  it "iterates over encoded keys and values" do
    with_dumped_file do |io|
      read_data = Gdbmish::Read::AsciiLineIterator.new(io).to_a
      data_keys_values_encoded = fixture_data.to_a.flatten.map { |d| Base64.strict_encode64(d) }

      expect(read_data).to match_array(data_keys_values_encoded)
    end
  end
end
