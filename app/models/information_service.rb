require 'openssl'
require 'net/https'

class InformationService

  def initialize(url, username, password)
    @service_url = url
    @username = username
    @password = password
  end

  def register_service(service, host, port)
    send_request("#{service}/register", {address: "#{host}:#{port}"})
  end

  def deregister_service(service, host, port)
    send_request("#{service}/deregister", {address: "#{host}:#{port}"})
  end

  def get_list_of(service)
    send_request("#{service}/list")
  end

  def send_request(request, data = nil)
    @host, @port = @service_url.split(':')
    puts "#{Time.now} --- sending #{request} request to the Information Service at '#{@host}:#{@port}'"

    req = if data.nil?
            Net::HTTP::Get.new('/' + request)
          else
            Net::HTTP::Post.new('/' + request)
          end


    req.basic_auth(@username, @password)
    req.set_form_data(data) unless data.nil?

    ssl_options = { use_ssl: true, ssl_version: :SSLv3, verify_mode: OpenSSL::SSL::VERIFY_NONE }

    begin
      response = Net::HTTP.start(@host, @port, ssl_options) { |http| http.request(req) }
      puts "#{Time.now} --- response from Information Service is #{response.body}"

      return response.body
    rescue Exception => e
      puts "Exception occurred but nothing terrible :) - #{e.message}"
    end

    nil
  end

end
