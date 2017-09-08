module MiqAeEngine
  class MiqAePlaybookMethod
    include ApplicationController::Filter::SubstMixin
    def initialize(aem, obj, inputs)
      @workspace = obj.workspace
      @inputs    = inputs
      @aem       = aem
      @aw = AutomateWorkspace.create(:input  => serialize_workspace(inputs),
                                     :user   => @workspace.ae_user,
                                     :tenant => @workspace.ae_user.current_tenant)
      @runner_options = build_options_hash(aem, @aw.guid)
    end

    def manageiq_env
      {
        'api_token'  => Api::UserTokenService.new.generate_token(@workspace.ae_user.userid, 'api'),
        'api_url'    => MiqRegion.my_region.remote_ws_url,
        'guid'       => @aw.guid,
        'MIQ_SCRIPT' => @contents,
        'miq_group'  => @workspace.ae_user.current_group.description
      }
    end

    def run
      $miq_ae_logger.info("Playbook Method passing options to runner: #{@runner_options}")
      begin
        result = ManageIQ::Providers::EmbeddedAutomationManager::ConfigurationScriptPayload.run(@runner_options)
      rescue => err
        $miq_ae_logger.error("Playbook Method Ended with error #{err.message}")
        raise MiqAeException::AbortInstantiation, err.message
      end

      $miq_ae_logger.error("Playbook Method Ended with success #{result}")
      @aw.reload
      @workspace.update_workspace(@aw.output)
    end

    private

    def serialize_workspace(inputs)
      {'workspace'         => @workspace.hash_workspace,
       'method_parameters' => MiqAeReference.encode(inputs),
       'current'           => current_info(@workspace),
       'state_vars'        => MiqAeReference.encode(@workspace.persist_state_hash)}
    end

    def current_info(workspace)
      list = %w(namespace class instance message method)
      list.each.with_object({}) { |m, hash| hash[m] = workspace.send("current_#{m}".to_sym) }
    end

    def build_options_hash(aem, guid)
      config_info = YAML.load(aem.data)
      config_info[:extra_vars] = MiqAeReference.encode(@inputs)
      config_info[:extra_vars][:manageiq] = manageiq_env
      { :name => aem.name, :config_info => config_info }
    end
  end
end
