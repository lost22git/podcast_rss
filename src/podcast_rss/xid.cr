# A xid implementation for crystal
#
# ## resources:
#
# - https://github.com/rs/xid
# - https://github.com/kazk/xid-rs
#

require "digest/crc32"
{% if flag?(:linux) %}
  require "digest/md5"
{% end %}

BASE32_ENC = "0123456789abcdefghijklmnopqrstuv"

BASE32_DEC = begin
  a = StaticArray(UInt8, 256).new 0

  a[48] = 0; a[49] = 1; a[50] = 2; a[51] = 3; a[52] = 4
  a[53] = 5; a[54] = 6; a[55] = 7; a[56] = 8; a[57] = 9

  # 'a' ~ 'v'
  #
  a[97] = 10; a[98] = 11; a[99] = 12; a[100] = 13
  a[101] = 14; a[102] = 15; a[103] = 16; a[104] = 17
  a[105] = 18; a[106] = 19; a[107] = 20; a[108] = 21
  a[109] = 22; a[110] = 23; a[111] = 24; a[112] = 25
  a[113] = 26; a[114] = 27; a[115] = 28; a[116] = 29
  a[117] = 30; a[118] = 31

  a
end

alias B12 = StaticArray(UInt8, 12)
alias B4 = StaticArray(UInt8, 4)
alias B3 = StaticArray(UInt8, 3)
alias B2 = StaticArray(UInt8, 2)

@[Packed]
record PodcastRss::Xid,
  time : B4, machine_id : B3, process_id : B2, count : B3 do
  # construct from base32 string
  #
  def self.from_s(base32 : String) : PodcastRss::Xid
    base32 = base32.downcase

    raise ArgumentError.new("not a valid base32 string") unless base32.matches_full? /[0-9a-v]{20}/

    ch = base32.to_unsafe

    Xid.new(
      time: B4[
        BASE32_DEC[ch[0]] << 3 | BASE32_DEC[ch[1]] >> 2,
        BASE32_DEC[ch[1]] << 6 | BASE32_DEC[ch[2]] << 1 | BASE32_DEC[ch[3]] >> 4,
        BASE32_DEC[ch[3]] << 4 | BASE32_DEC[ch[4]] >> 1,
        BASE32_DEC[ch[4]] << 7 | BASE32_DEC[ch[5]] << 2 | BASE32_DEC[ch[6]] >> 3,
      ],
      machine_id: B3[
        BASE32_DEC[ch[6]] << 5 | BASE32_DEC[ch[7]],
        BASE32_DEC[ch[8]] << 3 | BASE32_DEC[ch[9]] >> 2,
        BASE32_DEC[ch[9]] << 6 | BASE32_DEC[ch[10]] << 1 | BASE32_DEC[ch[11]] >> 4,
      ],
      process_id: B2[
        BASE32_DEC[ch[11]] << 4 | BASE32_DEC[ch[12]] >> 1,
        BASE32_DEC[ch[12]] << 7 | BASE32_DEC[ch[13]] << 2 | BASE32_DEC[ch[14]] >> 3,
      ],
      count: B3[
        BASE32_DEC[ch[14]] << 5 | BASE32_DEC[ch[15]],
        BASE32_DEC[ch[16]] << 3 | BASE32_DEC[ch[17]] >> 2,
        BASE32_DEC[ch[17]] << 6 | BASE32_DEC[ch[18]] << 1 | BASE32_DEC[ch[19]] >> 4,
      ]
    )
  end

  # construct from bytes
  #
  def self.from_bytes(bs : B12) : PodcastRss::Xid
    Xid.new(
      time: B4[bs[0], bs[1], bs[2], bs[3]],
      machine_id: B3[bs[4], bs[5], bs[6]],
      process_id: B2[bs[7], bs[8]],
      count: B3[bs[9], bs[10], bs[11]]
    )
  end

  # as **read-only** view `Bytes`
  #
  def as_bytes : Bytes
    Bytes.new(
      pointerof(@time).as(UInt8*),
      12,
      read_only: true
    )
  end

  # to base32 string
  #
  def to_s : String
    id = self.as_bytes

    String.build 20 do |io|
      io << BASE32_ENC[(id[0] >> 3).to_u32]
      io << BASE32_ENC[((id[1] >> 6) & 0x1F | (id[0] << 2) & 0x1F).to_u32]
      io << BASE32_ENC[((id[1] >> 1) & 0x1F).to_u32]
      io << BASE32_ENC[((id[2] >> 4) & 0x1F | (id[1] << 4) & 0x1F).to_u32]
      io << BASE32_ENC[(id[3] >> 7 | (id[2] << 1) & 0x1F).to_u32]
      io << BASE32_ENC[((id[3] >> 2) & 0x1F).to_u32]
      io << BASE32_ENC[(id[4] >> 5 | (id[3] << 3) & 0x1F).to_u32]
      io << BASE32_ENC[(id[4] & 0x1F).to_u32]
      io << BASE32_ENC[(id[5] >> 3).to_u32]
      io << BASE32_ENC[((id[6] >> 6) & 0x1F | (id[5] << 2) & 0x1F).to_u32]
      io << BASE32_ENC[((id[6] >> 1) & 0x1F).to_u32]
      io << BASE32_ENC[((id[7] >> 4) & 0x1F | (id[6] << 4) & 0x1F).to_u32]
      io << BASE32_ENC[(id[8] >> 7 | (id[7] << 1) & 0x1F).to_u32]
      io << BASE32_ENC[((id[8] >> 2) & 0x1F).to_u32]
      io << BASE32_ENC[((id[9] >> 5) | (id[8] << 3) & 0x1F).to_u32]
      io << BASE32_ENC[(id[9] & 0x1F).to_u32]
      io << BASE32_ENC[(id[10] >> 3).to_u32]
      io << BASE32_ENC[((id[11] >> 6) & 0x1F | (id[10] << 2) & 0x1F).to_u32]
      io << BASE32_ENC[((id[11] >> 1) & 0x1F).to_u32]
      io << BASE32_ENC[((id[11] << 4) & 0x1F).to_u32]
    end
  end

  # get `utc time` of xid
  #
  def time : Time
    Time.unix IO::ByteFormat::BigEndian.decode(UInt32, @time.to_slice)
  end

  # get `machine id` of xid
  #
  def machine_id : UInt32
    result = 0_u32
    @machine_id.to_slice.copy_to(pointerof(result).as(UInt8*) + 1, 3)
    result
  end

  # get `process id` of xid
  #
  def process_id : UInt16
    IO::ByteFormat::BigEndian.decode(UInt16, @process_id.to_slice)
  end

  # get `count` of xid
  #
  def count : UInt32
    result = 0_u32
    @count.to_slice.copy_to(pointerof(result).as(UInt8*) + 1, 3)
    result
  end

  def print
    puts "XID".ljust(15) + " : " + self.inspect
    puts "XID string".ljust(15) + " : " + self.to_s
    puts "XID time".ljust(15) + " : " + time().inspect
    puts "XID machine_id".ljust(15) + " : " + machine_id().inspect
    puts "XID process_id".ljust(15) + " : " + process_id().inspect
    puts "XID count".ljust(15) + " : " + count().inspect
  end
end

# Xid Generator
#
class PodcastRss::XidGenerator
  class_getter global = XidGenerator.new

  # TODO: lazy
  @@machine_id : B3 = load_machine_id
  @@process_id : B2 = load_process_id

  @count : Atomic(UInt32)

  def initialize
    @count = Atomic(UInt32).new Random.new.rand(UInt32)
  end

  def gen_id : PodcastRss::Xid
    Xid.new(
      time: read_time,
      machine_id: @@machine_id,
      process_id: @@process_id,
      count: next_count
    )
  end

  private def read_time : B4
    ts = Time.utc.to_unix.to_u32

    UInt8.static_array(
      ts >> 24,
      ts >> 16,
      ts >> 8,
      ts >> 0,
    )
  end

  private def next_count : B3
    _count = @count.add 1

    UInt8.static_array(
      _count >> 16,
      _count >> 8,
      _count >> 0
    )
  end

  def self.load_machine_id : B3
    {% if flag?(:linux) %}
      # https://github.com/kazk/xid-rs/blob/9d1fd22d281c379362888bf729a927509f2d8ffc/src/machine_id.rs#L38
      #
      machine_id_paths = ["/var/lib/dbus/machine-id", "/etc/machine-id"]
      while true
        path = machine_id_paths.pop?
        raise "Can not load machine id" unless path
        begin
          s = File.read(path).strip
          break unless s.blank?
          puts "XID: Can not load machine id: the content of `#{path}` is blank, try next"
        rescue _e : Exception
          puts "XID: Can not load machine id: read file `#{path}` failed, try next"
        end
      end

      puts "XID: load machine id: #{s}"

      md5 = Digest::MD5.new
      md5 << s
      final = md5.final
      UInt8.static_array(final[0], final[1], final[2])
    {% else %}
      # TODO
      raise "XID: Unimplemented on the platform"
    {% end %}
  end

  def self.load_process_id : B2
    # https://github.com/kazk/xid-rs/blob/9d1fd22d281c379362888bf729a927509f2d8ffc/src/pid.rs#L8
    #
    pid = Process.pid.to_u32

    begin
      s = File.read("/proc/self/cpuset").strip
      puts "XID: load pid: #{s}"
    rescue ex : Exception
    end

    if s && !s.blank?
      pid = pid ^ Digest::CRC32.checksum(s).to_u32
    end

    UInt8.static_array(pid >> 8, pid)
  end
end
