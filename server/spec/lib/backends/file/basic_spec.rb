require 'spec_helper'

describe Picky::Backends::File::Basic do

  context 'without options' do
    let(:basic) { described_class.new 'some/cache/path/to/file' }

    describe 'empty' do
      it 'returns the container that is used for indexing' do
        basic.empty.should == {}
      end
    end

    describe 'initial' do
      it 'returns the container that is used for indexing' do
        basic.initial.should == nil
      end
    end

    describe 'to_s' do
      it 'returns the cache path with the default file extension' do
        basic.to_s.should == 'Picky::Backends::File::Basic(some/cache/path/to/file.file.index,some/cache/path/to/file.file_mapping.index.memory.json)'
      end
    end
  end

  context 'with options' do
    let(:basic) do
      described_class.new 'some/cache/path/to/file',
                          empty: [],
                          initial: []
    end

    describe 'empty' do
      it 'returns the container that is used for indexing' do
        basic.empty.should == []
      end
    end

    describe 'initial' do
      it 'returns the container that is used for indexing' do
        basic.initial.should == []
      end
    end
  end

end