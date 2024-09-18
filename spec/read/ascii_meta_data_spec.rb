RSpec.describe Gdbmish::Read::AsciiMetaData do
  describe ".parse" do
    it "Reads meta fixture_data, skiping count" do
      with_dumped_file do |io|
        meta_data = Gdbmish::Read::AsciiMetaData.parse(io)
        expect(meta_data.count).to be_nil
        expect(meta_data.file).to eq "spec/fixtures/test.db"
        expect(meta_data.gid).to eq "20"
        expect(meta_data.group).to eq "staff"
        expect(meta_data.mode).to eq 0o644
        expect(meta_data.uid).to eq "501"
        expect(meta_data.user).to eq "robertschulze"
        expect(meta_data.version).to eq "1.1"
      end
    end
  end

  describe ".parse ignore_count: false" do
    it "Reads meta fixture_data, including count" do
      with_dumped_file do |io|
        meta_data = Gdbmish::Read::AsciiMetaData.parse(io, ignore_count: false)
        expect(meta_data.count).to eq fixture_data.size
        expect(meta_data.file).to eq "spec/fixtures/test.db"
        expect(meta_data.gid).to eq "20"
        expect(meta_data.group).to eq "staff"
        expect(meta_data.mode).to eq 0o644
        expect(meta_data.uid).to eq "501"
        expect(meta_data.user).to eq "robertschulze"
        expect(meta_data.version).to eq "1.1"
      end
    end
  end
end
