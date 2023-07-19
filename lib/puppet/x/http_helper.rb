require 'net/https'
require 'ipaddr'
require 'json'
require 'puppet'

module Puppet::X # rubocop:disable Style/ClassAndModuleChildren
  # Helper class for HTTP calls
  class HTTPHelper
    def initialize(username: nil,
                   password: nil,
                   auth_token: nil,
                   ssl_verify: OpenSSL::SSL::VERIFY_NONE,
                   redirect_limit: 10,
                   is_jamf_cloud: false,
                   jamf_cookie: nil,
                   headers: {})
      @username = username
      @password = password
      @auth_token = auth_token
      @ssl_verify = ssl_verify
      @redirect_limit = redirect_limit
      @is_jamf_cloud = is_jamf_cloud
      @jamf_cookie = jamf_cookie
      @headers = headers
    end

    def execute(method, url, body: nil, headers: {}, redirect_limit: @redirect_limit, form: nil)
      raise ArgumentError, 'HTTP redirect too deep' if redirect_limit.zero?

      Puppet.debug("http_helper - execute - method = #{method}")
      Puppet.debug("http_helper - execute - url = #{url}")

      # setup our HTTP class
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = @ssl_verify

      # create our request
      req = net_http_request_class(method).new(uri)
      if @username && @password
        req.basic_auth(@username, @password)
      elsif @auth_token
        headers['Authorization'] = "Bearer #{@auth_token}"
      end

      # NOTE: we must use a cookie in the header of every request made to
      #       cloud servers since they are clustered and we were running
      #       into refresh issues because subsequent calls are dependent upon
      #       earlier ones.
      if @is_jamf_cloud
        headers['Cookie'] = @jamf_cookie
      end

      # copy headers into the request
      headers.each { |k, v| req[k] = v }

      # set the body in the request
      if body
        case body
        when Array, Hash then
          req.content_type = 'application/json'
          req.body = body.to_json
        else
          req.body = body
        end
        Puppet.debug("http_helper - execute - body = #{req.body}")
      elsif form
        enctype = headers['Content-Type'] || headers['content-type'] || 'application/x-www-form-urlencoded'
        req.set_form(form, enctype)
        Puppet.debug("http_helper - execute - setting form data - body = #{req.body}")
      end

      # execute
      Puppet.debug("http_helper - execute - executing request=#{req}\n  body=#{req.body}")
      resp = http.request(req)
      Puppet.debug("http_helper - execute - received response=#{resp}\n  body=#{resp.body}")

      # check response for success, redirect or error
      case resp
      when Net::HTTPSuccess then
        resp
      when Net::HTTPRedirection then
        execute(method, resp['location'],
                body: body, headers: headers,
                redirect_limit: redirect_limit - 1)
      else
        Puppet.debug("throwing HTTP error: request_method=#{method} request_url=#{url} request_body=#{body} response_http_code=#{resp.code} resp_message=#{resp.message} resp_body=#{resp.body}")
        stack_trace = caller.join("\n")
        Puppet.debug("Raising exception: #{resp.error_type.name}")
        Puppet.debug("stack trace: #{stack_trace}")
        message = 'code=' + resp.code
        message += ' message=' + resp.message
        message += ' body=' + resp.body
        raise resp.error_type.new(message, resp)
      end
    end

    def net_http_request_class(method)
      Net::HTTP.const_get(method.capitalize, false)
    end

    def ip?(str)
      IPAddr.new(str)
      true
    rescue
      false
    end

    def get(url, body: nil, headers: @headers)
      execute('get', url, body: body, headers: headers, redirect_limit: @redirect_limit)
    end

    def post(url, body: nil, headers: @headers, form: nil)
      execute('post', url, body: body, headers: headers, redirect_limit: @redirect_limit, form: form)
    end

    def put(url, body: nil, headers: @headers)
      execute('put', url, body: body, headers: headers, redirect_limit: @redirect_limit)
    end

    def delete(url, body: nil, headers: @headers)
      execute('delete', url, body: body, headers: headers, redirect_limit: @redirect_limit)
    end
  end
end
