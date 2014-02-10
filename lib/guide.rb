### Terminal Twitter ###
#
#  Gives you the ability to access a twitter account
#  via the terminal command line
#

require 'twitters'

class Guide

  class Config
    @@actions = ['tweet','add', 'drain', 'view','clear','quit']
    def self.actions; @@actions; end
  end

  def initialize (path = nil)
    Twitters.filepath = path
    if Twitters.file_usable?
      puts "Found Tweet queue."
    elsif Twitters.create_file
      puts "Created Tweet queue."
    else
      puts "Exiting.\n\n"
      exit
    end
  end
  
  def launch!
    introduction
    verify
    result = nil
    until result == :quit
      action= get_action
      result = do_action(action)
    end
    conclusion
  end

  def verify
    verified = Twitters.user_verified?
    if verified
      puts "User Verified\n\n".center(60)
    else
      puts "User not verified . . ."
      puts "Ending session"
      exit
    end
  end

  def get_action
    action = nil
    until Guide::Config.actions.include?(action)
      puts "Actions: " + Guide::Config.actions.join(", ") if action
      print "> "
      user_response = gets.chomp.downcase.strip
      action = user_response
    end
    return action
  end
  
  def do_action(action)
    case action
    when 'tweet'
      tweet
    when 'add'
      add
    when 'drain'
      drain
    when 'view'
      view
    when 'clear'
      clear
    when 'quit'
      return :quit
    else
      puts "\nI don't understand that command.\n"
    end
  end
  
  def tweet
    output_action_header("Enter the user status")
    Twitters.tweet
  end

  def add
    output_action_header("Enter the user status")
    twitters = Twitters.add_to_queue
    if twitters.save
      puts "\nTweet Added to Queue\n\n"
    else
      puts "\nSave Error: Tweet Failed to add to queue\n\n"
    end
  end
  
  def drain
    puts "Draining Queue..."
    Twitters.drain_queue
  end
  
  def view
    twitters = Twitters.saved_twitters
    output_tweet_queue(twitters)
  end
  
  def clear
    twitters = Twitters.clear_queue
    puts "\nStatus Queue Cleared\n\n"
  end
  
  def introduction
    puts "\n\n"
    puts "<<<< Welcome to Twitter Terminal >>>>".center(60)
    puts "This is a way to send tweets on behalf of an account.".center(60)
    puts "-"*60
    puts "Tweet - Update Status Immediately".center(60)
    puts "Add - Add Update Status to Queue".center(60)
    puts "Drain - Begin Queue Drain".center(60)
    puts "View - Views the Current Tweet Queue".center(60)
    puts "Clear - Clear all existing tweets in the Queue\n\n".center(60)
  end
  
  def conclusion
    puts "\n\n"
    puts "<<<< Happy Tweets >>>>".center(60)
    puts "\n\n"
  end
  
  def output_action_header(text)
    puts "\n#{text.upcase.center(60)}\n\n"
  end

  def output_tweet_queue(twitters = [])
    print "\n\n " + "Tweet".ljust(50)
    print " " + "Wait".rjust(6) +"\n"
    puts "-" * 60
    twitters.each do |twit|
      line = " " << twit.status.ljust(50)
      line << " " + twit.wait.rjust(6)
      #status = twit.status
      #while status.length > 50
      #  count = 0
      #  line = " " << status[0..50].ljust(50)
      #  status = status[50..-1]
      #  if twitters[0]==twit
      #    line << " " + twit.wait.rjust(6)
      #  end
      #end
      puts line
      #count +=1
    end
    puts "No tweets in queue" if twitters.empty?
    puts "-" * 60
  end

end