describe MiqAeMethodService::MiqAeServiceObjectCommon do
  let(:wrapper_class) do
    Class.new do
      include MiqAeMethodService::MiqAeServiceObjectCommon
      def initialize(hash = {})
        @object = Spec::Support::MiqAeMockObject.new(hash)
      end
    end
  end

  let(:test_hash) { {} }
  let(:wrapper) { wrapper_class.new(test_hash) }

  describe "#attributes" do
    context "password fields" do
      let(:test_hash) do
        { 'fred'   => MiqAePassword.new("wilma") }
      end

      it "#attributes" do
        enc_hash = {'fred' => ManageIQ::Password::MASK, 'barney' => 'betty' }

        wrapper['barney'] = 'betty'
        expect(wrapper.attributes).to eq(enc_hash)
      end

      it "#decrypt" do
        expect(wrapper.decrypt('fred')).to eq('wilma')
      end

      it "#[]" do
        expect(wrapper['fred']).to eq(ManageIQ::Password::MASK)
      end

      it "#encrypted?" do
        expect(wrapper.encrypted?('fred')).to be true
      end

      it "#encrypted_string" do
        expect(wrapper.encrypted_string('fred')).to eq(test_hash['fred'].encStr)
      end
    end
  end
end
