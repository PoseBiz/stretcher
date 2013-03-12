require 'spec_helper'

describe Stretcher::IndexType do
  let(:server) { Stretcher::Server.new(ES_URL) }
  let(:index) {
    i = server.index(:foo)
    i
  }
  let(:type) {
    t = index.type(:bar)
    t.delete_query(:match_all => {})
    index.refresh
    mapping = {"bar" => {"properties" => {"message" => {"type" => "string"}}}}
    t.put_mapping mapping
    t
  }

  it "should be existentially aware" do
    t = index.type(:existential)
    t.exists?.should be_false
    mapping = {"existential" => {"properties" => {"message" => {"type" => "string"}}}}
    t.put_mapping mapping
    t.exists?.should be_true
    t.get_mapping.should == mapping
  end

  describe "searching" do
    before do
      @doc = {:message => "hello"}
      type.put(123123, @doc)
      index.refresh
    end

    it "should search and find the right doc" do
      res = type.search(:query => {:match => {:message => @doc[:message]}})
      res.results.first.message.should == @doc[:message]
    end

    it "should build results when _source is not included in loaded fields" do
      res = type.search(query: {match_all: {}}, fields: ['message'])
      res.results.first.message.should == @doc[:message]
    end

    it "should build results when no document fields are selected" do
      res = type.search(query: {match_all: {}}, fields: ['_id'])
      res.results.first.should have_key '_id'
    end

    it "should add _highlight field to resulting documents when present" do
      res = type.search(:query => {:match => {:message => 'hello'}}, :highlight => {:fields => {:message => {}}})
      res.results.first.message.should == @doc[:message]
      res.results.first.should have_key '_highlight'
    end
  end

  describe "put/get/delete/explain" do
    before do
      @doc = {:message => "hello!"}
      @put_res = type.put(987, @doc)
    end

    it "should put correctly" do
      @put_res.should_not be_nil
    end

    it "should post correctly" do
      type.post(@doc).should_not be_nil
    end

    it "should get individual documents correctly" do
      type.get(987).message.should == @doc[:message]
    end

    it "should return nil when retrieving non-extant docs" do
      lambda {
        type.get(898323329)
      }.should raise_exception(Stretcher::RequestError::NotFound)
    end

    it "should get individual raw documents correctly" do
      res = type.get(987, true)
      res["_id"].should == "987"
      res["_source"].message.should == @doc[:message]
    end

    it "should explain a query" do
      type.exists?(987).should be_true
      index.refresh
      res = type.explain(987, {:query => {:match_all => {}}})
      res.should have_key('explanation')
    end

    it "should update individual docs correctly" do
      type.update(987, :script => "ctx._source.message = 'Updated!'")
      type.get(987).message.should == 'Updated!'
    end

    it "should delete by query correctly" do
      type.delete_query("match_all" => {})
      index.refresh
      type.exists?(987).should be_false
    end

    it "should delete individual docs correctly" do
      type.exists?(987).should be_true
      type.delete(987)
      type.exists?(987).should be_false
    end
  end
end
