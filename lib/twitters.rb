require 'yaml'
require 'oauth'
require 'json'

class Twitters
  
    @@filepath = nil
    @@user_config = {}
    
    attr_accessor :status, :wait
    
    def self.filepath=(path=nil)
      @@filepath = File.join(APP_ROOT, path)
    end
    
    def self.setup_config
      configuration = YAML.load_file("lib/config.yml")
      @@user_config[:base_url] = configuration["url"]
      @@user_config[:consumer_key] = OAuth::Consumer.new(configuration["consumer_key"], configuration["consumer_secret"])
      @@user_config[:access_token] = OAuth::Token.new(configuration["access_token"], configuration["access_token_secret"])
    end

    def self.file_exists?
      # class should know if the file exists
      if @@filepath && File.exists?(@@filepath)
        return true
      else
        return false
      end
    end

    def self.file_usable?
      return false unless @@filepath
      return false unless File.exists?(@@filepath)
      return false unless File.readable?(@@filepath)
      return false unless File.writable?(@@filepath)
      return true
    end

    def self.create_file
      File.open(@@filepath, 'w') unless file_exists?
      return file_usable?
    end

    def self.saved_twitters
      twitters = []
      if file_usable?
        file = File.new(@@filepath, 'r')
        file.each_line do |line|
          twitters << Twitters.new.import_line(line.chomp)
        end
        file.close
      end
      return twitters
    end

    def initialize(args={})
      @status   = args[:status]   || ""
      @wait     = args[:wait]     || ""
    end

    def import_line(line)
      line_array = line.split("\t")
      @status,@wait = line_array
      return self
    end

    def self.add_to_queue
      args = {}
      print "Status: "
      args[:status] = gets.chomp.strip

      print "Wait in Minutes: "
      args[:wait] = gets.chomp.strip
      
      return self.new(args)
    end

    def save
      return false unless Twitters.file_usable?
      File.open(@@filepath, 'a') do |file|
        file.puts "#{[@status, @wait].join("\t")}\n"
      end
      return true
    end

    def self.user_verified?
      setup_config
      address = URI("#{@@user_config[:base_url]}/1.1/account/verify_credentials.json")
      http = Net::HTTP.new address.host, address.port
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      request = Net::HTTP::Get.new address.request_uri
      request.oauth! http, @@user_config[:consumer_key], @@user_config[:access_token]

      http.start
      response = http.request request
      if response.code == '200'
        return true
      else
        return false
      end
    end
    
    def self.tweet(status = nil)
      if status == nil
        print "Status: "
        status = gets.chomp.strip
      end
      address = URI("#{@@user_config[:base_url]}/1.1/statuses/update.json")
      request          = Net::HTTP::Post.new address.request_uri
      http             = Net::HTTP.new address.host, address.port
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      request.set_form_data("status" => status)
      request.oauth! http, @@user_config[:consumer_key], @@user_config[:access_token]
      http.start
      response = http.request request
      time = Time.now
      time = time.strftime("%H:%M:%S")
      if response.code == '200' then
        update = JSON.parse(response.body)
        puts "#{time} Tweet successfully sent: #{update["text"]}"
      else
        errors = JSON.parse(response.body)
        puts "#{time} Tweet Failed - Code: #{response.code}  Message: #{errors["errors"][0]["message"]}"
      end
    end
    
    def self.drain_queue
      if file_usable?        
        file = File.open(@@filepath, 'r')
        file.each_line do |line|
          next_line = Twitters.new.import_line(line.chomp)
          wait(next_line.wait) if next_line.wait.to_i > 0
          tweet(next_line.status)
        end
        file.close
        clear_queue
      end
    end
    
    def self.wait(minutes)
      msg_interval = 10 #seconds
      interval = minutes.to_i*(60/msg_interval)
      for i in 0...interval
        puts "There are #{(interval-i)*msg_interval}s left before the next tweet"
        sleep(msg_interval)
      end
    end
    
    def self.clear_queue
      File.truncate(@@filepath, 0)
    end
    
  end