RSpec.describe Gdbmish::Dump do
  describe ".ascii" do
    let(:data_symbol_hash) { {key1: "value1", key2: "value2"} }
    let(:data_string_hash) { {"key1" => "value1", "key2" => "value2"} }
    let(:dumped_without_header) { "#:count=2\n# End of data\n" }

    it "Dumps Symbol Hash" do
      expect(Gdbmish::Dump.ascii(data_symbol_hash)).to end_with(dumped_without_header)
    end

    it "Dumps String Hash" do
      expect(Gdbmish::Dump.ascii(data_string_hash)).to end_with(dumped_without_header)
    end

    it "Dumps into an IO" do
      io = StringIO.new
      io << "# my open IO"

      Gdbmish::Dump.ascii(data_string_hash, io)
      str = io.string
      expect(str).to start_with("# my open IO")
      expect(str).to end_with(dumped_without_header)
    end

    it "Dumps filename and permissions" do
      str = Gdbmish::Dump.ascii(data_string_hash, file: "test.db", uid: "501", user: "robertschulze", gid: "20", group: "staff", mode: 0o600)
      expect(str).to include("#:file=test.db")
      expect(str).to include("#:uid=501,user=robertschulze,gid=20,group=staff,mode=600")
    end

    it "Dumps filename and partial permissions" do
      str = Gdbmish::Dump.ascii(data_string_hash, file: "test.db", uid: "501", gid: "20", mode: 0o600)
      expect(str).to include("#:file=test.db")
      expect(str).to include("#:uid=501,gid=20,mode=600")
    end

    it "Dumps skips permissions if filename is missing" do
      str = Gdbmish::Dump.ascii(data_string_hash, uid: "501", gid: "20", mode: 0o600)
      expect(str).not_to include("#:file=test.db")
      expect(str).not_to include("uid=501")
      expect(str).not_to include("gid=20")
      expect(str).not_to include("mode=600")
    end

    it "keeps lines at GDBM_MAX_DUMP_LINE_LEN" do
      expect(fixture_data.values.any? { |v| v.size > Gdbmish::Dump::Ascii::GDBM_MAX_DUMP_LINE_LEN }).to be true

      Gdbmish::Dump.ascii(fixture_data).split("# End of header\n")[1].each_line(chomp: true) do |line|
        expect(line.size).to be <= Gdbmish::Dump::Ascii::GDBM_MAX_DUMP_LINE_LEN
      end
    end

    it "run using generator/consumer api" do
      str = Gdbmish::Dump.ascii do |dump|
        data_string_hash.each do |k, v|
          dump.push(k.to_s, v.to_s)
        end
      end

      expect(str).to end_with(dumped_without_header)
    end
  end
end
