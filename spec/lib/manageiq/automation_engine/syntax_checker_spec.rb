describe ManageIQ::AutomationEngine::SyntaxChecker do
  describe "#check" do
    it "valid" do
      result = described_class.check "this.is.valid.syntax"
      expect(result).to be_valid
      expect(result.errors).to eq([])

      result = described_class.check "i = 1"
      expect(result).to be_valid
    end

    it "invalid" do
      result = described_class.check "this.is -> not -> valid $ruby:syntax"
      expect(result).not_to be_valid
    end
  end

  it "#error_line, #error_text" do
    result = described_class.check "line(1).is.okay\nline(2) is not :("
    expect(result.error_line).to eq(2)
    expect(result.error_text).to match(/syntax error/)
  end

  describe "#errors" do
    it "returns every syntax error, not just the first" do
      result = described_class.check "a = (1 +\nb = 2 2\nc = )\nd = [1,\n"

      expect(result.errors.size).to be > 1
      expect(result.errors.map(&:first)).to include(2, 3, 4)
      expect(result.errors).to all(match([a_kind_of(Integer), a_kind_of(String)]))
    end

    it "does not include warnings" do
      result = described_class.check "a = (1 +\nb = 2 2\n"

      expect(result.errors.map(&:last)).to all(satisfy { |text| text.exclude?("warning:") })
    end

    it "keeps error_line and error_text pointing at the first error" do
      result = described_class.check "a = (1 +\nb = 2 2\nc = )\n"

      expect(result.error_line).to eq(result.errors.first.first)
      expect(result.error_text).to eq(result.errors.first.last)
    end
  end
end
