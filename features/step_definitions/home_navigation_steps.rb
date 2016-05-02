Then(/^User should see the evaluations page for (.+)$/) do |term|
  current_path.should == "/evaluation/#{term}"
end

Then(/^User should see the faculty member historical data page$/) do
  current_path.should == '/instructor'
end
