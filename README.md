# GDBMish

Create and read GDBM dump ASCII files.

Citing [gdbm](https://git.gnu.org.ua/gdbm.git/tree/NOTE-WARNING):
> Gdbm files have never been `portable' between different operating systems,
> system architectures, or potentially even different compilers.  Differences
> in byte order, the size of file offsets, and even structure packing make
> gdbm files non-portable.
>
> Therefore, if you intend to send your database to somebody over the wire,
> please dump it into a portable format using gdbm_dump and send the resulting
> file instead. The receiving party will be able to recreate the database from
> the dump using the gdbm_load command.

GDBMish does that by reimplementing the `gdbm_dump` ASCII format without compiling against `gdbm`

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add gdbmish
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install gdbmish
```

## Usage

* API documentation is available at [rubydoc.info](https://www.rubydoc.info/gems/gdbmish)

```ruby
require 'gdbmish'

# Create a dump into a StringIO and read it back
io = StringIO.new
dumper = Gdbmish::Dump::Ascii.new(file: "test.db", uid: "1000", user: "ziggy", gid: "1000", group: "staff", mode: 0o640)
dumper.dump(io) do |dump|
  dump.push("some_key", "Some Value")
  dump.push("otherKey", "Other\nValue")
end

io.rewind
reader = Gdbmish::Read::Ascii.new(io, load_meta: :count)
reader.data.to_h  # => {"some_key"=>"Some Value", "otherKey"=>"Other\nValue"}
reader.meta.count # => 2
reader.meta.file  # => "test.db"
reader.meta.uid   # => "1000"

# Dumping a Hash

data = {"key1" => "value", "key2" => "value2"}

# Get dump as String
string = Gdbmish::Dump.ascii(data)

# Write directly into File (or any other IO)
File.open("my_db.dump", "w") do |file|
  Gdbmish::Dump.ascii(data, file)
end

# Provide an original filename
Gdbmish::Dump.ascii(data, file: "my.db")

# Provide an original filename and file permissions
Gdbmish::Dump.ascii(data, file: "my.db", uid: "1000", gid: "1000", mode: 0o600)

# Iterate over a data source and push onto an IO
fileoptions = {file: "my.db", uid: "1000", user: "ziggy", gid: "1000", group: "staff", mode: 0o600}
File.open("my.dump", "w") do |file|
  Gdbmish::Dump::Ascii.new(**fileoptions).dump(io) do |dump|
    MyDataSource.each do |key, value|
      dump.push(key.to_s, value.to_s)
    end
  end
end

# Read from a file

file = File.open("my.dump")
# The file is read lazily, don't close it before you're done reading from it
reader = Gdbmish::Read::Ascii.new(file)

# get meta data
reader.meta.file # => "my.db"

# either iterate over data:
reader.data do |key, value|
  puts "#{key.inspect} => #{value.inspect}"
end

# or use the Iterator to transform into Hash
reader.data.to_h

file.close
```

### Shenanigans

Reading data from a dump file is a lazy one way street. Once data is read, it's read. You can't seek or peak.  
However, you can rewind the `IO` and start over.

```ruby
File.open("my.dump") do |io|
  reader = Gdbmish::Read::Ascii.new(io)
  reader.data.to_h # => {"key1"=>"value1", "key2"=>"value2"}
  reader.data.to_h # => {}

  io.rewind
  reader.data.to_h # => {"key1"=>"value1", "key2"=>"value2"}

  reader.data.first # => ["key1", "value1"]
  reader.data.first # => ["key2", "value2"]
  io.rewind
  reader.data.first # => ["key1", "value1"]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/fnordfih/gdbmish.rb>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/fnordfih/gdbmish.rb/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GDBMish project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fnordfih/gdbmish.rb/blob/main/CODE_OF_CONDUCT.md).
