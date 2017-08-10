module MiqAeServiceCloudSubnetSpec
  describe MiqAeMethodService::MiqAeServiceCloudSubnet do
    it "#cloud_network" do
      expect(described_class.instance_methods).to include(:cloud_network)
    end

    it "#availability_zone" do
      expect(described_class.instance_methods).to include(:availability_zone)
    end

    it "#vms" do
      expect(described_class.instance_methods).to include(:vms)
    end

    it "#update_cloud_subnet" do
      expect(described_class.instance_methods).to include(:update_cloud_subnet)
    end

    it "#delete_cloud_subnet" do
      expect(described_class.instance_methods).to include(:delete_cloud_subnet)
    end
  end
end
