require "./spec_helper"

describe PodcastRss::Xid do
  it "from_s and to_s" do
    s = "9m4e2mr0ui3e8a215n4g"
    xid = PodcastRss::Xid.from_s s
    xid.to_s.should eq s
  end

  it "from bytes" do
    xid = PodcastRss::Xid.from_bytes UInt8.static_array(
      0x4d, 0x88, 0xe1, 0x5b, 0x60, 0xf4, 0x86, 0xe4, 0x28, 0x41, 0x2d, 0xc9
    )
    xid.to_s.should eq "9m4e2mr0ui3e8a215n4g"
  end

  it "generate" do
    xid = PodcastRss::Xid.generate
    xid.debug
  end

  # NOTE: would be disordered in a second when counter overflow 3bytes
  #
  it "ordered!" do
    r = 1_000_000.times.map do |_|
      PodcastRss::Xid.generate.to_s
    end

    prev = ""
    curr = ""
    r.each do |it|
      curr = it
      if curr > prev
        prev = curr
      else
        puts "-" * 66
        PodcastRss::Xid.from_s(prev).debug
        puts "-" * 66
        PodcastRss::Xid.from_s(curr).debug
        raise "disordered!"
      end
    end
  end
end
