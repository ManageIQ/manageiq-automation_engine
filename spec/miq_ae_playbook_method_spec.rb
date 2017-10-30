describe MiqAeEngine::MiqAePlaybookMethod do
  describe "run" do
    let(:user) { FactoryGirl.create(:user_with_group) }
    let(:aw) { FactoryGirl.create(:automate_workspace, :user => user, :tenant => user.current_tenant) }
    let(:root_hash) { { 'name' => 'Flintstone' } }
    let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
    let(:persist_hash) { {} }
    let(:options) { {"test" => 13} }
    let(:method_name) { "Freddy Kreuger" }
    let(:method_key) { "FreddyKreuger_ansible_method_task_id" }
    let(:miq_task) { FactoryGirl.create(:miq_task) }
    let(:manager)  { FactoryGirl.create(:embedded_automation_manager_ansible) }
    let(:playbook) { FactoryGirl.create(:embedded_playbook, :manager => manager) }

    let(:workspace) do
      double("MiqAeEngine::MiqAeWorkspaceRuntime", :root               => root_object,
                                                   :persist_state_hash => persist_hash,
                                                   :ae_user            => user,
                                                   :hash_workspace     => {},
                                                   :current_namespace  => "Bedrock",
                                                   :current_class      => "Mogul",
                                                   :current_instance   => "Fred",
                                                   :current_message    => "Yabba Dabba",
                                                   :current_method     => "Dino")
    end

    let(:user) do
      FactoryGirl.create(:user_with_group, :userid   => "admin",
                                           :settings => {:display => { :timezone => "UTC"}})
    end

    let(:aem)    { double("AEM", :options => options, :name => method_name) }
    let(:obj)    { double("OBJ", :workspace => workspace) }
    let(:inputs) { { 'name' => 'Fred' } }

    context "check miq extra vars passed into playbook" do
      before do
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:create).and_return(aw)
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)
        allow(workspace).to receive(:update_workspace)
        allow(described_class::PLAYBOOK_CLASS).to receive(:find).and_return(playbook)
      end

      it "success" do
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_OK, "Done")
        expect(playbook).to receive(:run) do |args|
          expect(args['test']).to eq(13)
          expect(args[:extra_vars][:manageiq]['automate_workspace']).to eq(aw.href_slug)
          miq_task.id
        end

        ap = described_class.new(aem, obj, inputs)
        ap.run

        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "regular method" do
      before do
        allow(described_class::PLAYBOOK_CLASS).to receive(:find).and_return(playbook)
        allow(playbook).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:create).and_return(aw)
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)
        allow(workspace).to receive(:update_workspace)
      end

      it "success" do
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_OK, "Done")

        ap = described_class.new(aem, obj, inputs)
        ap.run

        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "method fails" do
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_ERROR, "Done")

        ap = described_class.new(aem, obj, inputs)
        expect { ap.run }.to raise_exception(MiqAeException::Error)
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "playbook launch fails" do
        expect(playbook).to receive(:run).and_raise("Bamm Bamm Rubble")

        ap = described_class.new(aem, obj, inputs)
        expect { ap.run }.to raise_exception(MiqAeException::Error)
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "state machine" do
      before do
        root_hash['ae_state_started'] = Time.zone.now.utc.to_s
        miq_task.update_status(MiqTask::STATE_ACTIVE, MiqTask::STATUS_OK, "Actively working")
        allow(described_class::PLAYBOOK_CLASS).to receive(:find).and_return(playbook)
        allow(playbook).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:find_by).and_return(aw)
        allow(workspace).to receive(:update_workspace)
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)
      end

      it "sets up retry as a state method" do
        ap = described_class.new(aem, obj, inputs)
        ap.run

        expect(root_object['ae_result']).to eq('retry')
        expect(persist_hash[method_key]).to eq(miq_task.id)
        expect(AutomateWorkspace.find_by(:guid => aw.guid)).not_to be_nil
      end

      it "on subsequent calls" do
        persist_hash[method_key] = miq_task.id
        persist_hash['automate_workspace_guid'] = aw.guid

        ap = described_class.new(aem, obj, inputs)
        ap.run

        expect(root_object['ae_result']).to eq('retry')
        expect(persist_hash[method_key]).to eq(miq_task.id)
        expect(AutomateWorkspace.find_by(:guid => aw.guid)).not_to be_nil
      end

      it "state finishes succesfully" do
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_OK, "Done")
        persist_hash[method_key] = miq_task.id
        persist_hash['automate_workspace_guid'] = aw.guid

        ap = described_class.new(aem, obj, inputs)

        ap.run

        expect(root_object['ae_result']).to eq('ok')
        expect(persist_hash[method_key]).to be_nil
        expect(persist_hash['automate_workspace_guid']).to be_nil
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "state finishes in error" do
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_ERROR, "Done")
        persist_hash[method_key] = miq_task.id
        persist_hash['automate_workspace_guid'] = aw.guid

        ap = described_class.new(aem, obj, inputs)

        expect { ap.run }.to raise_exception(MiqAeException::Error)

        expect(root_object['ae_result']).to eq('error')
        expect(persist_hash[method_key]).to be_nil
        expect(persist_hash['automate_workspace_guid']).to be_nil
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      shared_context "retry_interval" do
        let(:max_retries) { 100 }
        let(:retry_interval) { 1.minute }
      end

      shared_examples_for "check retry interval" do
        it "calculate interval" do
          root_object['ae_state_max_retries'] = max_retries
          ap = described_class.new(aem, obj, inputs)
          ap.run

          expect(root_object['ae_result']).to eq('retry')
          expect(root_object['ae_retry_interval']).to eq(retry_interval)
        end
      end

      context "7.minutes, execution_ttl 700" do
        let(:options) { {:execution_ttl => 700} }
        let(:max_retries) { 100 }
        let(:retry_interval) { 7.minutes }

        it_behaves_like "check retry interval"
      end

      context "default 1.minute, low execution_ttl" do
        include_context "retry_interval"
        let(:options) { {:execution_ttl => 40} }

        it_behaves_like "check retry interval"
      end

      context "default 1.minute, execution_ttl not specified" do
        include_context "retry_interval"
        let(:options) { {} }

        it_behaves_like "check retry interval"
      end

      context "default 1.minute, zero max_retries" do
        let(:max_retries) { 0 }
        let(:options) { {} }
        let(:retry_interval) { 1.minute }

        it_behaves_like "check retry interval"
      end
    end
  end
end
