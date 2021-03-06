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

  context 'defining instance methods' do
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

    context 'defining a method with positional arguments' do
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

    context 'defining a method with multiple acceptable types' do
      before :each do
        klass.class_eval do
          define :log, message: [String, Symbol] do
            "hello #{message}"
          end
        end
      end

      it { should respond_to :log }
      it 'should work for different types' do
        expect(instance.log(:world)).to eql('hello world')
        expect(instance.log('world')).to eql('hello world')
      end
    end

    context 'defining a method with default arguments' do
      before :each do
        klass.class_eval do
          define :log, message: String, level: default(:debug, Symbol) do
            [message, level].map(&:to_s).join(' ')
          end
        end
      end

      it { should respond_to :log }
      it 'a default call should use the arguments to create a result' do
        expect(instance.log('hello')).to eql('hello debug')
      end

      it 'should be callable multiple times in a row' do
        3.times do
          expect(instance.log('hello')).to eql('hello debug')
        end
      end
    end

    context 'defining a recursing method' do
      before :each do
        klass.class_eval do
          define :log, message: [String, Array] do
            if message.is_a? Array
              next message.map { |m| self.log(m) }
            end
            "hello #{message}"
          end
        end
      end

      it { should respond_to :log }

      it 'should generate the right recursive behavior' do
        expect(instance.log(['tom', 'jerry'])).to eql(['hello tom',
                                                       'hello jerry'])
      end
    end

    context 'defining a method which accepts a block' do
      before :each do
        klass.class_eval do
          define :log, message: String, block: Proc do
            block.call
            'hello proc'
          end
        end
      end

      it { should respond_to :log }

      it 'should return and yield the right thing' do
        called = false
        result = nil
        result = instance.log('hello') do
          called = true
        end
        expect(result).to eql('hello proc')
        expect(called).to be_truthy
      end
    end

    context 'defining a future method' do
      before :each do
        klass.class_eval do
          future :log, message: String do
            message
          end
        end
      end

      it { should respond_to :log }

      context 'the method result' do
        let(:msg) { 'hello' }
        subject(:result) { instance.log(msg) }

        it { should be_kind_of Concurrent::Future }

        it 'should successfully execute' do
          expect(result.value).to eql msg
          expect(result.state).to eql(:fulfilled), "Failure: #{result.reason}"
        end
      end

      context 'with the wrong parameter types' do
        it 'should raise immediately' do
          expect {
            instance.log(:failboat)
          }.to raise_error(Typedeaf::InvalidTypeException)
        end
      end
    end

    context 'defining a promise method' do
      before :each do
        klass.class_eval do
          promise :log, message: String do
            message
          end
        end
      end

      it { should respond_to :log }

      context 'the method result' do
        let(:msg) { 'hello' }
        subject(:result) { instance.log(msg) }

        it { should be_kind_of Concurrent::Promise }

        it 'should successfully execute' do
          expect(result.value).to eql msg
          expect(result.state).to eql(:fulfilled), "Failure: #{result.reason}"
        end
      end
    end
  end


  context 'defining class methods' do
    context 'using class_define' do
      before :each do
        klass.class_eval do
          class_define :log do
            'hello rspec'
          end
        end
      end

      it { should respond_to :log }
      it 'should return the right value' do
        expect(klass.log).to eql 'hello rspec'
      end
    end

    context 'using class_future' do
      before :each do
        klass.class_eval do
          class_future :log do
            'hello rspec'
          end
        end
      end

      it { should respond_to :log }
    end

    context 'using class_promise' do
      before :each do
        klass.class_eval do
          class_promise :log do
            'hello rspec'
          end
        end
      end

      it { should respond_to :log }
    end
  end
end
