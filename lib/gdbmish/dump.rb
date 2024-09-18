# frozen_string_literal: true

module Gdbmish
  # Wrapper for different dump formats, providing various shortcut methods.
  # Currently, there is only `Ascii` mode.
  #
  # Ascii mode optionally dumps file information such as filename, owner, mode.
  # See {Gdbmish::Dump::Ascii#new} on how they are used.
  module Dump
    # Dumping GDBM data as ASCII (aka default) format.
    class Ascii
      # Appends and counts {#push}ed data as ASCII dump format onto the given `io`.
      #
      # @note
      #   Users should not use this class directly, as it only represents the
      #   data part of an dump, without header and footer.
      #
      #   An instance of it gets yielded when using `Ascii#dump(io) { |appender| }`
      # @see Ascii#dump Gdbmish::Dump::Ascii#dump(io) { |appender| }
      class Appender
        # @return [Integer] The number of key/value pairs pushed
        attr_reader :count

        # @param io [IO] The IO to append to
        def initialize(io)
          @io = io
          @count = 0
        end

        # Push a *key*, *value* pair onto the dump
        # @param key [String] The key
        # @param value [String] The value
        def push(key, value)
          @count += 1
          @io << dump_datum(key)
          @io << dump_datum(value)
          nil
        end

        private

        def dump_datum(datum)
          result = sprintf("#:len=%d\n", datum.bytesize)
          encoded = Base64.strict_encode64(datum)
          if encoded.size > GDBM_MAX_DUMP_LINE_LEN
            encoded.gsub!(/(.{#{GDBM_MAX_DUMP_LINE_LEN}})/o, "\\1\n")
          end
          result << encoded << "\n"
        end
      end

      # GDBM does not split base64 strings at 60 encoded characters (as defined by RFC 2045).
      #
      # See `_GDBM_MAX_DUMP_LINE_LEN` in [gdbmdefs.h](https://git.gnu.org.ua/gdbm.git/tree/src/gdbmdefs.h)
      GDBM_MAX_DUMP_LINE_LEN = 76

      # Builds a new Ascii format dumper
      #
      # Dumping file information is optional.
      #
      # - *uid*, *user*, *gid*, *group* and *mode* will only be used when *file* is given
      # - *user* will only be used when *uid* is given
      # - *group* will only be used when *gid* is given
      #
      # @example
      #   fileoptions = {file: "test.db", uid: "1000", user: "ziggy", gid: "1000", group: "staff", mode: 0o600}
      #   File.open("test.dump", "w") do |file|
      #     Gdbmish::Dump::Ascii.new(**fileoptions).dump(file) do |appender|
      #       MyDataSource.each do |key, value|
      #         appender.push(key.to_s, value.to_s)
      #       end
      #     end
      #   end
      def initialize(file: nil, uid: nil, user: nil, gid: nil, group: nil, mode: nil)
        @file = file
        @uid = uid
        @user = user
        @gid = gid
        @group = group
        @mode = mode
      end

      # @overload dump(io)
      #   Dump only the header and footer
      #   @param io [IO] The IO to dump to
      #   @return [IO] The IO written to
      # @overload dump(io, data)
      #   Dump *data* to *io*
      #   @param io [IO] The IO to dump to
      #   @param data [#each_pair] The data to dump
      #   @return [IO] The IO written to
      # @overload dump(io, &block)
      #   Yield an {Appender} to call {Appender#push push} on.
      #   @param io [IO] The IO to dump to
      #   @yieldparam appender [Appender] The appender to push data onto the dump
      #   @return [IO] The IO written to
      # @overload dump(io, data, &block)
      #   Dump *data* to *io* and then yield an {Appender} to call {Appender#push push} on.
      #   @param io [IO] The IO to dump to
      #   @param data [#each_pair] The data to dump
      #   @yieldparam appender [Appender] The appender to push data onto the dump
      #   @return [IO] The IO written to
      def dump(io, data = nil, &block)
        appender = Appender.new(io)

        dump_header!(io)
        data&.each_pair do |k, v|
          appender.push(k.to_s, v.to_s)
        end
        yield appender if block
        dump_footer!(io, appender.count)

        io
      end

      private

      def dump_header!(io)
        io.printf("# GDBM dump file created by GDBMish version %s on %s\n", Gdbmish::VERSION, Time.now.rfc2822)
        io.puts("#:version=1.1")

        if @file
          io.printf("#:file=%s\n", @file)
          l = []

          if @uid
            l << sprintf("uid=%d", @uid)
            l << sprintf("user=%s", @user) if @user
          end

          if @gid
            l << sprintf("gid=%d", @gid)
            l << sprintf("group=%s", @group) if @group
          end

          l << sprintf("mode=%03o", @mode & 0o777) if @mode

          unless l.empty?
            io << "#:"
            io.puts(l.join(","))
          end
        end

        io.puts("#:format=standard")
        io.puts("# End of header")
      end

      def dump_footer!(io, count)
        io.printf("#:count=%d\n", count)
        io.puts("# End of data")
      end
    end

    # Dump *data* as standard ASCII format.
    # When an *io* is given, the dump will be written to it. Otherwise, a new `String` will be returned.
    # See {Dump::Ascii#initialize} for *fileoptions*.
    # See {Dump::Ascii#dump} for *data* and *block* behaviour.
    #
    # @param data [#each_pair,nil] The data to dump
    # @param io [IO,nil] The IO to dump to
    # @param fileoptions [Hash] Options for the dump file
    # @yield [appender] The appender to push data onto the dump
    # @return [String] The dump as a string when no *io* is given
    # @return [IO] The IO written to when *io* is given
    #
    # @example Dumping simple Hash into an IO
    #   File.open("test.dump", "w") do |file|
    #     Gdbmish::Dump.ascii({some: "data"}, file)
    #   end
    #
    # @example Dumping into a String
    #   string_dump = Gdbmish::Dump.ascii({some: "data"})
    #
    # @example Dumping into IO with file information and block
    #   Gdbmish::Dump.ascii(io, file: "test.db", uid: "1000", user: "ziggy", gid: "1000", group: "staff", mode: 0o600) do |appender|
    #     MyData.each do |object|
    #       appender.push(object.id, object.dump)
    #     end
    #   end
    def self.ascii(data = nil, io = nil, **fileoptions, &block)
      if io.nil?
        io = StringIO.new
        to_string = true
      end

      io = Ascii.new(**fileoptions).dump(io, data, &block)
      to_string ? io.string : io
    end
  end
end
