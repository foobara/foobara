#!/usr/bin/env ruby

require "yaml"
require "fileutils"

remote_gems = `gem list --remote`

db = if File.exist?("gem_db.yaml")
       YAML.load_file("gem_db.yaml")
     else
       { good: {}, bad: {} }
     end

good = db[:good]
bad = db[:bad]

begin
  remote_gems.split("\n").each do |line|
    if line !~ /^(\w.*) \(([\d.]+)([^)]*)\)$/
      puts "WARNING: unexpected line: #{line}"
      bad[line] = true
      next
    end

    gem_name = Regexp.last_match(1)
    version = Regexp.last_match(2)
    extra = Regexp.last_match(3)
    full_version = "#{version}#{extra}"

    next if good.key?(gem_name)

    gem_file_name = "#{gem_name}-#{version}.gem"
    puts ":#{gem_file_name}:"
    begin
      puts `gem fetch #{gem_name}`
      license_yaml = `gem specification "#{gem_file_name}" license`
      license = YAML.load(license_yaml)
      h = { version:, license: }
      if version != full_version
        h[:full_version] = full_version
      end
      good[gem_name] = h
    ensure
      begin
        FileUtils.rm(gem_file_name)
      rescue
        nil
      end
    end
  end
ensure
  File.write("gem_db.yaml", db.to_yaml)
end
