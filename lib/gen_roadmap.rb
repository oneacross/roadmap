#!/usr/bin/env ruby

require 'yaml'
require 'erb'
require 'csv'
require 'ostruct'
require 'date'

def validate_features(features)
  features.each do |feat|
      if !feat.has_key?('estimated_effort')
          raise NotImplementedError, "Topic #{feat['name']} does not have an estimated_effort"
      end

      if feat.has_key?('start_date')
          if !feat.has_key?('owner')
              raise NotImplementedError, "Topic #{feat['name']} has a start_date, but no owner"
          end
      end
  end
end

def increment_start_date(start_date, effort_days)
    # Increment start_date, skipping weekends
    increment_map = {
        1 => 1,
        2 => 1,
        3 => 1,
        4 => 1,
        # Friday => Monday
        5 => 3,
    }

    effort_days.times do
        start_date += increment_map[start_date.to_date.wday]
    end
    start_date
end

def parse_estimated_effort(estimated_effort)
    if estimated_effort =~ /week/
        effort_days = estimated_effort.match(/(?<week>\d+)/)[:week].to_i * 5
    elsif estimated_effort =~ /day/
        effort_days = estimated_effort.match(/(?<day>\d+)/)[:day].to_i
    end
    effort_days
end

def populate_start_dates(features, workers)
    day_free = {}

    # Initializer each worker's free day to today.
    workers.each do |worker|
      day_free[worker] = DateTime.now
    end

    validate_features(features)

    features.each do |feat|
        estimated_effort = feat['estimated_effort']

        if feat.has_key?('start_date')
            worker = feat['owner']
            start_date = DateTime.parse(feat['start_date'])
        else
            # Pick the worker who is free first
            worker, start_date = day_free.min_by { |wrkr, free_date| free_date }

            feat['start_date'] = start_date.strftime("%B %e, %Y")
        end

        effort_days = parse_estimated_effort(estimated_effort)

        start_date = increment_start_date(start_date, effort_days)

        # May have prior, longer task
        day_free[worker] = [start_date, day_free[worker]].max
    end
end

def main()
  features = YAML::load_file('features.yml')
  populate_start_dates(features)

  erb = ERB.new(File.read('roadmap.rhtml'))
  output = erb.result(binding)

  # Static HTML file to link to from wiki.
  File.open("roadmap.html", "w") do |f|
    f.write(output)
  end

  # Create CSV file for managers to use
  CSV.open("roadmap.csv", "w") do |csv|
    csv << ['name', 'owner', 'estimated_effort', 'start_date', 'end_date']
    features.each do |f|
      csv << [f['name'], f['owner'], f['estimated_effort'], f['start_date'], f['end_date']]
    end
  end
end
