describe MiqAeEngine::MiqAeMethod do
  describe ".invoke_inline_ruby (private)" do
    let(:workspace) do
      Class.new do
        attr_accessor :invoker, :root

        def persist_state_hash
        end

        def disable_rbac
        end

        def current_method
          "/my/automate/method"
        end

        def root
          {}
        end
      end.new
    end

    let(:aem)    { double("AEM", :data => script, :fqname => "/my/automate/method", :embedded_methods => embeds) }
    let(:obj)    { double("OBJ", :workspace => workspace) }
    let(:inputs) { {} }
    let(:embeds) { [] }

    subject { described_class.send(:invoke_inline_ruby, aem, obj, inputs) }

    context "with a script that ends normally" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
        RUBY
      end

      it "logs and returns the correct exit status" do
        allow($miq_ae_logger).to receive(:info).and_call_original
        expect($miq_ae_logger).to receive(:info).with("Method exited with rc=MIQ_OK").at_least(:once)
        expect($miq_ae_logger).to_not receive(:error)

        expect(subject).to eq(0)
      end
    end

    context "with a script that raises" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          raise
        RUBY
      end

      it "logs the error with file and line numbers changed in the stacktrace, and raises an exception" do
        allow($miq_ae_logger).to receive(:error).and_call_original
        expect($miq_ae_logger).to receive(:error).with("Method STDERR: /my/automate/method:2:in `<main>': unhandled exception").at_least(:once)

        expect { subject }.to raise_error(MiqAeException::UnknownMethodRc)
      end
    end

    context "with a script that raises in a nested method" do
      let(:script) do
        <<-RUBY
          def my_method
            raise
          end

          puts 'Hi from puts'
          my_method
        RUBY
      end

      it "logs the error with file and line numbers changed in the stacktrace, and raises an exception" do
        allow($miq_ae_logger).to receive(:error).and_call_original
        expect($miq_ae_logger).to receive(:error).with("Method STDERR: /my/automate/method:2:in `my_method': unhandled exception").at_least(:once)
        expect($miq_ae_logger).to receive(:error).with("Method STDERR: \tfrom /my/automate/method:6:in `<main>'").at_least(:once)

        expect { subject }.to raise_error(MiqAeException::UnknownMethodRc)
      end
    end

    context "with a script that exits" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          exit
        RUBY
      end

      it "logs and returns the correct exit status" do
        allow($miq_ae_logger).to receive(:info).and_call_original
        expect($miq_ae_logger).to receive(:info).with("Method exited with rc=MIQ_OK").at_least(:once)
        expect($miq_ae_logger).to_not receive(:error)

        expect(subject).to eq(0)
      end
    end

    context "with a script that exits with an unknown return code" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          exit 1234
        RUBY
      end

      it "does not log but raises an exception" do
        expect($miq_ae_logger).to_not receive(:error)

        expect { subject }.to raise_error(MiqAeException::UnknownMethodRc)
      end
    end

    context "with a script that exits MIQ_OK" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          exit MIQ_OK
        RUBY
      end

      it "logs and returns the correct exit status" do
        allow($miq_ae_logger).to receive(:info).and_call_original
        expect($miq_ae_logger).to receive(:info).with("Method exited with rc=MIQ_OK").at_least(:once)
        expect($miq_ae_logger).to_not receive(:error)

        expect(subject).to eq(0)
      end
    end

    context "with a script that exits MIQ_WARN" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          exit MIQ_WARN
        RUBY
      end

      it "logs and returns the correct exit status" do
        allow($miq_ae_logger).to receive(:warn).and_call_original
        expect($miq_ae_logger).to receive(:warn).with("Method exited with rc=MIQ_WARN").at_least(:once)
        expect($miq_ae_logger).to_not receive(:error)

        expect(subject).to eq(4)
      end
    end

    context "with a script that exits MIQ_STOP" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          exit MIQ_STOP
        RUBY
      end

      it "does not log but raises an exception" do
        expect($miq_ae_logger).to_not receive(:error)

        expect { subject }.to raise_error(MiqAeException::StopInstantiation)
      end
    end

    context "with a script that exits MIQ_ABORT" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          exit MIQ_ABORT
        RUBY
      end

      it "does not log but raises an exception" do
        expect($miq_ae_logger).to_not receive(:error)

        expect { subject }.to raise_error(MiqAeException::AbortInstantiation)
      end
    end

    context "with a script that does I/O" do
      let(:script) do
        <<-RUBY
          puts 'Hi from puts'
          STDOUT.puts 'Hi from STDOUT.puts'
          $stdout.puts 'Hi from $stdout.puts'
          STDERR.puts 'Hi from STDERR.puts'
          $stderr.puts 'Hi from $stderr.puts'
          $evm.logger.sleep
        RUBY
      end

      it "writes to the logger synchronously" do
        logger_stub = Class.new do
          attr_reader :expected_messages

          def initialize
            @expected_messages = [
              "Method STDOUT: Hi from puts",
              "Method STDOUT: Hi from STDOUT.puts",
              "Method STDOUT: Hi from $stdout.puts",
              "Method STDERR: Hi from STDERR.puts",
              "Method STDERR: Hi from $stderr.puts",
            ]
          end

          def sleep
            # Raise if all messages have not already been written before a method like sleep runs.
            raise unless expected_messages == []
          end

          def verify_next_message(message)
            expected = expected_messages.shift
            return if message == expected
            puts "Expected: #{expected.inspect}, Got: #{message.inspect}"
            raise
          end
          alias_method :error, :verify_next_message
          alias_method :info,  :verify_next_message
        end.new

        svc = MiqAeMethodService::MiqAeService.new(workspace, [], logger_stub)
        expect(MiqAeMethodService::MiqAeService).to receive(:new).with(workspace, inputs).and_return(svc)

        expect($miq_ae_logger).to receive(:info).with("<AEMethod [/my/automate/method]> Starting ").ordered
        expect(logger_stub).to    receive(:sleep).and_call_original.ordered
        expect($miq_ae_logger).to receive(:info).with("<AEMethod [/my/automate/method]> Ending").ordered
        expect($miq_ae_logger).to receive(:info).with("Method exited with rc=MIQ_OK").ordered

        expect(subject).to eq(0)
        expect(logger_stub.expected_messages).to eq([])
      end
    end

    context "with a custom log prefix" do
      let(:script) do
        <<-RUBY
          $evm.set_log_prefix "Flintstones"
          $evm.log(:info, "This is a test message")
          $evm.log(:info, "This is a warning message")
          $evm.log(:error, "This is a error message")
          $evm.log(:info, "The current prefix is \#{$evm.get_log_prefix}")
        RUBY
      end

      it "does not log but raises an exception" do
        expect($miq_ae_logger).to receive(:info).with(/Flintstones This is a test message/)
        expect($miq_ae_logger).to receive(:info).with(/Flintstones This is a warning message/)
        expect($miq_ae_logger).to receive(:error).with(/Flintstones This is a error message/)
        expect($miq_ae_logger).to receive(:info).with(/Flintstones The current prefix is Flintstones/)
        allow($miq_ae_logger).to receive(:info).with("<AEMethod [/my/automate/method]> Starting ")
        allow($miq_ae_logger).to receive(:info).with("<AEMethod [/my/automate/method]> Ending")
        allow($miq_ae_logger).to receive(:info).with("Method exited with rc=MIQ_OK")

        expect(subject).to eq(0)
      end
    end

    context "embed other methods into a method" do
      let(:script) do
        <<-RUBY
          Shared::Methods.new.some_method('barney', "Bamm-Bamm Ruble"); exit MIQ_OK
        RUBY
      end

      let(:shared_script) do
        <<-RUBY
          module Shared
            class Methods
              def initialize(handle = $evm)
                @handle = handle
              end

              def some_method(var, value)
                @handle.log(:info, "Stuff method called \#{var} => \#{value}")
                @handle.log(:info, "Stuff method ended")
              end
            end
          end
        RUBY
      end

      let(:exception_script) do
        <<-RUBY
          module Shared
            class Methods
              def initialize(handle = $evm)
                @handle = handle
              end

              def some_method(var, value)
                raise
              end
            end
          end
        RUBY
      end

      let(:embeds) { ['/Shared/Methods/TopMethod'] }
      let(:klass)    { double("Klass", :id => 10) }
      let(:embed_method) do
        double("Method", :fqname => 'Shared/Methods/TopMethod', :data => shared_script)
      end

      let(:exception_method) do
        double("Method", :fqname => 'Shared/Methods/RaiseException', :data => exception_script)
      end

      it 'can properly call functions in embedded methods' do
        allow(::MiqAeClass).to receive(:find_by_fqname).with('Shared/Methods').and_return(klass)
        allow(::MiqAeMethod).to receive(:find_by).with(:class_id => klass.id, :name => 'TopMethod').and_return(embed_method)
        allow($miq_ae_logger).to receive(:info).and_call_original
        allow(workspace).to receive(:overlay_method).with('Shared', 'Methods', 'TopMethod').and_return('Shared')
        expect($miq_ae_logger).to receive(:info).with("Method exited with rc=MIQ_OK").at_least(:once)
        expect($miq_ae_logger).to_not receive(:error)

        expect(subject).to eq(0)
      end

      it 'raises error when a embeded method is not found' do
        allow(::MiqAeClass).to receive(:find_by_fqname).with('Shared/Methods').and_return(nil)
        allow($miq_ae_logger).to receive(:info).and_call_original
        allow(workspace).to receive(:overlay_method).with('Shared', 'Methods', 'TopMethod').and_return('Shared')

        expect { subject }.to raise_error(MiqAeException::MethodNotFound)
      end

      context "exception" do
        let(:embeds) { ['/Shared/Methods/RaiseException'] }
        it 'can log stack trace in embedded methods' do
          allow(::MiqAeClass).to receive(:find_by_fqname).with('Shared/Methods').and_return(klass)
          allow(::MiqAeMethod).to receive(:find_by).with(:class_id => klass.id, :name => 'RaiseException').and_return(exception_method)
          allow($miq_ae_logger).to receive(:info).and_call_original
          allow($miq_ae_logger).to receive(:error).and_call_original
          allow(workspace).to receive(:overlay_method).with('Shared', 'Methods', 'RaiseException').and_return('Shared')
          expect($miq_ae_logger).to receive(:error).with("<AEMethod /my/automate/method>   Shared/Methods/RaiseException:8:in `some_method'").at_least(:once)
          expect { subject }.to raise_error(MiqAeException::UnknownMethodRc)
        end
      end
    end
  end
end
