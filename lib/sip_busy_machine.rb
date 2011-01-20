require 'socket'
require 'thread'

class SipBusyMachine
  
  SIP_RINGING_TIME = 8 # Secs
  
  SIP_TRYING_FMT = <<eor
SIP/2.0 100 Trying\r
%s\r
From: %s\r
To: %s\r
Call-ID: %s\r
CSeq: %s INVITE\r
User-Agent: SipAnsweringMachine\r
Content-Length: 0\r
\r
eor

  SIP_RINGING_FMT = <<eor
SIP/2.0 180 Ringing\r
%s\r
From: %s\r
To: %s\r
Call-ID: %s\r
CSeq: %s INVITE\r
User-Agent: SipAnsweringMachine\r
Content-Length: 0\r
\r
eor

  SIP_BUSY_FMT = <<eor
SIP/2.0 486 Busy Here\r
%s\r
From: %s\r
To: %s\r
Call-ID: %s\r
CSeq: %s INVITE\r
User-Agent: SipAnsweringMachine\r
Content-Length: 0\r
\r
eor

  SIP_CANCEL_OK_FMT = <<eor
SIP/2.0 200 OK\r
%s\r
From: %s\r
To: %s\r
Call-ID: %s\r
CSeq: %s CANCEL\r
User-Agent: SipAnsweringMachine\r
Content-Length: 0\r
\r
eor


  protected
    attr_accessor :sd # Socket desctiptor  
    attr_accessor :logger
  
  public
    def initialize(params = {})
      @logger = params[:logger] || Rails.logger
      @port = params[:port] || 5060
      @address = params[:address] || '0.0.0.0'

      @serving_m = Mutex.new
      @serving_h = {}
    end

    def run
      current_retry = 0
      begin
        self.sd = UDPSocket.open
        sd.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
        self.sd.bind(@address, @port)
        loop do
          data, sender = self.sd.recvfrom(1500) # Ugly!
          Thread.new { 
            if validSIPServerAddress?( :address => sender[3] )
              serveSIPRequest(data, sender)
            end
          }
        end
        current_retry = 0
      rescue Exception => e
        @logger.error "Error! (#{e.to_s})"
      ensure
        @logger.error "Sip Busy Machine terminated! (#{$!})"
      end
    end

    def validSIPServerAddress?(params)
      params[:address] || raise("BUG: address parameter is required!")
      # default: do nothing!
      return true
    end

    def validPhoneNumbers?(params)
      params[:from] || raise("BUG: from parameter is required!")
      params[:to]   || raise("BUG: to parameter is required!")
      # default: do nothing!
      return true
    end

    def callback(params)
      params[:from] || raise("BUG: from parameter is required!")
      params[:to]   || raise("BUG: to parameter is required!")
    end

  private
  
    def parseINVITERequestHeader(header)
      result = {}
      header.each { |line|
        case line
        when /\AVia: (.+)\Z/
          result[:via] = result[:via].nil? ? [ $1 ] : result[:via] << $1
        when /\ARecord-Route: (.+)\Z/
          result[:record_route] = result[:record_route].nil? ? [ $1 ] : result[:record_route] << $1
        when /\ATo: (.+)\Z/
          result[:to] = $1
        when /\AFrom: (.+;tag=.+)\Z/
          result[:from] = $1
        when /\ACall-ID: (.+)\Z/i
          result[:call_id] = $1
        when /\ACSeq: (.+) INVITE\Z/i
          result[:cseq] = $1
        end
      }
      if result[:cseq].nil? or result[:call_id].nil? or result[:to].nil? or result[:from].nil? or result[:via].nil?
        nil
      else
        result
      end
    end

    def parseCANCELRequestHeader(header)
      result = {}
      header.each { |line|
        case line
        when /\AVia: (.+)\Z/
          result[:via] = result[:via].nil? ? [ $1 ] : result[:via] << $1
        when /\ATo: (.+)\Z/
          result[:to] = $1
        when /\AFrom: (.+;tag=.+)\Z/
          result[:from] = $1
        when /\ACall-ID: (.+)\Z/i
          result[:call_id] = $1
        when /\ACSeq: (.+) CANCEL\Z/i
          result[:cseq] = $1
        end
      }
      if result[:cseq].nil? or result[:call_id].nil? or result[:to].nil? or result[:from].nil? or result[:via].nil?
        nil
      else
        result
      end
    end

    def sendSIPBusyReply(params, sender)
      chost = sender[3]
      cport = sender[1]
      
      viarr = ''
      unless params[:via].nil?
        viarr = (params[:via].map{ |v| "Via: #{v}" }).join("\r\n")
      end
      unless params[:record_route].nil?
        viarr += "\r\n" + (params[:record_route].map{ |r| "Record-Route: #{r}" }).join("\r\n")
      end
      tag = rand(36 ** 10).to_s(36)

      self.sd.send(sprintf(SIP_TRYING_FMT,  viarr, params[:from], params[:to],                 params[:call_id], params[:cseq]), 0, chost, cport)
      self.sd.send(sprintf(SIP_RINGING_FMT, viarr, params[:from], "#{params[:to]};tag=#{tag}", params[:call_id], params[:cseq]), 0, chost, cport)
      sleep(SIP_RINGING_TIME)
      self.sd.send(sprintf(SIP_BUSY_FMT,    viarr, params[:from], "#{params[:to]};tag=#{tag}", params[:call_id], params[:cseq]), 0, chost, cport)
    end

    def sendSIPCancelOk(params, sender)
      chost = sender[3]
      cport = sender[1]
    
      viarr = (params[:via].map{ |v| "Via: #{v}" }).join("\r\n")
      unless params[:record_route].nil?
        viarr += "\r\n" + (params[:record_route].map{ |r| "Record-Route: #{r}" }).join("\r\n")
      end
      self.sd.send(sprintf(SIP_CANCEL_OK_FMT, viarr, params[:from], params[:to], params[:call_id], params[:cseq]), 0, chost, cport)
    end
  
    def serveSIPRequest(data, sender)
      request = data.split("\r\n")

      case request[0]
      when /\AINVITE (sip:.+) SIP\/2.0\Z/
        # SIP INVITE
        uri = $1
        # TODO: validate URI
        params = parseINVITERequestHeader(request[1..-1])
        unless params.nil?
          if params[:from] =~ /\A[^0-9]+([0-9]+)\@.+\Z/ or params[:from] =~ /<[^0-9]+([0-9]+)\@.+>/
            from = $1
            if params[:to] =~ /\A[^0-9]+([0-9]+)\@.+\Z/
              to = $1
              @logger.info("Incoming call from #{from} to #{to}")
              process_new_req = true
              @serving_m.synchronize {
                if @serving_h["#{sender[3]}#{from}"] == true
                  process_new_req = false
                  @logger.info "Ignoring call from #{from}: already serving!"
                else
                  @serving_h["#{sender[3]}#{from}"] = true
                end
              }
              if process_new_req
                begin
                  if validPhoneNumbers?( :from => from, :to => to )
                    @logger.info("Processing incoming call from #{from} to #{to}")
                    cbThread = Thread.new { callback( :from => from, :to => to ) }
                    sendSIPBusyReply(params, sender)
                    cbThread.join
                  else
                    @logger.info("Ignoring incoming call from #{from} to #{to}")
                    sendSIPBusyReply(params, sender)
                  end
                ensure
                  @serving_m.synchronize {
                    @serving_h["#{sender[3]}#{from}"] = nil
                  }
                end 
              end
            end
          end
        end
      when /\ACANCEL (sip:.+) SIP\/2.0\Z/
        # SIP CANCEL
        uri = $1
        params = parseCANCELRequestHeader(request[1..-1])
        unless params.nil?
          sendSIPCancelOk(params, sender)
        end
      end
    end

end

