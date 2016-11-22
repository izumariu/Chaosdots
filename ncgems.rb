begin
  require 'rubygems'
  require 'bundler/setup'
  require 'mkmf'
  require 'open3'
  needed_bins = %w[convert pnminvert tail dd nc]
  bins_exist = Array.new
  needed_bins.each{|bin|find_executable(bin).nil?&&bins_exist.push(bin)}
  bins_exist.empty?||(
    emsg = "Please install ";
    last = bins_exist.pop;
    misbins = [(needed_bins-bins_exist).join(", "),last].map{|i|i!=""};
    misbins = misbins.join(" and ");
    emsg = "Please install #{misbins}!"
    raise(Exception.new(emsg))
  )
rescue => e
  puts "\e[31mFATAL: " << e.message << "\e[0m"
  abort
end

Bundler.require