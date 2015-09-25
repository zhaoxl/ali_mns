require 'active_support'
require 'active_support/core_ext'
require 'rest-client'
require 'nokogiri'
require 'yaml'
require 'ali_mns/version'
require 'rexml/document' 
# RestClient.log=STDOUT

# Monkey patch hash to support xml array and xml object
class Hash
  def self.xml_array content, *path
    o = xml_object(content, *path)
    return (o.is_a?(Array) ? o : [o]).reject{|n| n.empty?}
  end

  def self.xml_object content, *path
    h = from_xml(content)
    path.reduce(h){|memo, node|  memo = memo[node] || {}}
  end
end

module AliMns
  require 'ali_mns/queue'
  require 'ali_mns/batch_message'
  require 'ali_mns/message'
  require 'ali_mns/request'
  require 'ali_mns/cli'

  class << self
    def configuration
      @configuration ||=  begin
        if defined? Rails
          config_file = Rails.root.join("config/aliyun-mns.yml")
        else
          config_file = File.expand_path("~/.aliyun-mns.yml")
        end

        if (File.exist?(config_file))
          config = YAML.load(ERB.new(File.new(config_file).read).result)
          config = config[Rails.env] if defined? Rails
        end
        OpenStruct.new(config || {access_id:"", key:"", region:"", owner_id:""})
      end
    end

    def configure
      yield(configuration)
    end
  end

end


=begin
AliMns::Queue['log-development'].receive_message
AliMns::Queue['log-development'].batch_receive_message
=end