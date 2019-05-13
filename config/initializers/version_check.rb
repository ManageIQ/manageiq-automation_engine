rh_domain = MiqAeDomain.find_by(:name => "RedHat")
if rh_domain.version != rh_domain.available_version
  $log.warn "Current version - #{rh_domain.version}, Available version - #{rh_domain.available_version}"
end
