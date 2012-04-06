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

# Things I don't like:
# * Worker names are hardcoded.

describe "populate_start_dates" do
  it "populates initial start_date for one feature with no start_date" do
    features = [
      { 'name' => 'task1',
        'estimated_effort' => '1 day' }
    ]

    owners = ['worker1', 'worker2']
    populate_start_dates(features, owners)

    features[0]['start_date'].should == Date.today.strftime("%B %e, %Y")
  end

  it "populates future start_date to worker2" do
    features = [
      { 'name' => 'task1',
        'estimated_effort' => '1 day',
        'start_date' => Date.today.strftime("%B %e %Y"),
        'owner' => 'worker1' },
      { 'name' => 'task2',
        'estimated_effort' => '1 day' }
    ]

    owners = ['worker1', 'worker2']
    populate_start_dates(features, owners)

    features[1]['start_date'].should == Date.today.strftime("%B %e, %Y")
  end

  it "populates future start_date to worker1" do
    features = [
      { 'name' => 'task1',
        'estimated_effort' => '1 day',
        'start_date' => Date.today.strftime("%B %e %Y"),
        'owner' => 'worker1' },
      { 'name' => 'task2',
        'estimated_effort' => '1 day',
        'owner' => 'worker2' },
      { 'name' => 'task3',
        'estimated_effort' => '1 day' }
    ]

    owners = ['worker1', 'worker2']
    populate_start_dates(features, owners)

    # Takes account of weekend, this test only passes on Friday
    features[2]['start_date'].should == (Date.today + 3).strftime("%B %e, %Y")
  end

  it "every feature must have an estimated_effort" do
    features = [
      { 'name' => 'task1' }
    ]

    owners = ['worker1', 'worker2']
    expect {
      populate_start_dates(features, owners)
    }.to raise_error(NotImplementedError)
  end
end
