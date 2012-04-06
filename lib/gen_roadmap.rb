#!/usr/bin/env ruby

require 'yaml'
require 'erb'
require 'csv'
require 'ostruct'
require 'date'

def populate_start_dates(features, workers)
    day_free = {}

    # Initializer each worker's free day to today.
    workers.each do |worker|
      day_free[worker] = DateTime.now
    end

    features.each do |feat|
        if !feat.has_key?('estimated_effort')
            raise NotImplementedError, "Topic #{feat['name']} does not have an estimated_effort"
        end
        estimated_effort = feat['estimated_effort']

        if feat.has_key?('start_date')
            if !feat.has_key?('owner')
                raise NotImplementedError, "Topic #{feat['name']} has a start_date, but no owner"
            end

            worker = feat['owner']
            start_date = DateTime.parse(feat['start_date'])
        else
            # Pick the worker who is free first
            worker = day_free.min_by { |worker, free_date| free_date }[0]

            start_date = day_free[worker]

            # Update start_time
            feat['start_date'] = start_date.strftime("%B %e, %Y")
        end

        if estimated_effort =~ /week/
            effort_days = estimated_effort.match(/(?<week>\d+)/)[:week].to_i * 5
        elsif estimated_effort =~ /day/
            effort_days = estimated_effort.match(/(?<day>\d+)/)[:day].to_i
        end

        # Skip weekends
        effort_days.times do
            if start_date.to_date.wday == 5
                # Friday => Monday
                start_date += 3
            else
                start_date += 1
            end
        end

        # May have earlier, longer task
        if (start_date > day_free[worker])
            day_free[worker] = start_date
        end
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
