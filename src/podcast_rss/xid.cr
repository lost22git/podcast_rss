# A xid implementation for crystal
#
# ## resources:
#
# - https://github.com/rs/xid
# - https://github.com/kazk/xid-rs
#

require "digest/md5"

{% if flag?(:linux) %}
  require "digest/crc32"
{% end %}

alias B12 = StaticArray(UInt8, 12)
alias B4 = StaticArray(UInt8, 4)
alias B3 = StaticArray(UInt8, 3)
alias B2 = StaticArray(UInt8, 2)

class XidError < Exception
end

record PodcastRss::Xid,
  time : B4, machine_id : B3, process_id : B2, count : B3 do
  @@machine_id : B3 = load_machine_id
  @@process_id : B2 = load_process_id
  @@counter : Atomic(UInt32) = Atomic(UInt32).new Random.new.rand(UInt32)

  def self.generate : Xid
    Xid.new time: read_time, machine_id: @@machine_id, process_id: @@process_id, count: next_count
  end

  @[AlwaysInline]
  private def self.read_time : B4
    ts = Time.utc.to_unix.to_u32
    ts.unsafe_as(B4).reverse!
  end

  @[AlwaysInline]
  private def self.next_count : B3
    v = @@counter.add 1
    UInt8.static_array v >> 16, v >> 8, v >> 0
  end

  @[AlwaysInline]
  def self.from_bytes(raw : B12) : PodcastRss::Xid
    Xid.new(
      time: B4[raw[0], raw[1], raw[2], raw[3]],
      machine_id: B3[raw[4], raw[5], raw[6]],
      process_id: B2[raw[7], raw[8]],
      count: B3[raw[9], raw[10], raw[11]]
    )
  end

  def self.from_s(base32 : String) : PodcastRss::Xid
    base32 = base32.downcase
    raise XidError.new("XID: not a valid base32 string") unless base32.matches_full? /[0-9a-v]{20}/
    raw = base32.to_slice
    base32_decode(raw).unsafe_as Xid
  end

  # as **read-only** view `Bytes`
  #
  def as_bytes : Bytes
    Bytes.new pointerof(@time).as(UInt8*), 12, read_only: true
  end

  def to_s : String
    base32_encode as_bytes
  end

  def time : Time
    Time.unix IO::ByteFormat::BigEndian.decode(UInt32, @time.to_slice)
  end

  def machine_id : UInt32
    v = @machine_id
    v[0].to_u32 << 16 | v[1].to_u32 << 8 | v[2].to_u32
  end

  def process_id : UInt16
    IO::ByteFormat::BigEndian.decode(UInt16, @process_id.to_slice)
  end

  def count : UInt32
    v = @count
    v[0].to_u32 << 16 | v[1].to_u32 << 8 | v[2].to_u32
  end

  def debug
    puts "XID".ljust(15) + " : " + self.inspect
    puts "XID string".ljust(15) + " : " + self.to_s
    puts "XID time".ljust(15) + " : " + time().inspect
    puts "XID machine_id".ljust(15) + " : " + machine_id().inspect
    puts "XID process_id".ljust(15) + " : " + process_id().inspect
    puts "XID count".ljust(15) + " : " + count().inspect
  end
end

BASE32_ENC = "0123456789abcdefghijklmnopqrstuv"
BASE32_DEC = begin
  a = StaticArray(UInt8, 256).new 0

  # '0' ~ '9'
  #
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

@[AlwaysInline]
private def base32_encode(raw : Bytes) : String
  String.build 20 do |io|
    io << BASE32_ENC[raw[0] >> 3]
    io << BASE32_ENC[(raw[1] >> 6) & 0x1F | (raw[0] << 2) & 0x1F]
    io << BASE32_ENC[(raw[1] >> 1) & 0x1F]
    io << BASE32_ENC[(raw[2] >> 4) & 0x1F | (raw[1] << 4) & 0x1F]
    io << BASE32_ENC[raw[3] >> 7 | (raw[2] << 1) & 0x1F]
    io << BASE32_ENC[(raw[3] >> 2) & 0x1F]
    io << BASE32_ENC[raw[4] >> 5 | (raw[3] << 3) & 0x1F]
    io << BASE32_ENC[raw[4] & 0x1F]
    io << BASE32_ENC[raw[5] >> 3]
    io << BASE32_ENC[(raw[6] >> 6) & 0x1F | (raw[5] << 2) & 0x1F]
    io << BASE32_ENC[(raw[6] >> 1) & 0x1F]
    io << BASE32_ENC[(raw[7] >> 4) & 0x1F | (raw[6] << 4) & 0x1F]
    io << BASE32_ENC[raw[8] >> 7 | (raw[7] << 1) & 0x1F]
    io << BASE32_ENC[(raw[8] >> 2) & 0x1F]
    io << BASE32_ENC[(raw[9] >> 5) | (raw[8] << 3) & 0x1F]
    io << BASE32_ENC[raw[9] & 0x1F]
    io << BASE32_ENC[raw[10] >> 3]
    io << BASE32_ENC[(raw[11] >> 6) & 0x1F | (raw[10] << 2) & 0x1F]
    io << BASE32_ENC[(raw[11] >> 1) & 0x1F]
    io << BASE32_ENC[(raw[11] << 4) & 0x1F]
  end
end

@[AlwaysInline]
private def base32_decode(ch : Bytes) : B12
  UInt8.static_array(
    BASE32_DEC[ch[0]] << 3 | BASE32_DEC[ch[1]] >> 2,
    BASE32_DEC[ch[1]] << 6 | BASE32_DEC[ch[2]] << 1 | BASE32_DEC[ch[3]] >> 4,
    BASE32_DEC[ch[3]] << 4 | BASE32_DEC[ch[4]] >> 1,
    BASE32_DEC[ch[4]] << 7 | BASE32_DEC[ch[5]] << 2 | BASE32_DEC[ch[6]] >> 3,
    BASE32_DEC[ch[6]] << 5 | BASE32_DEC[ch[7]],
    BASE32_DEC[ch[8]] << 3 | BASE32_DEC[ch[9]] >> 2,
    BASE32_DEC[ch[9]] << 6 | BASE32_DEC[ch[10]] << 1 | BASE32_DEC[ch[11]] >> 4,
    BASE32_DEC[ch[11]] << 4 | BASE32_DEC[ch[12]] >> 1,
    BASE32_DEC[ch[12]] << 7 | BASE32_DEC[ch[13]] << 2 | BASE32_DEC[ch[14]] >> 3,
    BASE32_DEC[ch[14]] << 5 | BASE32_DEC[ch[15]],
    BASE32_DEC[ch[16]] << 3 | BASE32_DEC[ch[17]] >> 2,
    BASE32_DEC[ch[17]] << 6 | BASE32_DEC[ch[18]] << 1 | BASE32_DEC[ch[19]] >> 4,
  )
end

private def load_machine_id : B3
  machine_id = {% if flag?(:linux) %}
                 load_machine_id_on_linux
               {% else %}
                 raise XidError.new("XID: unimplemented on the platform")
               {% end %}
  sum = md5sum machine_id
  UInt8.static_array(sum[0], sum[1], sum[2])
end

private def md5sum(input : Bytes) : Bytes
  md5 = Digest::MD5.new
  md5 << input
  md5.final
end

private def load_machine_id_on_linux : Bytes
  # https://github.com/kazk/xid-rs/blob/9d1fd22d281c379362888bf729a927509f2d8ffc/src/machine_id.rs#L38
  #
  try_paths = ["/var/lib/dbus/machine-id", "/etc/machine-id"]
  try_paths.each do |path|
    begin
      s = File.read(path).strip
      if s != ""
        puts "XID: load machine id: #{s}"
        return s.to_slice
      end
      puts "XID: failed to load machine id, read `#{path}` is blank, trying next path"
    rescue ex : Exception
      puts "XID: failed to load machine id, read `#{path}` failed, trying next path"
    end
  end
  raise XidError.new("XID: failed to load machine id")
end

private def load_process_id : B2
  # https://github.com/kazk/xid-rs/blob/9d1fd22d281c379362888bf729a927509f2d8ffc/src/pid.rs#L8
  #
  pid = Process.pid.to_u32

  {% if flag?(:linux) %}
    begin
      s = File.read("/proc/self/cpuset").strip
      puts "XID: read `/proc/self/cpuset`: #{s}"
    rescue ex : Exception
    end

    if s && !s.blank?
      pid ^= Digest::CRC32.checksum(s).to_u32
    end
  {% end %}

  puts "XID: load process id: #{pid}"

  UInt8.static_array(pid >> 8, pid)
end
