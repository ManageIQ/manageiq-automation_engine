describe MiqAePassword do
  let(:plaintext) { "Pl$1nTeXt" }

  describe ".to_s" do
    subject { described_class.new(plaintext) }

    it "is hidden to_s" do
      expect(subject.to_s).to eq("********")
    end
  end

  it "produces a key decryptable by ManageIQ::Password" do
    expect(ManageIQ::Password.decrypt(described_class.encrypt(plaintext))).to eq(plaintext)
  end

  describe ".decrypt" do
    it "reads password encrypted by ManageIQ::Password" do
      expect(described_class.decrypt(ManageIQ::Password.encrypt(plaintext))).to eq(plaintext)
    end

    it "throws understandable error" do
      expect { described_class.decrypt("v1:{something}") }.to raise_error(ManageIQ::Password::PasswordError)
    end
  end

  describe ".decrypt_if_password" do
    context "with encrypted password" do
      subject { described_class.new(plaintext) }
      it "decrypts" do
        expect(MiqAePassword.decrypt_if_password(subject)).to eq(plaintext)
      end
    end

    context "with plaintext password" do
      subject { "string" }
      it "decrypts" do
        expect(MiqAePassword.decrypt_if_password(subject)).to eq(subject)
      end
    end
  end

  describe ".key_root" do
    it "has key_root set" do
      expect(MiqAePassword.key_root).to be_truthy
    end
  end
end
