require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'roshambo'

describe "dojo" do
  it "works" do
    expect do
      Roshambo::Dojo.new(Roshambot::Player.new , Roshambo::Competitor::SpazmanianDevil.new).fight
    end.to_not raise_error
  end
end
