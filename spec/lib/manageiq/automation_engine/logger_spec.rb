describe ManageIQ::AutomationEngine::Logger do
  let(:io) { StringIO.new }
  subject { described_class.new(io) }

  describe "#info" do
    it "with a resource_id" do
      subject.info("foo", :resource_id => 123)

      expect(io.string).to match(/INFO.*foo/)

      expect(RequestLog.count).to eq(1)
      log = RequestLog.first
      expect(log.message).to     eq("foo")
      expect(log.severity).to    eq("INFO")
      expect(log.resource_id).to eq(123)
    end

    it "without a resource_id" do
      subject.info("foo")

      expect(io.string).to match(/INFO.*foo/)
      expect(RequestLog.count).to eq(0)
    end
  end

  describe "#error" do
    it "with a resource_id" do
      subject.error("foo", :resource_id => 123)

      expect(io.string).to match(/ERROR.*foo/)

      expect(RequestLog.count).to eq(1)
      log = RequestLog.first
      expect(log.message).to     eq("foo")
      expect(log.severity).to    eq("ERROR")
      expect(log.resource_id).to eq(123)
    end

    it "without a resource_id" do
      subject.error("foo")

      expect(io.string).to match(/ERROR.*foo/)
      expect(RequestLog.count).to eq(0)
    end
  end

  describe "#warn" do
    it "with a resource_id" do
      subject.warn("foo", :resource_id => 123)

      expect(io.string).to match(/WARN.*foo/)

      expect(RequestLog.count).to eq(1)
      log = RequestLog.first
      expect(log.message).to     eq("foo")
      expect(log.severity).to    eq("WARN")
      expect(log.resource_id).to eq(123)
    end

    it "without a resource_id" do
      subject.warn("foo")

      expect(io.string).to match(/WARN.*foo/)
      expect(RequestLog.count).to eq(0)
    end
  end

  describe "#fatal" do
    it "with a resource_id" do
      subject.fatal("foo", :resource_id => 123)

      expect(io.string).to match(/FATAL.*foo/)

      expect(RequestLog.count).to eq(1)
      log = RequestLog.first
      expect(log.message).to     eq("foo")
      expect(log.severity).to    eq("FATAL")
      expect(log.resource_id).to eq(123)
    end

    it "without a resource_id" do
      subject.fatal("foo")

      expect(io.string).to match(/FATAL.*foo/)
      expect(RequestLog.count).to eq(0)
    end
  end

  describe "#debug" do
    context "when the level doesn't include DEBUG" do
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

    context "when the level includes DEBUG" do
      before { subject.level = Logger::DEBUG }

      it "with a resource_id" do
        subject.debug("foo", :resource_id => 123)

        expect(RequestLog.count).to eq(1)
        log = RequestLog.first
        expect(log.message).to     eq("foo")
        expect(log.severity).to    eq("DEBUG")
        expect(log.resource_id).to eq(123)
      end

      it "without a resource_id" do
        subject.debug("foo")

        expect(io.string).to match(/DEBUG.*foo/)
        expect(RequestLog.count).to eq(0)
      end
    end
  end
end
