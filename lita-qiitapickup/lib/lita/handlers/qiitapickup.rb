# coding: utf-8

module Lita
  module Handlers
    class Qiitapickup < Handler
      config :qiita_access_token, type: String, required: true

      TARGET_TAGS = %w(Ruby Rails)
      
      route /start pickupqiita/, :start_pickup, help: {
                      "start pickupqiita" => "qiitaから注目記事をピックアップします"
                    }

      def start_pickup(response)
        pickup(response)
        
        every(60 * 60) do |timer|
          # FIXME: ストップするためのコマンドも欲しい。
          # timer.stop if some_condition
          pickup(response)
        end
      end
      def pickup(response)
        recent_items.each do |item|
          id = item[:id]
          old_stock_count = redis.get(id) || 0
          current_stock_count = get_stock_count(id)

          message = pickup_judge(old_stock_count.to_i, current_stock_count)

          if message
            send_message(response, message)
            send_item(response, url: item[:url], title: item[:title], stock_count: current_stock_count)
          end
          
          redis.set(id, current_stock_count)
        end
      end

      private

      def send_message(response, message)
        target = response.message.source
        robot.send_message(target, message)
      end

      def send_item(response, url: , title: , stock_count:)
        room = response.message.source.room
        room = Lita::Room.new(room) if room.is_a?(String)
        target = room || response.message.source.user

        text = "#{stock_count}ストック！\n「<#{url}|#{title}>」"

        attachment = Adapters::Slack::Attachment.new(text)
        robot.chat_service.send_attachment(target, attachment)
      end

      def pickup_judge(old_stock_count, current_stock_count)
        if old_stock_count < 100 && current_stock_count >= 100
          '100ストックを超えたみんなマストリードなRuby記事があるよ！要要要チェック！'
        elsif old_stock_count < 50 && current_stock_count >= 50
          '50ストック以上されたトレンディーなRuby記事があるよ！要要チェック！'
        elsif old_stock_count < 10 && current_stock_count >= 10
          '10ストック以上されたRubyの記事が有るよ！要チェック！'
        else
          nil
        end
      end

      def recent_items
        TARGET_TAGS.map do |tag|
          client.list_tag_items(tag, {page: 1, per_page: 100})
            .body
            .map{ |i| {id: i['id'], title: i['title'], url: i['url'] } }
        end.flatten
      end

      # 指定したitemのストック数を返す。100を超える場合は100を返す。それ以上は数えない。
      def get_stock_count(item_id)
        client.list_item_stockers(item_id, {page: 1, per_page: 100}).body.count
      end

      def client
        @client ||= Qiita::Client.new(access_token: config.qiita_access_token)
      end

      Lita.register_handler(self)
    end
  end
end
