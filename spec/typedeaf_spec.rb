require 'spec_helper'

describe Typedeaf do
  subject(:klass) do
    Class.new do
      include Typedeaf
    end
  end

  context 'with a new class' do
    it { should be_kind_of Class }
    it { should respond_to :define }
  end

  context 'defining typedeaf instance methods' do
    subject(:instance) { klass.new }

    context 'defining a method with an invalid block' do
      it 'should raise a MissingMethodException' do
        expect {
          klass.class_eval do
            define :log
          end
        }.to raise_error(Typedeaf::MissingMethodException)
      end
    end


    context 'defining a method with no arguments' do
      before :each do
        klass.class_eval do
          define :log do
            'hello rspec'
          end
        end
      end

      it { should respond_to :log }

      it 'should return the right value when invoked' do
        expect(instance.log).to eql('hello rspec')
      end
    end


    context 'defining a method with arguments' do
      before :each do
        klass.class_eval do
          define :log, message: String do
            "hello #{message}"
          end
        end
      end

      it { should respond_to :log }
      it 'should use the arguments to generate a result' do
        expect(instance.log('world')).to eql('hello world')
      end

      it 'should raise when not enough args are passed' do
        expect {
          instance.log
        }.to raise_error(ArgumentError)
      end

      it 'should raise when an incorrectly typed argument is passed' do
        expect {
          instance.log 4
        }.to raise_error(Typedeaf::InvalidTypeException)
      end
    end
  end
end
