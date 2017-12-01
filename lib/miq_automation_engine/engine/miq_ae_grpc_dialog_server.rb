require 'grpc'
require 'dialog_field_services_pb'

class MiqAeGrpcDialogServer < Manageiq::Dialog::AutomateDialog::Service
  def get_dialog_field_date_control(input, _unused_call)
    attributes = call_automate(input).root.attributes
    result =  Manageiq::Dialog::DialogFieldDateControlResult.new
    result.show_past_dates = attributes[:show_past_dates] || false
    result.read_only       = attributes[:read_only]       || false
    result.visible         = attributes[:visible]         || true
    result.value           = attributes[:value]           || ""
    result
  end

  def get_dialog_field_date_time_control(input, _unused_call)
    attributes = call_automate(input).root.attributes
    result = Manageiq::Dialog::DialogFieldDateTimeControlResult.new
    result.show_past_dates = attributes[:show_past_dates] || false
    result.read_only       = attributes[:read_only]       || false
    result.visible         = attributes[:visible]         || true
    result.value           = attributes[:value]           || ""
    result
  end

  def get_dialog_field_sorted_item(input, _unused_call)
    attributes = call_automate(input).root.attributes
    values_map = Google::Protobuf::Map.new(:int64, :string)
    attributes['values'].each { |k, v| values_map[k] = v }
    result = Manageiq::Dialog::DialogFieldSortedItemResult.new
    result.sort_by       = attributes[:sort_by] || 'description'
    result.data_type     = attributes[:data_type] || 'string'
    result.required      = attributes[:required]  || false
    result.sort_order    = attributes[:sort_order] || 'ascending'
    result.values        = values_map
    result.default_value = ""
    result
  end

  def get_dialog_field_text_area_box(input, _unused_call)
    puts "Method called #{input.to_h}"
    attributes = call_automate(input).root.attributes
    result = Manageiq::Dialog::DialogFieldTextAreaBoxResult.new
    result.required        = attributes[:required]  || false
    result.read_only       = attributes[:read_only] || false
    result.visible         = attributes[:visible]   || true
    result.value           = attributes[:value]     || ""
    result
  end

  def get_dialog_field_text_box(input, _unused_call)
    attributes = call_automate(input).root.attributes
    result = Manageiq::Dialog::DialogFieldTextBoxResult.new
    result.data_type       = attributes[:data_type] || 'string'
    result.protected       = attributes[:protected] || false
    result.required        = attributes[:required]  || false
    result.validator_rule  = attributes[:validator_rule] || ""
    result.validator_type  = attributes[:validator_type] || ""
    result.read_only       = attributes[:read_only] || false
    result.visible         = attributes[:visible]   || true
    result.value           = attributes[:value]     || ""
    result
  end

  def get_dialog_field_check_box(input, _unused_call)
    attributes = call_automate(input).root.attributes
    result = Manageiq::Dialog::DialogFieldCheckBoxResult.new
    result.required        = attributes[:required]  || true
    result.read_only       = attributes[:read_only] || false
    result.visible         = attributes[:visible]   || true
    result.value           = attributes[:value]     || ""
    result
  end

  def call_automate(input_map)
    MiqAeEngine.deliver(input_map.to_h)
  end

  def self.start_grpc_server
    s = GRPC::RpcServer.new
    s.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
    s.handle(self)
    s.run_till_terminated
  end
end
