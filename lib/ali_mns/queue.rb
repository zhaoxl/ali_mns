module AliMns
  class Queue
    attr_reader :name

    delegate :to_s, to: :name

    class << self
      def [] name
        Queue.new(name)
      end

      def queues opts={}
        mns_options = {query: "x-mns-prefix", offset: "x-mns-marker", size: "x-mns-ret-number"}
        mns_headers = opts.slice(*mns_options.keys).reduce({}){|mns_headers, item| k, v = *item; mns_headers.merge!(mns_options[k]=>v)}
        response = Request.get("/", mns_headers: mns_headers)
        Hash.xml_array(response, "Queues", "Queue").collect{|item| Queue.new(URI(item["QueueURL"]).path.sub!(/^\//, ""))}
      end
    end

    def initialize name
      @name = name
    end

    def create opts={}
      response = Request.put(queue_path) do |request|
        msg_options = {
          :VisibilityTimeout => 30,
          :DelaySeconds => 0,
          :MaximumMessageSize => 65536,
          :MessageRetentionPeriod => 345600,
          :PollingWaitSeconds => 0}.merge(opts)
        request.content :Queue, msg_options
      end
    end

    def delete
      Request.delete(queue_path)
    end

    def send_message message, opts={}
      Request.post(messages_path) do |request|
        msg_options = {:DelaySeconds => 0, :Priority => 10}.merge(opts)
        request.content :Message, msg_options.merge(:MessageBody => message.to_s)
      end
    end

    def receive_message wait_seconds: nil
      request_opts = {}
      request_opts.merge!(params:{waitseconds: wait_seconds}) if wait_seconds
      return nil unless result = Request.get(messages_path, request_opts)
      Message.new(self, result)
    end
    
    # 批量获取消息
    # 本接口用于消费者批量消费队列的消息，一次BatchReceiveMessage操作最多可以获取16条消息。该操作会将取得的消息状态变成Inactive，Inactive的时间长度由Queue属性VisibilityTimeout指定（详见CreateQueue接口）。 消费者在VisibilityTimeout时间内消费成功后需要调用DeleteMessage接口删除取得的消息，否则取得的消息将会被重新置为Active，又可被消费者重新消费。
    def batch_receive_message limit: 16, wait_seconds: nil
      request_opts = {params:{numOfMessages: limit}}
      request_opts[:params].merge!({waitseconds: wait_seconds}) if wait_seconds
      
      return [] unless result = Request.get(messages_path, request_opts)
      BatchMessage.new(self, result)
    end

    def peek_message
      result = Request.get(messages_path, params: {peekonly: true})
      Message.new(self, result)
    end

    def queue_path
      "/#{name}"
    end

    def messages_path
      "/queues/#{name}/messages"
    end

  end
end
