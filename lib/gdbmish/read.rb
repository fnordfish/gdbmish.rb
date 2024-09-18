require "base64"

module Gdbmish
  # Wrapper for reading GDBM dump files. Currently, only Ascii (aka standard) format is supported.
  #
  # See {Gdbmish::Read::Ascii} for the main high level interface.
  module Read
    # Main abstraction to read an GDBM Ascii dump file (aka "standard format")
    #
    # @example
    #   File.open("path/to/file.dump") do |io|
    #     file = Gdbmish::Read::Ascii.new(io)
    #
    #     file.data do |key, value|
    #       puts "#{key.inspect} => #{value.inspect}"
    #     end
    #     pp file.meta
    #
    #     # Note: your `io`'s file pointer posistion has changed.
    #     io.pos # => 317
    #   end
    #
    #   # Produces:
    #   # "some_key" => "Some Value"
    #   # "otherKey" => "Other\nValue"
    #   #<Gdbmish::Read::AsciiMetaData @count=nil, @file="test.db", @gid="1000", @group="staff", @mode=384, @uid="1000", @user="ziggy", @version="1.1">
    class Ascii
      # Create a new Ascii reader.
      #
      # *load_meta* can be:
      #
      # - `true` (default) load meta data, but skip `count` for preformance reasons.
      # - `false` skip loading meta data.
      # - `:count` load meta data, including `count`.
      #
      # @param io [IO] The IO to read from. Assumed to point to the beginning of the GDBM dump.
      # @param load_meta [Boolean, Symbol] Whether to load meta data.
      # @param encoding [String,Encoding] The encoding to use for key/value pairs.
      def initialize(io, load_meta: true, encoding: Encoding::UTF_8)
        @io = io
        @load_meta = load_meta
        @encoding = encoding
      end

      # Returns an Enumerator over key/value pairs.
      # Given a block, it will yield each key/value pair, which is a shortcut for `#data.each`.
      #
      # @note This will consume the IO, so you can only iterate once. After that, you need to rewind the IO.
      #
      # Depending on the size of the dataset, you might want to read everything into an Array or Hash:
      # ```
      # Ascii.new(io1).data.to_a # => [["some_key", "Some Value"], ["otherKey", "Other\nValue"]]
      # Ascii.new(io2).data.to_h # => {"some_key" => "Some Value", "otherKey" => "Other\nValue"}
      # ```
      #
      # @yield [key, value] for each key/value pair
      # @yieldparam key [String] the key
      # @yieldparam value [String] the value
      # @return [AsciiDataIterator] if no block is given
      def data(&block)
        load_meta!
        @data_iterator ||= AsciiDataIterator.new(@io, encoding: @encoding)
        block ? @data_iterator.each(&block) : @data_iterator
      end

      # Parses for meta data, depending on the *load_meta* value in {#initialize}
      # @return [AsciiMetaData,nil] the meta data if loaded
      def meta
        load_meta!
      end

      private

      def load_meta!
        return unless @load_meta

        @meta ||= AsciiMetaData.parse(@io, ignore_count: @load_meta != :count)
      end
    end

    # Header and footer meta data from a GDBM Ascii dump file.
    class AsciiMetaData
      attr_reader :version, :file, :uid, :user, :gid, :group, :mode, :count

      def initialize(version: nil, file: nil, uid: nil, user: nil, gid: nil, group: nil, mode: nil, count: nil)
        @version = version
        @file = file
        @uid = uid
        @user = user
        @gid = gid
        @group = group
        @mode = mode
        @count = count
      end

      # Parse given IO for meta data.
      # Reads from +io+ until a `"# End of header"` line is found (enhancing its `pos`).
      # By default, ignores reading the `count` (indecating the amount of datasets in the file)
      # because it is written at the end of the file.
      def self.parse(io, ignore_count: true)
        version = nil
        file = nil
        uid = nil
        user = nil
        gid = nil
        group = nil
        mode = nil
        count = nil

        while (line = io.gets(chomp: true))
          break if line == "# End of header"

          next unless line.start_with?("#:")

          line[2..].split(",") do |e|
            k, v = e.split("=")
            case k
            when "version"
              version = v
            when "file"
              file = v
            when "uid"
              uid = v
            when "user"
              user = v
            when "gid"
              gid = v
            when "group"
              group = v
            when "mode"
              mode = v.to_i(8)
            end
          end
        end

        count = read_count(io) unless ignore_count

        new(version: version, file: file, uid: uid, user: user, gid: gid, group: group, mode: mode, count: count)
      end

      def self.read_count(io)
        count = nil
        end_of_header_pos = begin
          io.pos
        rescue
          # ignore error, this io does not support pos
          nil
        end

        return if end_of_header_pos.nil?

        while (line = io.gets(chomp: true))
          next unless line.start_with?("#:count")
          count = line.split("=")[1].to_i
        end
        io.pos = end_of_header_pos

        count
      end

      private_class_method :read_count
    end

    # Iterates over lines, skipping comments, joining wrapped lines.
    # Lines are alternating key or value in encoded form.
    # @note Users should not need to use this directly, but rather {Gdbmish::Read::Ascii#data}.
    class AsciiLineIterator
      include Enumerable

      # Comment lines start with '#'
      COMMENT_BYTE = "#".ord

      def initialize(io)
        @io = io
      end

      # Iterates over encoded lines, skipping comments, joining wrapped lines.
      # @yield [String] The still encoded, joined line
      def each
        while (line = @io.gets(chomp: true))
          next if line.bytes.first == COMMENT_BYTE

          data = line.dup

          until next_is_comment?
            data << @io.gets(chomp: true)
          end

          yield data
        end
      end

      private

      def next_is_comment?
        next_byte = @io.readbyte
        return false if next_byte.nil?

        @io.seek(-1, IO::SEEK_CUR)
        next_byte == COMMENT_BYTE
      end
    end

    # Iterates over data and returns decoded key/value pairs.
    # @note Users should not need to use this directly, but rather {Gdbmish::Read::Ascii#data}.
    class AsciiDataIterator
      include Enumerable

      def initialize(io, encoding: Encoding::UTF_8)
        @iterator = AsciiLineIterator.new(io)
        @encoding = encoding
      end

      # Iterates over key/value pairs, decoding them.
      # @yield [String,String] The decoded key and value
      def each
        @iterator.each_slice(2) do |k, v|
          k = Base64.decode64(k).force_encoding(@encoding)
          v = Base64.decode64(v).force_encoding(@encoding) unless v.nil?
          yield [k, v]
        end
      end
    end
  end
end
