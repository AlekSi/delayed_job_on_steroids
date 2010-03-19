require File.dirname(__FILE__) + '/database'

describe Delayed::Worker do
  it "is singleton" do
    Delayed::Worker.included_modules.include?(Singleton).should == true
  end

  it "responds to methods moved from Job" do
    Delayed::JobDeprecations.instance_methods.each do |m|
      m = m.to_s.gsub("worker_", "").to_sym
      Delayed::Worker.respond_to?(m).should == true
      Delayed::Worker.instance.respond_to?(m).should == true
    end
  end
end
