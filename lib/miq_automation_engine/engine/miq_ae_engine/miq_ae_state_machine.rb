module MiqAeEngine
  module MiqAeStateMachine

    STATE_METHOD_REGEX = Regexp.new(/^METHOD::(.*$)/i)
    def state_runnable?(field)
      return false unless @workspace.root['ae_state'] == field['name']
      return false unless @workspace.root['ae_result'] == 'ok'

      true
    end

    def initialize_state_maxima_metadata(field)
      @workspace.root['ae_state_started'] = Time.zone.now.utc.to_s  if @workspace.root['ae_state_started'].blank?
      @workspace.root['ae_state_retries'] = 0                  if @workspace.root['ae_state_retries'].blank?
      @workspace.root['ae_state_max_retries'] = field['max_retries'].to_i
    end

    def reset_state_maxima_metadata
      @workspace.root['ae_state_started'] = ''
      @workspace.root['ae_state_retries'] = 0
      @workspace.root['ae_state_max_retries'] = 0
    end

    def increment_state_retries
      @workspace.root['ae_state_retries'] = @workspace.root['ae_state_retries'].to_i + 1
    end

    def enforce_state_maxima(field)
      enforce_max_retries(field)
      enforce_max_time(field)
    end

    def enforce_max_retries(field)
      return if field['max_retries'].blank?

      return if field['max_retries'].to_i >= @workspace.root['ae_state_retries'].to_i

      raise "number of retries <#{@workspace.root['ae_state_retries']}> exceeded maximum of <#{field['max_retries']}>"
    end

    def enforce_max_time(field)
      return if field['max_time'].blank?

      lapsed = Time.zone.now.utc - Time.zone.parse(@workspace.root['ae_state_started'])
      return if field['max_time'].to_i_with_method > lapsed

      raise "time in state <#{lapsed} seconds> exceeded maximum of <#{field['max_time']}>"
    end

    def process_state_step_with_error_handling(field, step = nil)
      current_state = @workspace.root['ae_state']
      yield
      if @workspace.root['ae_next_state'].present? && current_state != @workspace.root['ae_next_state']
        $miq_ae_logger.warn("Skipping to state #{@workspace.root['ae_next_state']}")
        @workspace.root['ae_result'] = 'skip' if step == 'on_entry'
      end
    rescue MiqAeException::StopInstantiation => e
      $miq_ae_logger.error("State=<#{field['name']}> running #{step} raised exception: <#{e.message}>")
      raise
    rescue StandardError => e
      error_message = "State=<#{field['name']}> running #{step} raised exception: <#{e.message}>"
      $miq_ae_logger.error(error_message)
      @workspace.root['ae_reason'] = error_message
      @workspace.root['ae_result'] = 'error'
    end

    def process_state(field, message, args)
      Benchmark.current_realtime[:state_count] += 1
      Benchmark.realtime_block(:state_time) do
        # Initialize the ae_state and ae_result variables, if blank
        @workspace.root['ae_state']  = field['name'] if @workspace.root['ae_state'].blank?
        @workspace.root['ae_result'] = 'ok'      if @workspace.root['ae_result'].blank?
        @workspace.root['ae_next_state'] = ''
        @workspace.root['ae_retry_server_affinity'] = false

        # Do not proceed further unless this state is runnable
        return unless state_runnable?(field)

        # Ensure the metadata to deal with retries and timeouts is initialized
        initialize_state_maxima_metadata(field)

        # Process on_entry method
        process_state_step_with_error_handling(field, 'on_entry') { process_state_method(field, 'on_entry') }

        # Re-verify (in case on-entry method changed anything)
        process_state_step_with_error_handling(field) { process_state_relationship(field, message, args) } if state_runnable?(field)

        # Check the ae_result and set the next state appropriately
        if @workspace.root['ae_result'] == 'ok'
          $miq_ae_logger.info("Processed State=[#{field['name']}]")
        elsif @workspace.root['ae_result'] == 'skip'
          $miq_ae_logger.warn("Skipping State=[#{field['name']}]")
          return set_next_state(field, message)
        elsif %w[retry restart async_launch].include?(@workspace.root['ae_result'])
          increment_state_retries
        elsif @workspace.root['ae_result'] == 'error'
          $miq_ae_logger.warn("Error in State=[#{field['name']}]")
          # Process on_error method

          return process_state_step_with_error_handling(field, 'on_error') do
            process_state_method(field, 'on_error')
            if @workspace.root['ae_result'] == 'continue'
              $miq_ae_logger.warn("Resetting Error in State=[#{field['name']}]")
              @workspace.root['ae_result'] = 'ok'
              set_next_state(field, message)
            end
          end
        end

        state_in_retry = @workspace.root['ae_result'] == 'retry'
        # Process on_exit method if not async_launch
        if @workspace.root['ae_result'] == 'async_launch'
          @workspace.root['ae_result'] = 'retry'
        else
          process_state_step_with_error_handling(field, 'on_exit') do
            process_state_method(field, 'on_exit')
            if @workspace.root['ae_result'] == 'retry' && !state_in_retry
              increment_state_retries
            end
          end
        end
        set_next_state(field, message)
      end
    end

    def process_state_relationship(field, message, args)
      relationship = get_value(field, :aetype_relationship)
      unless relationship.blank? || relationship.lstrip[0, 1] == '#'
        $miq_ae_logger.info("Processing State=[#{field['name']}]")
        @workspace.root['ae_state_step'] = 'main'
        enforce_state_maxima(field)
        match_data = STATE_METHOD_REGEX.match(relationship)
        if match_data
          process_method_raw(match_data[1])
        else
          process_relationship_raw(relationship, message, args, field['name'], field['collect'])
          raise MiqAeException::MiqAeDatastoreError, "empty relationship" unless @rels[field['name']]
        end
        $miq_ae_logger.info("Processed State=[#{field['name']}] with Result=[#{@workspace.root['ae_result']}]")
      end
    end

    def process_state_method(field, method_name)
      return if field[method_name].blank?

      field[method_name].split(";").each do |method|
        method = substitute_value(method.strip)
        next if method.blank? || method.lstrip[0, 1] == '#'

        $miq_ae_logger.info("In State=[#{field['name']}], invoking [#{method_name}] method=[#{method}]")
        @workspace.root['ae_status_state'] = method_name
        @workspace.root['ae_state']        = field['name']
        @workspace.root['ae_state_step'] = method_name
        process_method_raw(method)
      end
    rescue MiqAeException::MethodNotFound => err
      raise MiqAeException::MethodNotFound, "In State=[#{field['name']}], #{method_name} #{err.message}"
    end

    def next_state(current, message)
      state_name = @workspace.root['ae_next_state'].presence || current
      states = fields(message).collect { |f| f['name'] if f['aetype'] == 'state' }.compact
      validate_state(states)
      index = states.index(state_name)
      return nil if index.nil?

      @workspace.root['ae_next_state'].blank? ? states[index + 1] : states[index]
    end

    def set_next_state(field, message)
      if %w[skip ok].include?(@workspace.root['ae_result'])
        @workspace.root['ae_state'] = next_state(field['name'], message).to_s
        reset_state_maxima_metadata
        $miq_ae_logger.info("Next State=[#{@workspace.root['ae_state']}]")
        @workspace.root['ae_result'] = 'ok'
      elsif @workspace.root['ae_result'] == 'restart'
        $miq_ae_logger.info("State=[#{field['name']}] has requested a restart")
        @workspace.root['ae_result'] = 'retry'
        @workspace.root['ae_state'] = restart_state(message).to_s
        $miq_ae_logger.info("Will restart at State=[#{@workspace.root['ae_state']}]")
      end
    end

    def restart_state(message)
      states = fields(message).collect { |f| f['name'] if f['aetype'] == 'state' }.compact
      validate_state(states)
      @workspace.root['ae_next_state'].presence || states[0]
    end

    def validate_state(states)
      next_state = @workspace.root['ae_next_state']
      if next_state.present? && states.exclude?(next_state)
        $miq_ae_logger.error("Next State=#{next_state} is invalid aborting state machine")
        raise MiqAeException::AbortInstantiation, "Invalid state specified <#{next_state}>"
      end
    end
  end
end
