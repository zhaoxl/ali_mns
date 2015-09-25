module AliMns
  class BatchMessage

    attr_reader :queue, :messages
    delegate :[], to: :messages
    delegate :each, to: :messages

    def initialize queue, content
      @queue = queue
      @messages = []
      #先用Nokogiri转换成xml对象 再循环创建消息对象
      xml = REXML::Document.new(content)
      xml.elements[1].elements.each do |message_element|
        @messages << Message.new(queue, message_element.to_s)
      end
    end

    def delete_all
      xml = REXML::Document.new
      root_element = REXML::Element.new("ReceiptHandles")
      root_element.add_namespace("xmlns", "http://mns.aliyuncs.com/doc/v1/")          
      @messages.each do |message|
        message_element = REXML::Element.new("ReceiptHandle")
        message_element.text = message.receipt_handle
        root_element.add_element(message_element)
      end
      xml.add_element(root_element)
      
      response = Request.delete(queue.messages_path) do |request|
        request.xml_content xml
      end
    end


  end
end