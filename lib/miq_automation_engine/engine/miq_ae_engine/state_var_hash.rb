module MiqAeEngine
  class StateVarHash < HashWithIndifferentAccess
    SERIALIZE_KEY = 'binary_blob_id'.freeze

    def encode_with(coder)
      coder[SERIALIZE_KEY] =
        blank? ? 0 : BinaryBlob.new.tap { |bb| bb.store_data("YAML", to_h) }.id
    end

    def init_with(coder)
      return if coder[SERIALIZE_KEY].zero?

      binary_blob = BinaryBlob.find_by(:id => coder[SERIALIZE_KEY])
      if binary_blob
        blob_hash = binary_blob.data
        binary_blob.destroy

        $miq_ae_logger.info("Reloading state var data: #{blob_hash.to_yaml}")
        update(blob_hash)
      else
        $miq_ae_logger.warn("Failed to load BinaryBlob with ID [#{coder[SERIALIZE_KEY]}] for #{self.class.name}")
      end

      self
    end
  end
end
