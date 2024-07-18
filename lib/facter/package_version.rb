Facter.add(:jamf_version) do
  setcode do
    Facter::Core::Execution.execute("/usr/local/jss/bin/jamf-pro --version | head -1 | awk '{ print $2 }'")
  end
end
