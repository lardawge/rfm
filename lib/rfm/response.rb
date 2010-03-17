module Rfm
  module Response
    
    def self.options
      @options ||= Rfm.options
    end
    
    def self.http(params, path='/fmi/xml/fmresultset.xml', limit=10)
      raise CommunicationError, "While trying to reach the Web Publishing Engine, RFM was redirected too many times." if limit == 0
      
      request = Net::HTTP::Post.new(path)
      request.basic_auth(options[:account_name], options[:password])
      request.set_form_data(params)
      
      http = Net::HTTP.new(options[:host], options[:ssl] && options[:port] == 80 ? 443 : options[:port])

      set_ssl(http)
      
      response = http.start { |http| http.request(request) }
      logging(params, path, response)
      process_response(response)
      response.body
    end
    
    def self.set_ssl(http)
      if options[:ssl]
        http.use_ssl = true
        if options[:pem]
          if File.exists?(options[:pem])
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.ca_file = options[:pem]
          else
            raise PemFileMissingError, "You have specified a pem file but it appears to be missing. " +
            "If you do not want to use SSL Verify set :pem => false"
          end
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
    end
    
    def self.process_response(response)
      case response
      when Net::HTTPSuccess; response
      when Net::HTTPRedirection
        if options[:warn_on_redirect]
          warn "The web server redirected to " + response['location'] + 
          ". You should revise your connection hostname or fix your server configuration if possible to improve performance."
        end
        newloc = URI.parse(response['location'])
        http(newloc.host, newloc.port, newloc.request_uri, params, limit - 1) #TODO Fix me
      when Net::HTTPUnauthorized
        msg = "The account name (#{options[:account_name]}) or password provided is not correct (or the account doesn't have the fmxml extended privilege)."
        raise AuthenticationError, msg
      when Net::HTTPNotFound
        msg = "Could not talk to FileMaker because the Web Publishing Engine is not responding (server returned 404)."
        raise CommunicationError, msg
      else
        msg = "Unexpected response from server: #{response.code} (#{response.class.to_s}). Unable to communicate with the Web Publishing Engine."
        raise CommunicationError, msg
      end
    end
    
    def self.logging(data, path, response)
      if options[:log_actions]
        query = data.collect { |k,v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}" }.join("&")
        warn "#{options[:ssl] ? "https" : "http"}://#{options[:host]}:#{options[:port]}#{path}?#{query}"
      end
      
      if options[:log_responses]
        response.to_hash.each { |k,v| warn "#{k}: #{v}" }
        warn response.body
      end
    end

  end
end