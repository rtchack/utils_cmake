#
# Created by xing
#

module TC
  class << self

    def show(dev)
      ex "tc -s qdisc show dev #{dev} && tc -s class show dev #{dev}"
    end

    def clr(dev)
      ex "tc qdisc delete dev #{dev} root || tc qdisc del dev #{dev} ingress"
    end

    def add_netem(dev, emstr, proto,
                  src_ip: nil, src_port: nil, dst_ip: nil, dst_port: nil)
      matching_str = "match ip protocol #{ip_proto_no proto} 0xff"
      matching_str += " match ip src #{src_ip}" if src_ip && !src_ip.empty?
      matching_str += " match ip sport #{src_port} 0xffff" if src_port && !src_port.empty?
      matching_str += " match ip dst #{dst_ip}" if dst_ip && !dst_ip.empty?
      matching_str += " match ip dport #{dst_port} 0xffff" if dst_port && !dst_port.empty?

      ex "tc qdisc add dev #{dev} root handle 1: htb && \
  tc class add dev #{dev} parent 1: classid 1:10 htb rate 20mbps && \
  tc qdisc add dev #{dev} parent 1:10 handle 10: netem #{emstr} && \
  tc filter add dev #{dev} parent 1: protocol ip prio 0 u32 #{matching_str} flowid 1:10"
    end

    def add_ingress(dev, police_str, proto,
                    src_ip: nil, src_port: nil, dst_ip: nil, dst_port: nil)
      matching_str = "match ip protocol #{ip_proto_no proto} 0xff"
      matching_str += " match ip src #{src_ip}" if src_ip && !src_ip.empty?
      matching_str += " match ip sport #{src_port} 0xffff" if src_port && !src_port.empty?
      matching_str += " match ip dst #{dst_ip}" if dst_ip && !dst_ip.empty?
      matching_str += " match ip dport #{dst_port} 0xffff" if dst_port && !dst_port.empty?

      ex "tc qdisc add dev #{dev} ingress &&\
  tc filter add dev #{dev} parent ffff: protocol ip prio 0 u32 #{matching_str} \
  police #{police_str} flowid :1"
    end

    def limit(dev, nlimit, proto, dst_ip, dst_port)
      add_netem dev, "limit #{nlimit}", proto,
                dst_ip: dst_ip, dst_port: dst_port
    end

    def delay(dev, delay, proto, dst_ip, dst_port)
      add_netem dev, "delay #{delay}ms", proto,
                dst_ip: dst_ip, dst_port: dst_port
    end

    def loss(dev, percent, proto, dst_ip, dst_port)
      add_netem dev, "loss #{percent}%", proto,
                dst_ip: dst_ip, dst_port: dst_port
    end

    def corrupt(dev, percent, proto, dst_ip, dst_port)
      add_netem dev, "corrupt #{percent}%", proto,
                dst_ip: dst_ip, dst_port: dst_port
    end

    def jitter(dev, jt, proto, dst_ip, dst_port)
      add_netem dev,
                "delay #{jt.to_i + 8}ms #{jt}ms distribution normal",
                proto,
                dst_ip: dst_ip,
                dst_port: dst_port
    end

    def mix(dev, percent, jt, proto, dst_ip, dst_port)
      add_netem dev,
                "loss #{percent}% delay #{jt.to_i + 8}ms #{jt}ms distribution normal",
                proto,
                dst_ip: dst_ip,
                dst_port: dst_port
    end

    def rate(dev, kbps, npkts, proto, dst_ip, dst_port)
      add_netem dev,
                "rate #{kbps}Kbit limit #{npkts}",
                proto,
                dst_ip: dst_ip,
                dst_port: dst_port
    end

    def uprate(dev, kbps, proto, dst_ip, dst_port)
      burst = kbps
      burst = 8 if burst < 8

      # By default, allow burst time of 80000ms.
      # burst = ((burst + 7) & (~7)) * 8 >> 3

      add_ingress dev,
                  "rate #{kbps}Kbit burst #{burst}k",
                  proto,
                  dst_ip: dst_ip,
                  dst_port: dst_port
    end

  end
end
