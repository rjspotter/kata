require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Roshambot" do
  describe "Player" do
    subject {Roshambot::Player.new()}
    it "has a past" do
      subject.last_competitor_throw = :rock
      subject.past.should == [:rock]
    end

    it "accesses the past" do
      subject.last_competitor_throw = :rock
      subject.last_competitor_throw.should == :rock
    end

    it "counts the past" do
      subject.last_competitor_throw = :rock
      subject.past_counts[:rock].should == 1
    end

    it "tracks double runs" do
      subject.last_competitor_throw = :rock
      subject.last_competitor_throw = :rock
      subject.double_run?.should == true
      subject.last_competitor_throw = :paper
      subject.double_run?.should == false
    end

    it "knows no history" do
      subject.begining?.should == true
      subject.last_competitor_throw = :rock
      subject.begining?.should == false
    end

    it "identifies frequency ties" do
      subject.last_competitor_throw = :rock
      subject.last_competitor_throw = :paper
      subject.unclear?.should == true
      subject.last_competitor_throw = :rock
      subject.unclear?.should == false
    end

    it "saves historical runs" do
      subject.last_competitor_throw = :rock
      subject.last_competitor_throw = :paper
      subject.last_competitor_throw = :scissors
      subject.last_competitor_throw = :rock
      subject.runs[[:rock,:paper,:scissors]].should == :rock
    end

    it "finds historical runs greater than 3" do
      subject.last_competitor_throw = :rock
      subject.last_competitor_throw = :paper
      subject.last_competitor_throw = :scissors
      subject.last_competitor_throw = :rock
      subject.historical_value.should == nil
      subject.last_competitor_throw = :rock
      subject.last_competitor_throw = :rock
      subject.last_competitor_throw = :paper
      subject.last_competitor_throw = :scissors
      subject.last_competitor_throw = :rock
      subject.historical_value.should == :rock
    end

    describe "throw logic" do
      it "throws scissors first" do
        subject.throw.should == :scissors
      end

      it "throws paper after a scissors double run" do
        subject.last_competitor_throw = :scissors
        subject.last_competitor_throw = :scissors
        subject.throw.should == :paper
      end

      it "throws scissors if there rock scissors tie and rock was last" do
        subject.last_competitor_throw = :scissors
        subject.last_competitor_throw = :rock
        subject.throw.should == :scissors
      end

      it "throws what would beat the most commonly thrown by opponent" do
        subject.last_competitor_throw = :scissors
        subject.last_competitor_throw = :scissors
        subject.last_competitor_throw = :scissors
        subject.last_competitor_throw = :scissors
        subject.last_competitor_throw = :rock
        subject.throw.should == :rock
      end
    end
  end
end
