require "./spec_helper"

# describe PodcastRss::XidGenerator do
#  it "gen_id" do
#    id_gen = PodcastRss::XidGenerator.instance
#
#    ch = ::Channel(PodcastRss::Xid).new
#
#    20.times.each do |i|
#      spawn do
#        ch.send id_gen.gen_id
#      end
#    end
#
#    20.times.each do |i|
#      p! ch.receive
#    end
#  end
# end

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

  it "generator gen_id" do
    xid = PodcastRss::XidGenerator.instance.gen_id
    xid.print
  end

  it "order?" do
    r = 50000.times.map do |_|
      # sleep 10.milliseconds
      PodcastRss::XidGenerator.instance.gen_id.to_s
    end

    max = "0"
    r.each do |it|
      raise "disordered" unless it <=> max > 0
      max = it
    end
  end
end
