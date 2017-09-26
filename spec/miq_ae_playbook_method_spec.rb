describe MiqAeEngine::MiqAePlaybookMethod do
  describe "run" do
    let(:user) { FactoryGirl.create(:user_with_group) }
    let(:aw) { FactoryGirl.create(:automate_workspace, :user => user, :tenant => user.current_tenant) }
    let(:root_hash) { { 'name' => 'Flintstone' } }
    let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
    let(:persist_hash) { {} }
    let(:script) { {"a" => "1"} }
    let(:method_name) { "Freddy Kreuger" }
    let(:method_key) { "FreddyKreuger_ansible_method_task_id" }
    let(:miq_task) { FactoryGirl.create(:miq_task) }

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

    let(:aem)    { double("AEM", :data => script.to_yaml, :name => method_name) }
    let(:obj)    { double("OBJ", :workspace => workspace) }
    let(:inputs) { { 'name' => 'Fred' } }

    context "regular method" do
      it "success" do
        allow(described_class::PLAYBOOK_CLASS).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:create).and_return(aw)
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_OK, "Done")
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)
        allow(workspace).to receive(:update_workspace)

        ap = described_class.new(aem, obj, inputs)
        ap.run

        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "method fails" do
        allow(described_class::PLAYBOOK_CLASS).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:create).and_return(aw)
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_ERROR, "Done")
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)
        allow(workspace).to receive(:update_workspace)

        ap = described_class.new(aem, obj, inputs)
        expect { ap.run }.to raise_exception(MiqAeException::Error)
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "playbook launch fails" do
        allow(described_class::PLAYBOOK_CLASS).to receive(:run).and_raise("Bamm Bamm Rubble")
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:create).and_return(aw)

        ap = described_class.new(aem, obj, inputs)
        expect { ap.run }.to raise_exception(MiqAeException::Error)
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "state machine" do
      it "sets up retry as a state method" do
        root_hash['ae_state_started'] = Time.zone.now.utc.to_s
        allow(described_class::PLAYBOOK_CLASS).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:create).and_return(aw)
        ap = described_class.new(aem, obj, inputs)
        allow(workspace).to receive(:update_workspace)
        miq_task.update_status(MiqTask::STATE_ACTIVE, MiqTask::STATUS_OK, "Actively working")
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)
        ap.run

        expect(root_object['ae_result']).to eq('retry')
        expect(persist_hash[method_key]).to eq(miq_task.id)
        expect(AutomateWorkspace.find_by(:guid => aw.guid)).not_to be_nil
      end

      it "on subsequent calls" do
        root_hash['ae_state_started'] = Time.zone.now.utc.to_s
        persist_hash[method_key] = miq_task.id
        persist_hash['automate_workspace_guid'] = aw.guid

        allow(described_class::PLAYBOOK_CLASS).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:find_by).and_return(aw)
        ap = described_class.new(aem, obj, inputs)
        allow(workspace).to receive(:update_workspace)
        miq_task.update_status(MiqTask::STATE_ACTIVE, MiqTask::STATUS_OK, "Actively working")
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)
        ap.run

        expect(root_object['ae_result']).to eq('retry')
        expect(persist_hash[method_key]).to eq(miq_task.id)
        expect(AutomateWorkspace.find_by(:guid => aw.guid)).not_to be_nil
      end

      it "state finishes succesfully" do
        root_hash['ae_state_started'] = Time.zone.now.utc.to_s
        persist_hash[method_key] = miq_task.id
        persist_hash['automate_workspace_guid'] = aw.guid

        allow(described_class::PLAYBOOK_CLASS).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:find_by).and_return(aw)
        ap = described_class.new(aem, obj, inputs)
        allow(workspace).to receive(:update_workspace)
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_OK, "Done")
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)

        ap.run

        expect(root_object['ae_result']).to eq('ok')
        expect(persist_hash[method_key]).to be_nil
        expect(persist_hash['automate_workspace_guid']).to be_nil
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "state finishes in error" do
        root_hash['ae_state_started'] = Time.zone.now.utc.to_s
        persist_hash[method_key] = miq_task.id
        persist_hash['automate_workspace_guid'] = aw.guid

        allow(described_class::PLAYBOOK_CLASS).to receive(:run).and_return(miq_task.id)
        allow(MiqRegion).to receive(:my_region).and_return(FactoryGirl.create(:miq_region))
        allow(AutomateWorkspace).to receive(:find_by).and_return(aw)
        ap = described_class.new(aem, obj, inputs)
        allow(workspace).to receive(:update_workspace)
        miq_task.update_status(MiqTask::STATE_FINISHED, MiqTask::STATUS_ERROR, "Done")
        allow(MiqTask).to receive(:wait_for_taskid).and_return(miq_task)

        expect { ap.run }.to raise_exception(MiqAeException::Error)

        expect(root_object['ae_result']).to eq('error')
        expect(persist_hash[method_key]).to be_nil
        expect(persist_hash['automate_workspace_guid']).to be_nil
        expect { aw.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end
end
