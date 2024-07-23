Facter.add(:jamf_version) do
  File.open( "/usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/version.xml" ).each do |line|
    if line.include?('webApplicationVersion')
      setcode do
        "#{line}".slice!(/>(.*)-/, 1)
      end
    end
  end
end
