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
  end
end
