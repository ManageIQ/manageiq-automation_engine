describe MiqAeEngine::StateVarHash do
  let!(:start_var_hash) { MiqAeEngine::StateVarHash.new }

  describe 'with an empty hash' do
    let(:blank_yaml_string) { "--- !ruby/object:MiqAeEngine::StateVarHash\nbinary_blob_id: 0\n" }

    it 'should return a blob id of zero' do
      expect(YAML.dump(start_var_hash)).to eq(blank_yaml_string)
    end

    it 'should return an empty hash struct without calling BinaryBlob find' do
      expect(BinaryBlob).to_not receive(:find_by)

      new_start_var_hash = YAML.safe_load(blank_yaml_string, [MiqAeEngine::StateVarHash])

      expect(new_start_var_hash).to be_a(MiqAeEngine::StateVarHash)
      expect(new_start_var_hash).to be_blank
    end
  end

  describe 'with hash entries' do
    let(:state_var_hash) { MiqAeEngine::StateVarHash.new(:x => 1, 'y' => 'two') }

    it 'should create a binary blob entry with YAML.dump' do
      expect(BinaryBlob.count).to be_zero

      matcher = /binary_blob_id: (?<blob_id>\d*)/.match(YAML.dump(state_var_hash))

      expect(BinaryBlob.pluck(:id, :data_type)).to eq([[matcher[:blob_id].to_i, "YAML"]])
    end

    it 'should delete binary_blob when loaded' do
      yaml_out = YAML.dump(state_var_hash)
      expect(BinaryBlob.count).to be(1)

      YAML.safe_load(yaml_out, [MiqAeEngine::StateVarHash])
      expect(BinaryBlob.count).to be_zero
    end

    it 'should create a new copy of the original hash object when reloaded' do
      expect($miq_ae_logger).to receive(:info).with(/Reloading state var data/).and_call_original

      new_start_var_hash = YAML.safe_load(YAML.dump(state_var_hash), [MiqAeEngine::StateVarHash])

      expect(new_start_var_hash).to eq(state_var_hash)
      expect(new_start_var_hash.object_id).to_not eq(start_var_hash.object_id)
    end

    it 'should log a warning and return empty hash if binary_blob instance is not found' do
      yaml_out = YAML.dump(state_var_hash)
      BinaryBlob.destroy_all

      expect($miq_ae_logger).to receive(:warn).with(/Failed to load BinaryBlob with ID/).and_call_original

      restored_state_var = YAML.safe_load(yaml_out, [MiqAeEngine::StateVarHash])
      expect(restored_state_var).to eq({})
    end
  end

  describe 'key names' do
    let(:state_var_hash) { MiqAeEngine::StateVarHash.new }

    [nil, 1, 3.14, 'test', :test, Date.new, Time.zone.now].each do |key|
      it "allows hash key types for [#{key.class}]" do
        state_var_hash[key] = 1
      end
    end

    it 'raises an error for invalid hash key types' do
      expect { state_var_hash[{}] = nil }.to raise_error(RuntimeError, /State Var key \(.*\] must be of type: .*/)
    end
  end
end
