# coding: utf-8
Lita.configure do |config|
  # The name your robot will use.
  config.robot.name = "@ika"

  # The locale code for the language to use.
  config.robot.locale = :ja

  # The severity of messages to log. Options are:
  # :debug, :info, :warn, :error, :fatal
  # Messages at the selected level and above will be logged.
  config.robot.log_level = :info

  # An array of user IDs that are considered administrators. These users
  # the ability to add and remove other users from authorization groups.
  # What is considered a user ID will change depending on which adapter you use.
  config.robot.admins = ["rantan"]

  config.robot.adapter = :slack
  config.adapters.slack.token = ENV['SLACK_TOKEN']


  # Example: Set options for the Redis connection.
  config.redis.host = ENV['REDIS_HOST']
  config.redis.port = ENV['REDIS_PORT']

  # 雑談bot(powerd by docomo)
  config.handlers.talk.docomo_api_key = ENV['DOCOMO_API_KEY']
  # optional (https://dev.smt.docomo.ne.jp/?p=docs.api.page&api_name=dialogue&p_name=api_1#tag01)
  #  20 : 関西弁キャラ
  #  30 : 赤ちゃんキャラ
  #  指定なし : デフォルトキャラ
  # config.handlers.talk.docomo_character_id = 20
  # config.handlers.talk.docomo_character_id = [nil, 20, 30] # at random in array

  config.handlers.qiitapickup.qiita_access_token = ENV['QIITA_ACCESS_TOKEN']

  ## Example: Set configuration for any loaded handlers. See the handler's
  ## documentation for options.
  # config.handlers.some_handler.some_config_key = "value"
end
