describe MiqAeMethodService::MiqAeServiceOrchestrationStack do
  let(:stack)           { FactoryBot.create(:orchestration_stack) }
  let(:service_stack)   { MiqAeMethodService::MiqAeServiceOrchestrationStack.find(stack.id) }
  let(:service)         { FactoryBot.create(:service) }
  let(:user)            { FactoryBot.create(:user_with_group) }
  let(:service_service) { MiqAeMethodService::MiqAeServiceService.find(service.id) }

  context "#add_to_service" do
    it "adds a stack to service_resources of a valid service" do
      service_stack.add_to_service(service_service)
      expect(service.service_resources[0].resource_id).to eq(stack.id)
      expect(service.service_resources[0].resource_type).to eq(stack.class.name)
    end

    it "raises an error when adding a stack to an invalid service" do
      expect { service_stack.add_to_service('wrong type') }
        .to raise_error(ArgumentError, /service must be a MiqAeServiceService/)
    end
  end

  context "normalized_live_status" do
    it "gets the live status of the stack and normalizes the status" do
      status = ManageIQ::Providers::Amazon::CloudManager::OrchestrationStack::Status.new('CREATING', nil)
      allow_any_instance_of(OrchestrationStack).to receive(:raw_status) { status }

      expect(service_stack.normalized_live_status).to eq(['transient', "CREATING"])
    end

    it "shows the status as not_exist for non-existing stacks" do
      allow_any_instance_of(OrchestrationStack).to receive(:raw_status) { raise MiqException::MiqOrchestrationStackNotExistError, 'test failure' }

      expect(service_stack.normalized_live_status).to eq(['not_exist', 'test failure'])
    end
  end

  context "refresh" do
    before { stack.update(:ext_management_system => FactoryBot.create(:ext_management_system)) }

    it "calls a refresh on OrchestrationStack object" do
      expect(stack.class).to receive(:refresh_ems).with(stack.ext_management_system.id, stack.ems_ref)
      service_stack.refresh
    end

    it "calls a refresh on OrchestrationStack class" do
      expect(stack.class).to receive(:refresh_ems).with(stack.ext_management_system.id, stack.ems_ref)
      service_stack.class.refresh(stack.ext_management_system.id, stack.ems_ref)
    end
  end

  it "#start_retirement" do
    expect(service_stack.retirement_state).to be_nil
    service_stack.start_retirement

    expect(service_stack.retirement_state).to eq("retiring")
  end

  it "#retire_now" do
    expect(stack.retirement_state).to be_nil
    expect(MiqEvent).to receive(:raise_evm_event).once

    service_stack.retire_now
  end

  it "#extend_retires_on - invalid date" do
    error_msg = "Invalid Date specified: #{Time.zone.today}"
    expect { service_stack.extend_retires_on(7, Time.zone.today) }.to raise_error(RuntimeError, error_msg)
  end

  it "#finish_retirement" do
    expect(service_stack).not_to be_retired
    expect(service_stack.retirement_state).to be_nil
    expect(service_stack.retires_on).to be_nil

    service_stack.finish_retirement

    expect(service_stack.retired).to be_truthy
    expect(service_stack.retires_on).to be_between(Time.zone.now - 1.hour, Time.zone.now + 1.second)
    expect(service_stack.retirement_state).to eq("retired")
  end

  it "#retiring - false" do
    expect(service_stack.retiring?).to be_falsey
  end

  it "#retiring? - true" do
    service_stack.retirement_state = 'retiring'

    expect(service_stack.retiring?).to be_truthy
  end

  it "#error_retiring? - false" do
    expect(service_stack.error_retiring?).to be_falsey
  end

  it "#error_retiring? - true" do
    service_stack.retirement_state = 'error'

    expect(service_stack.error_retiring?).to be_truthy
  end

  context "#retires_on" do
    it "now" do
      stack.update_attributes(:retirement_last_warn => Time.zone.now)
      service_stack.retires_on = Time.zone.now
      stack.reload
      expect(stack.retirement_last_warn).to be_nil
      expect(stack.retirement_due?).to be_truthy
    end

    it "clears all previously set retirement fields when reset" do
      stack.update_attributes(
        :retired              => true,
        :retirement_last_warn => Time.zone.today,
        :retirement_state     => "retiring"
      )
      service_stack.retires_on = Time.zone.now + 1.day
      stack.reload

      expect(stack).to have_attributes(
        :retirement_last_warn => nil,
        :retired              => false,
        :retirement_state     => nil,
        :retirement_due?      => false
      )
    end
  end

  it "#extend_retires_on - no retirement date set" do
    extend_days = 7
    Timecop.freeze(Time.zone.now) do
      service_stack.extend_retires_on(extend_days)
      stack.reload
      new_retires_on = Time.zone.now + extend_days.days
      expect(stack.retires_on.day).to eq(new_retires_on.day)
    end
  end

  it "#extend_retires_on - future retirement date set" do
    Timecop.freeze(Time.zone.now) do
      stack.update_attributes(
        :retired              => true,
        :retirement_last_warn => Time.zone.now,
        :retirement_state     => "retiring"
      )
      future_retires_on = Time.zone.now + 30.days
      service_stack.retires_on = future_retires_on
      extend_days = 7
      service_stack.extend_retires_on(extend_days, future_retires_on)
      stack.reload

      expect(stack).to have_attributes(
        :retirement_last_warn => nil,
        :retired              => false,
        :retirement_state     => nil,
        :retires_on           => a_value_within(1.second).of(future_retires_on + extend_days.days)
      )
    end
  end

  it "#extend_retires_on - invalid date" do
    error_msg = "Invalid Date specified: #{Time.zone.today}"
    expect { service_stack.extend_retires_on(7, Time.zone.today) }.to raise_error(RuntimeError, error_msg)
  end

  it "#retirement_warn" do
    expect(service_stack.retirement_warn).to be_nil
    stack.retirement_last_warn = Time.zone.today
    service_stack.retirement_warn = 60
    stack.reload

    expect(service_stack.retirement_warn).to eq(60)
    expect(stack.retirement_last_warn).to be_nil
  end
end
