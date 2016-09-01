WebsocketRails::EventMap.describe do
  subscribe :client_disconnected, to: ChatController, with_method: :client_disconnected
  subscribe :client_connected, to: ChatController, with_method: :client_connected
  subscribe :new_user, to: ChatController, with_method: :new_user

  ## Custom routes
  subscribe :new_message, to: ChatController, with_method: :new_message


  ## Game routes
  subscribe :start_game, to: ChatController, with_method: :start_game
  subscribe :get_question, to: ChatController, with_method: :get_question
  subscribe :final_scores, to: ChatController, with_method: :final_scores

  #subscribe :change_username, to: ChatController, with_method: :change_username

end
