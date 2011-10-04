#!/user/bin/env ruby
require 'active_support/core_ext/hash'

bundle_gems = HashWithIndifferentAccess.new
file_gems = HashWithIndifferentAccess.new

def get_version *args
  raise 'MissingArgs' if args.nil? or args.empty?
  args.flatten!
  rlist = []
  args.each do |arg|
    rlist << Regexp.last_match(1) if /(['"](?:\d+\.?){3}['"])/ =~ arg.gsub(/\s/, '')
  end
  return nil if rlist.try(:join) == ""
  rlist.try(:join)
end

def get_git *args
  raise "MissingArgs" if args.nil? or args.empty?
  args.flatten!
  rlist=[]
  args.each_with_index do |arg, i|
    rlist[i] = Regexp.last_match(1) if /(\w+:\/\/[[:graph:]]+\.git)/ =~ arg
  end
  rlist.compact.first
end

def parseable_line? line
  return false if !(/(?:\d+\.?){3}/x.match(line)).nil?
  return true if !(/[\s]gem\s["'][[:graph:]]+["']$/.match(line)).nil?
  false
end

`bundle show | tr " (*)" " "`.split("\n").each do |line|
  next if line == "Gems included by the bundle:"
  line = line.split(' ')
  gem = line.first
  version = line[1]
  bundle_gems[gem] = version
end

file = File.new("Gemfile", "r")
file = file.read
file = file.split("\n")

file.each do |line|
  next if (/^gem\s/ =~ line.strip).nil?
  line = line.gsub('gem ', '').gsub(",","").split(" ")
  args = line.pop(line.size-1)
  gem = line.first.gsub(/\s/, '').gsub("\"", "").gsub("\'", "")
  file_gems[gem] = get_version(args)
end

newfile = String.new

file.each do |line|
  if  (/^gem\s/ =~ line.strip).nil? or line.blank? or line.nil?
    newfile << "#{line}\n" and next
  else
    line2 = line.gsub('gem ', '').split(",")
    line2[0] = line2[0].split("#")[0]
    args = line2.pop(line2.size-1)
    gem = line2.first.gsub(/\s/, '').gsub("\"", "").gsub("\'", "")
    version = get_version(args)
    args = args - [version]
    if file_gems[gem].nil?
      if args.empty?
        newfile << "gem '#{gem}', '#{bundle_gems[gem]}'\n"
      else
        newfile << "gem '#{gem}', '#{bundle_gems[gem]}', #{args.join(', ')}\n"
      end
    else
      newfile << "#{line}\n"
    end
  end
end

gemfile = File.new('newgems', "w+")
gemfile.write newfile
gemfile.close
