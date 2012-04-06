require 'gen_roadmap'

# Given a list of tasks and efforts, setup a roadmap with dates.
# Take account for weekends
# Take account for vacation

# Task might look like:
# name: NAME
# effort: EFFORT (days or weeks)
# start_date: START_DATE (optional)

# Given a schedule, calculate the next free day.
# If a worker does not yet have a free date, then

describe "populate_start_dates" do
  it "populates start_date for feature without start_date" do
    features = [
      { 'name' => 'task1',
        'estimated_effort' => '1 day' }
    ]

    populate_start_dates(features)

    features[0]['start_date'].should == Date.today.strftime("%B %e, %Y")
  end
end
