# coding: utf-8
module Lita
  module Handlers
    class Qiitapickup < Handler
      route /pickup qiita/, :pickup, help: {
        "pickup qiita" => "qiitaから注目記事をピックアップします"
      }

      def pickup(response)
        response.reply 'hello'
      end

      Lita.register_handler(self)
    end
  end
end
