module Roshambot

  class Player
    # Mixed probablistic and rules based with guidance from
    # http://mentalfloss.com/article/15039/how-win-rock-paper-scissors-and-also-how-cheat
    # and
    # http://ofb.net/~egnor/iocaine.html

    attr_reader :past, :past_counts, :runs

    BEAT_BY = {:rock => :paper, :scissors => :rock, :paper => :scissors}

    def initialize()
      reset()
    end

    def name
      'Roshambot::Player'
    end

    def reset(seed=nil)
      @past = []
      @past_counts = {
        :rock => 0,
        :paper => 0,
        :scissors => 0
      }
      @runs = {}
    end

    def last_competitor_throw=(throw)
      @past << throw
      @past_counts[throw] += 1
      start = (past.length - 11)
      start = 0 if start < 0
      hist = @past[start..-2]
      @runs[hist.compact] = throw if hist
    end

    def last_competitor_throw
      past.last
    end

    def double_run?
      past[-2] == past.last
    end

    def begining?
      !past.first
    end

    def unclear?
      p = past_counts.values.sort.reverse
      p[0] == p[1]
    end

    def historical_value
      10.downto(3) do |x|
        key = past.reverse[0..x].reverse
        if runs[key]
          return runs[key]
        end
      end
      nil
    end

    def throw
      if begining?
        :scissors
      elsif !!(hv = historical_value)
        BEAT_BY[hv]
      elsif double_run?
        would_have_lost_to(past.last)
      elsif unclear?
        would_have_lost_to(past.last)
      else
        BEAT_BY[past_counts.inject([:paper,0]) {|m,x| m[1] > x[1] ? m : x}[0]]
      end
    end

    def would_have_lost_to(throw)
      BEAT_BY[BEAT_BY[throw]]
    end
    private :would_have_lost_to

  end

end
