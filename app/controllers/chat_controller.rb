class ChatController < WebsocketRails::BaseController
  include QuizHelper
  def initialize_session
    # perform application setup here
    controller_store[:message_count] = 0
  end

  def client_connected
    new_message = {:message => 'this is a client_connected'}
    puts new_message.to_s
    send_message :new_message, new_message
  end

  def client_disconnected
    # keys = $redis.keys "*"
    # $redis.del keys
    #$redis.flushdb

    new_message = {:message => 'this is a client_disconnected'}
    puts new_message.to_s
    send_message :new_message, new_message
  end

  def new_user
    new_message = {:message => 'this is a new_user... ' + controller_store[:message_count].to_s }
    puts new_message.to_s
    send_message :new_message, new_message
  end

  ## Custom event handlers
  def new_message
    #send_message :new_message, message
    #trigger_success {message:"awesome level is sufficient"}
    broadcast_message :new_message, message
  end

  def start_game
    ## message should contain user_name, genre
    new_message, flag = start_game_helper(message)
    #puts "game, new_message: #{new_message}"
    send_message :start_game, new_message
  end

  def get_question
    begin
      start_time = Time.now.to_i
      new_message, flag = get_next_question(message)
      if flag
        #puts "get_question, new_message: #{new_message}"
        broadcast_message :get_question, new_message
      else
        #puts "broadcasting condition failed"
      end
      total_time = Time.now.to_i - start_time
      puts total_time
    rescue Exception => e
      puts e.message
      binding.pry
    end
  end

  def final_scores
    new_message, flag = get_final_scores(message)
    if flag
      puts "final_scores, new_message: #{new_message}"
      broadcast_message :final_scores, new_message
    else
      puts "broadcasting condition failed"
    end

  end

end
