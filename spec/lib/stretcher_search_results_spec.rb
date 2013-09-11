require 'spec_helper'

class CustomResultClass < Hashie::Mash; end

describe Stretcher::SearchResults do
  let(:result) do
    Hashie::Mash.new({
      'raw' => {
        'facets' => [],
        'hits' => {
          'total' => 1,
          'hits'  => [{
            '_score' => 255,
            '_id' => 2,
            '_index' => 'index_name',
            '_type' => 'type_name'
          }]
        }
      }
    })
  end

  context 'merges in select keys' do
    subject(:search_result) { Stretcher::SearchResults.new(result).results.first }
    its(:_score) { should == 255 }
    its(:_id) { should == 2 }
    its(:_index) { should == 'index_name' }
    its(:_type) { should == 'type_name' }
  end

  context 'use custom result class' do
    subject(:search_result) do
      Stretcher::SearchResults.result_class = CustomResultClass
      Stretcher::SearchResults.new(result).results.first
    end
    its(:class) { should == CustomResultClass }
  end
end
