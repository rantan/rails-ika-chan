module Lita
  module Handlers
    class Qiitapickup < Handler
      config :qiita_access_token, type: String, required: true

      TARGET_TAGS = %w(Ruby Rails)
      
      route /qiitapickup install/, :install, help: {
        "@ika: qiitapickup install" => "qiitaから注目記事をピックアップします"}
      route /qiitapickup uninstall/, :uninstall, help: {
        "@ika: qiitapickup uninstall" => "qiitapickuをアンインストールします。"}
      route /qiitapickup status/, :status, help: {
        "@ika: qiitapickup status" => "qiitapickuが有効化確認します"}

      on :loaded, :start

      def install(response)
        room = response.message.source.room
        redis.rpush(ROOM_LIST_KEY, room)

        response.reply 'インストールしたで！'
      end

      def uninstall(response)
        room = response.message.source.room
        redis.lrem(ROOM_LIST_KEY, 0, room)

        response.reply 'アンインストールしたで！'
      end

      def status(response)
        room = response.message.source.room
        if rooms.include?(room)
          response.reply '有効やで！よかったな！'
        else
          response.reply '無効やで！残念やな！'
        end
      end

      def start(payload)
        pickup
        every(30 * 60) do
          pickup
        end
      end

      private

      def pickup
        return if rooms.count == 0

        log.info('start qiita pickup.')
        items = TARGET_TAGS
          .map { |tag| Pickup.new(tag, redis, config, log).execute }
          .flatten
        items.each { |item| send_item(item) }
        log.info("#{items.count} items are picked up.")
        log.info('finish qiita pickup.')
      end

      def rooms
        redis.lrange(ROOM_LIST_KEY, 0, -1)
      end

      def send_item(item)
        options = {
          pretext: item.pretext,
          color: item.color,
          author_name: item.user_id,
          author_link: item.qiita_profile_url,
          author_icon: item.profile_image_url,
          title: item.title,
          title_link: item.url
        }

        attachment = Adapters::Slack::Attachment.new(item.message, options)

        rooms.each do |room|
          room = Lita::Room.new(room)
          robot.chat_service.send_attachment(room, attachment)
        end
      end

      class Item < Struct.new(
        :id,
        :url,
        :title,
        :user_id,
        :profile_image_url,
        :created_at,
        :current_stock_count,
        :old_stock_count)

        def message
          <<~MESSAGE
          #{stock_count_message}
          投稿日時: #{created_at}
          MESSAGE
        end

        def qiita_profile_url
          "https://qiita.com/#{user_id}"
        end

        def pretext
          if current_stock_count >= 100
            '100ストックを超えたみんなマストリードなRuby記事があるよ！要要要チェック！'
          elsif current_stock_count >= 50
            '50ストック以上されたトレンディーなRuby記事があるよ！要要チェック！'
          elsif  current_stock_count >= 10
            '10ストック以上されたRubyの記事が有るよ！要チェック！'
          else
            ''
          end
        end

        def color
          if current_stock_count >= 100
            '#bd3c3a'
          elsif current_stock_count >= 50
            '#bc9d3b'
          else
            '#bababa'
          end
        end

        private

        def stock_count_message
          if current_stock_count > 100
            "#{current_stock_count}ストック突破！！"
          else
            "#{current_stock_count}ストック！"
          end
        end
      end

      class Pickup
        attr_reader :tag, :redis, :config, :log

        def initialize(tag, redis, config, log)
          @tag = tag
          @redis = redis
          @config = config
          @log = log
        end

        def execute
          recent_items.select { |item| pickup?(item) }
        end

        private

        def pickup?(item)
          (item.old_stock_count < 100 && item.current_stock_count >= 100) ||
            (item.old_stock_count < 50 && item.current_stock_count >= 50) ||
            (item.old_stock_count < 10 && item.current_stock_count >= 10)
        end

        def recent_items
          log.debug("GET Qiita List Tag Items API tag = #{@tag}")
          client.list_tag_items(@tag, { page: 1, per_page: 100 })
            .body
            .map do |item|
            old = redis.get(item['id']).to_i || 0
            current = get_stock_count(item['id'])
            redis.set(item['id'], current)
            Item.new(
              item['id'],
              item['url'],
              item['title'],
              item.dig('user', 'id'),
              item.dig('user', 'profile_image_url'),
              item['created_at'],
              current,
              old
            )
          end
        rescue Puma::HttpParserError => e
          log.error("#{e.class}: #{e.message}\n#{e.backtrace}")
        end

        # 指定したitemのストック数を返す。100を超える場合は100を返す。それ以上は数えない。
        def get_stock_count(item_id)
          log.debug("GET Qiita Item Stockers API item_id = #{item_id}")
          count = client.list_item_stockers(item_id, { page: 1, per_page: 100 }).body.count
          log.debug("Stockers Count = #{count}")
          count
        rescue Puma::HttpParserError => e
          log.error("#{e.class}: #{e.message}\n#{e.backtrace}")
        end

        def client
          @client ||= Qiita::Client.new(access_token: config.qiita_access_token)
        end
      end

      Lita.register_handler(self)
    end
  end
end
