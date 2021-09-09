module MiqAeEngine
  class StateVarHash < HashWithIndifferentAccess
    STATE_VAR_NAME_CLASSES = [NilClass, Numeric, String, Symbol, Date, Time].freeze
    SERIALIZE_KEY = 'binary_blob_id'.freeze

    def []=(name, value)
      validate_state_var_name!(name)

      super
    end

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

        $miq_ae_logger.info("Reloading state var data: ")
        VMDBLogger.log_hashes($miq_ae_logger, blob_hash, :filter => Vmdb::Settings.secret_filter)
        update(blob_hash)
      else
        $miq_ae_logger.warn("Failed to load BinaryBlob with ID [#{coder[SERIALIZE_KEY]}] for #{self.class.name}")
      end

      self
    end

    private

    def validate_state_var_name!(name)
      if STATE_VAR_NAME_CLASSES.none? { |klass| name.kind_of?(klass) }
        raise "State Var key (#{name.class.name})[#{name.inspect}] must be of type: #{STATE_VAR_NAME_CLASSES.join(', ')}"
      end
    end
  end
end
