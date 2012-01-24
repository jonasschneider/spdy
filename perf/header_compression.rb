require 'bundler'
Bundler.setup

require 'benchmark'
require 'spdy'

N = 100
headers = {
  "accept"=>"application/xml", "host"=>"127.0.0.1:9000",
  "method"=>"GET", "scheme"=>"https",
  "url"=>"/?echo=a&format=json","version"=>"HTTP/1.1"
}

Benchmark.bmbm(20) do |b|
  b.report('Create with compression') {
    zlib_session = SPDY::Zlib.new
    N.times do 
      sr = SPDY::Protocol::Control::SynStream.new({:zlib_session => zlib_session})
      sr.create({:stream_id => 1, :headers => headers})
    end
  }

  b.report('Create w/o compression') {
    N.times do 
      sr = SPDY::Protocol::Control::SynStream.new
      sr.create({:stream_id => 1, :headers => headers, :flags => SPDY::Protocol::FLAG_NOCOMPRESS})
    end
  }

  sending_zlib_session = SPDY::Zlib.new

  compressed = SPDY::Protocol::Control::SynStream.new({:zlib_session => sending_zlib_session})
  compressed.create({:stream_id => 1, :headers => headers})
  p compressed.to_binary_s

  uncompressed = SPDY::Protocol::Control::SynStream.new
  uncompressed.create({:stream_id => 1, :headers => headers, :flags => SPDY::Protocol::FLAG_NOCOMPRESS})

  b.report('Parse with compression') {
    zlib_session = SPDY::Zlib.new
    N.times do
      zlib_session.reset
      st = SPDY::Protocol::Control::SynStream.new({:zlib_session => zlib_session})
      st.parse(compressed.to_binary_s)
    end
  }

  b.report('Parse w/o compression') {
    N.times do 
      st = SPDY::Protocol::Control::SynStream.new
      st.parse(uncompressed.to_binary_s)
    end
  }
end