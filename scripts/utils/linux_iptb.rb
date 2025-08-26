#
# Created by xing
#

module Iptb
  class << self
    def show
      ex 'sudo iptables -S'
    end

    def clr
      ex 'sudo iptables -F'
    end

    def dropin(percent, proto)
      ex "iptables -A INPUT -p #{proto} -m statistic --mode random\
    --probability #{percent.to_i / 100.0} -j DROP"
    end

    def dropout(percent, proto)
      ex "iptables -A OUTPUT -p #{proto} -m statistic --mode random\
    --probability #{percent.to_i / 100.0} -j DROP"
    end
  end
end