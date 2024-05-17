#!/usr/bin/env ruby

require "yaml"

db = YAML.load_file("gem_db.yaml")
good = db[:good]
bad = db[:bad]

good.each_pair do |gem_name, info|
  info[:gem_name] = gem_name
end

to_consider = good.values.select do |g|
  license = g[:license]

  if license.nil? || license.empty?
    next
  end

  version = g[:version]

  if version =~ /^[1-9]\d*\.(\d+)\.(\d+)$/
    minor = Regexp.last_match(1)
    build = Regexp.last_match(2)

    minor.to_i > 0 || build.to_i > 0
  end
end

to_consider.each do |g|
  license = g[:license].downcase

  g[:license] = case license
                when "apache 2.0", "apache license 2.0", "apache license version 2.0", "apache license, version 2.0",
                  "http://www.apache.org/licenses/license-2.0.txt", "apache license v2.0", "apachev2", "apache2",
                  "apache 2", "apache v2", "apache license (2.0)"
                  "apache-2.0"
                when "agpl-3.0-only", "agpl3"
                  "agpl-3.0"
                when "gpl-3-license", "gpl-3", "gpl3", "gplv3"
                  "gpl-3.0"
                when "gplv2+", "gpl-2.0-only", "gpl-2.0-or-later", "gpl-2+", "gpl-2.0+"
                  "gpl-2.0+"
                when "gplv3+", "gpl-3.0-only", "gpl-3.0-or-later", "gpl-3+"
                  "gpl-3.0+"
                when "gpl-2", "gplv2", "gnu gpl v2", "gpl2"
                  "gpl-2.0"
                when "bsd 3-clause", "bsd-3"
                  "bsd-3-clause"
                when "mit license", "mit-license"
                  "mit"
                else
                  license
                end

  if license =~ /mozilla|\bmpl\b/
    # puts "#{g[:gem_name]} #{license}"
    puts g[:gem_name]
  end
end

by_license = to_consider.group_by { |gem| gem[:license] }

license_counts = by_license.transform_values(&:size).to_a.sort_by(&:last)
# license_counts = license_counts.reverse

license_counts.each do |(license, count)|
  # puts "#{license}: #{count}"
end
