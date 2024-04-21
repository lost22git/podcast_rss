require "./spec_helper"

describe PodcastRss do
  # TODO: Write tests

  it "works" do
    true.should eq(true)
  end

  it "duckdb connect successfully" do
    PodcastRss::Repo.connect do |cnn|
      p! cnn.scalar "select 1"
    end
  end
end
