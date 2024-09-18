RSpec.describe Gdbmish::Dump::Ascii do
  let(:fileoptions) { {file: "test.db", uid: "1000", user: "ziggy", gid: "1000", group: "staff", mode: 0o600} }
  let(:data_hash) { {"key1" => "value1", "key2" => "value2"} }
  let(:dumped_without_header) { "#:count=2\n# End of data\n" }

  it "#dump with block" do
    io = StringIO.new
    Gdbmish::Dump::Ascii.new(**fileoptions).dump(io) do |dump|
      data_hash.each do |key, value|
        dump.push(key.to_s, value.to_s)
      end
    end
    str = io.string
    expect(str).to include("#:file=test.db")
    expect(str).to include("#:uid=1000,user=ziggy,gid=1000,group=staff,mode=600")
    expect(str).to end_with(dumped_without_header)
  end

  it "#dump with data_hash" do
    io = StringIO.new
    Gdbmish::Dump::Ascii.new(**fileoptions).dump(io, data_hash)
    str = io.string
    expect(str).to include("#:file=test.db")
    expect(str).to include("#:uid=1000,user=ziggy,gid=1000,group=staff,mode=600")
    expect(str).to end_with(dumped_without_header)
  end
end
