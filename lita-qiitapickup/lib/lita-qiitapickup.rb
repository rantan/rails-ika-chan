require "lita"
require "qiita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

ROOM_LIST_KEY = 'rooms'

require "lita/handlers/qiitapickup"

Lita::Handlers::Qiitapickup.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
