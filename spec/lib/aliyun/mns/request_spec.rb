require 'spec_helper'

describe AliMns::Request do
  
  describe "Reqest methods" do
    specify "get" do
      expect(RestClient).to receive(:get) do |*args|
        path, headers = *args
        expect(path).to eq("http://owner-id.mns-region.aliyuncs.com/path")
        expect(headers).to be_a(Hash)
      end

      AliMns::Request.get("/path")
    end

    specify "get with params" do
      expect(RestClient).to receive(:get) do |*args|
        path, headers = *args
        expect(path).to eq("http://owner-id.mns-region.aliyuncs.com/path?a=1")
        expect(headers).to be_a(Hash)
      end
      
      AliMns::Request.get("/path", params:{a:1})
    end

    specify "get with mns_headers" do
      expect(RestClient).to receive(:get) do |*args|
        path, headers = *args
        expect(path).to eq("http://owner-id.mns-region.aliyuncs.com/path")
        expect(headers.slice("x-mns-1")).to eq("x-mns-1"=>"1")
      end
      
      AliMns::Request.get("/path", mns_headers:{"x-mns-1"=>"1"})
    end
   
    specify "delete" do
      expect(RestClient).to receive(:delete) do |*args|
        path, headers = *args
        expect(path).to eq("http://owner-id.mns-region.aliyuncs.com/path")
        expect(headers).to be_a(Hash)
      end

      AliMns::Request.delete("/path")
    end

    specify "post with content" do
      expect(RestClient).to receive(:post) do |*args|
        path, body, headers = *args
        expect(path).to eq("http://owner-id.mns-region.aliyuncs.com/path")
        expect(body).not_to be_empty
        expect(headers).to be_a(Hash)
      end

      AliMns::Request.post("/path"){|request| request.content "content"}
    end

    specify "put with content" do
      expect(RestClient).to receive(:put) do |*args|
        path, body, headers = *args
        expect(path).to eq("http://owner-id.mns-region.aliyuncs.com/path")
        expect(body).not_to be_empty
        expect(headers).to be_a(Hash)
      end
      
      AliMns::Request.put("/path"){|request| request.content "content"}
    end
  end

  specify "has default x-mns-version header" do
    expect(subject.mns_headers).to eq("x-mns-version" => "2014-07-08")
  end

  specify "has default content namespace when content is set" do
    subject.content("content", attr1: 1, attr2: 2)
    xml = Hash.AliMns(subject.body)

    expect(subject.content_type).to eq("text/xml;charset=utf-8")
    expect(xml["content"]["xmlns"]).to eq("http://mns.aliyuncs.com/doc/v1/")
    expect(subject.content_length).not_to be_nil
    expect(subject.content_md5).not_to be_nil
  end

end
