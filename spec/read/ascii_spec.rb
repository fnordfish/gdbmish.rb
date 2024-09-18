RSpec.describe Gdbmish::Read::Ascii do
  it "can read it's own dump" do
    io = StringIO.new
    dumper = Gdbmish::Dump::Ascii.new(file: "test.db", uid: "1000", user: "ziggy", gid: "1000", group: "staff", mode: 0o640)
    dumper.dump(io) do |dump|
      dump.push("some_key", "Some Value")
      dump.push("otherKey", "Other\nValue")
    end

    io.rewind
    file = Gdbmish::Read::Ascii.new(io, load_meta: :count)

    expect(file.data.to_h).to match({
      "some_key" => "Some Value",
      "otherKey" => "Other\nValue"
    })

    meta = file.meta
    expect(meta).not_to be_nil

    if meta
      expect(meta.file).to eq("test.db")
      expect(meta.uid).to eq("1000")
      expect(meta.user).to eq("ziggy")
      expect(meta.gid).to eq("1000")
      expect(meta.group).to eq("staff")
      expect(meta.mode).to eq(0o640)
      expect(meta.count).to eq(2)
    end
  end

  it "load_meta: false skips loading meta" do
    with_dumped_file do |io|
      f = Gdbmish::Read::Ascii.new(io, load_meta: false)
      expect(f.meta).to be_nil
      expect(f.data.to_h).to match(fixture_data)
    end
  end

  it "load_meta: true skips loading count in meta" do
    with_dumped_file do |io|
      f = Gdbmish::Read::Ascii.new(io, load_meta: true)
      meta = f.meta

      expect(meta).to be_a(Gdbmish::Read::AsciiMetaData)
      expect(meta.count).to be_nil if meta
      expect(f.data.to_h).to match(fixture_data)
    end
  end

  it "load_meta: :count loads count in meta" do
    with_dumped_file do |io|
      f = Gdbmish::Read::Ascii.new(io, load_meta: :count)

      meta = f.meta
      expect(meta).to be_a(Gdbmish::Read::AsciiMetaData)
      expect(meta.count).to eq(fixture_data.size) if meta
      expect(f.data.to_h).to match(fixture_data)
    end
  end
end
