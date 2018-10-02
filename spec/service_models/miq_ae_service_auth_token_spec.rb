describe MiqAeMethodService::MiqAeServiceAuthToken do
  it "#auth_key" do
    expect(described_class.instance_methods).to include(:auth_key)
  end
end
