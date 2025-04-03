describe ManageIQ::AutomationEngine::Logger do
  let(:io) { StringIO.new }
  subject do
    described_class.create_log_wrapper(io).tap do |logger|
      logger.level = Logger::DEBUG
    end
  end

  %w[debug info warn error fatal].each do |sev|
    describe "##{sev}" do
      let(:sev_uc) { sev.upcase }

      it "with a resource_id" do
        subject.public_send(sev, "foo", :resource_id => 123)

        expect(io.string).to match(/#{sev_uc}.*foo/)

        expect(RequestLog.count).to eq(1)
        log = RequestLog.first
        expect(log.message).to     eq("foo")
        expect(log.severity).to    eq(sev_uc)
        expect(log.resource_id).to eq(123)
      end

      it "with a resource_id and a block" do
        subject.public_send(sev, :resource_id => 123) { "foo" }

        expect(io.string).to match(/#{sev_uc}.*foo/)

        expect(RequestLog.count).to eq(1)
        log = RequestLog.first
        expect(log.message).to     eq("foo")
        expect(log.severity).to    eq(sev_uc)
        expect(log.resource_id).to eq(123)
      end

      it "without a resource_id" do
        subject.public_send(sev, "foo")

        expect(io.string).to match(/#{sev_uc}.*foo/)
        expect(RequestLog.count).to eq(0)
      end

      it "without a resource_id and with a block" do
        subject.public_send(sev) { "foo" }

        expect(io.string).to match(/#{sev_uc}.*foo/)
        expect(RequestLog.count).to eq(0)
      end
    end
  end

  describe "#debug" do
    context "when the level doesn't include DEBUG" do
      before { subject.level = Logger::INFO }

      it "with a resource_id" do
        subject.debug("foo", :resource_id => 123)

        expect(RequestLog.count).to eq(0)
      end

      it "without a resource_id" do
        subject.debug("foo")

        expect(io.string).to eq("")
        expect(RequestLog.count).to eq(0)
      end
    end
  end

  describe "supports container logging" do
    subject { described_class.create_log_wrapper }
    let(:log_wrapper) { subject.log_wrapper }
    let(:container_log) do
      if log_wrapper.respond_to?(:broadcasts)
        log_wrapper.broadcasts.last
      else
        log_wrapper.wrapped_logger
      end
    end

    before do
      stub_const("ENV", ENV.to_h.merge("CONTAINER" => "true"))

      # Hide the container logger output to STDOUT
      allow(container_log.logdev).to receive(:write)
    end

    it "with a resource_id" do
      expect(subject.logdev).to be_nil # i.e. won't write to a file
      expect(subject).to       receive(:add).with(Logger::INFO, "foo", "automation").and_call_original
      expect(container_log).to receive(:add).with(Logger::INFO, "foo", "automation").and_call_original

      subject.info("foo", :resource_id => 123)

      expect(RequestLog.count).to eq(1)
      log = RequestLog.first
      expect(log.message).to     eq("foo")
      expect(log.severity).to    eq("INFO")
      expect(log.resource_id).to eq(123)
    end

    it "with a resource_id and a block" do
      expect(subject.logdev).to be_nil # i.e. won't write to a file
      expect(subject).to       receive(:add).with(Logger::INFO, "foo", "automation").and_call_original
      expect(container_log).to receive(:add).with(Logger::INFO, "foo", "automation").and_call_original

      subject.info(:resource_id => 123) { "foo" }

      expect(RequestLog.count).to eq(1)
      log = RequestLog.first
      expect(log.message).to     eq("foo")
      expect(log.severity).to    eq("INFO")
      expect(log.resource_id).to eq(123)
    end

    it "without a resource_id" do
      expect(subject.logdev).to be_nil # i.e. won't write to a file
      expect(subject).to       receive(:add).with(Logger::INFO, nil, "foo").and_call_original
      expect(container_log).to receive(:add).with(Logger::INFO, nil, "foo").and_call_original

      subject.info("foo")

      expect(RequestLog.count).to eq(0)
    end

    it "without a resource_id and with a block" do
      expect(subject.logdev).to be_nil # i.e. won't write to a file
      expect(subject).to receive(:add).with(Logger::INFO, nil, nil).and_call_original
      expect(container_log).to receive(:add).with(Logger::INFO, nil, nil).and_call_original
      expect(container_log.logdev).to receive(:write).with(/"message":"foo"/)

      subject.info { "foo" }

      expect(RequestLog.count).to eq(0)
    end
  end
end
