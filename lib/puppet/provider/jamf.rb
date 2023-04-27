require File.expand_path(File.join(File.dirname(__FILE__), '..', 'x', 'erb_sandbox'))
require 'cgi'
require 'rexml/document'

# This class is a "base" provider to use to implement your own custom providers
class Puppet::Provider::Jamf < Puppet::Provider
  ##########################
  # public methods inherited from Puppet::Provider

  # defines our getter & setter methods that assign stuff to @property_hash
  # this creates a bunch of methods like:
  #   def full_name
  #     @property_hash[:full_name]
  #   end
  #
  #   def full_name=(value)
  #     @property_hash[:full_name] = value
  #   end
  #
  # This allows us to capture the properties that are changed inside of @property_hash
  # and write all of the changes at one time.
  # If we did not use this, we would have to implement the above getter and setter
  # methods and in each setter write the changed property to the API (not very efficient)
  #
  # @note: sub-classes MUST to call this in their own class, otherwise if we define it here
  # we get an error:
  #  Error: Could not autoload puppet/provider/jamf_activation/api: undefined method `validproperties' for nil:NilClass
  #
  # mk_resource_methods

  # the exists method should return true if the current named resource exists or not
  # in this method we also get the instance of this resource from the API and save
  # it to our @property_hash, this initializes @property_hash and allows it to be
  # used by the mk_resource_methods getter and setters above.
  def exists?
    # use cached_instance here so we can compare before/after in flush() if needed
    @property_hash = cached_instance
    @property_hash[:ensure] == :present
  end

  # this method is called if exists? returns false and :ensure == :present,
  #   so that the resource is created
  # you have two options:
  # 1) implement your "creation" API call here
  # 2) defer the creation to the "flush" method so that "create" and "update" can be
  #    handled in the exact same way
  def create
    @property_hash[:ensure] = :present
  end

  # this method is called if exists? returns false and :ensure == :absent,
  #   so that the resource is deleted
  # 1) implement your "deletion" API call here
  # 2) defer the deletion to the "flush" method so we are consistent with what
  #    we're doing above
  def destroy
    @property_hash[:ensure] = :absent
  end

  # the flush method is called at the end of the "transaction" once all setter methods
  # above have been called along with exists? and potentially create or delete.
  # this method should take all changes that need to happen to this resource and
  # make the necessary API calls to make them happen.
  # In our case we're going to do one "bulk" API call for all of our properties
  # to either create or update the user.
  # If the resource was requested to be destroyed we will delete the resource
  # using the API.
  #
  # This allows us to be super efficiently and basically make one "write" call
  # for each resource instance.
  def flush
    flush_instance

    # Collect the resources again once they've been changed (that way `puppet
    # resource` will show the correct values after changes have been made).
    @property_hash = read_instance
  end

  ##########################
  # private methods
  #
  # You as an implementer need to define 3x methods below
  # - cached_instance : This is just a cache of read_instance, we've provided a default
  #                     implementation so implementers of sub-classes don't have to worry
  # - read_instance : this should return a hash that has the same properties (as symbols)
  #                   and values of what the resource currently looks like
  # - flush_instance : this should read from resource[:xxx] and either create/update or
  #                    delete the instance based on the value of @property_hash[:ensure]
  def cached_instance
    @cached_instance ||= read_instance
  end

  # this method should retrieve an instance and return it as a hash
  # note: we explicitly do NOT cache within this method because we want to be
  #       able to call it both in initialize() and in flush() and return the current
  #       state of the resource from the API each time
  def read_instance
    raise NotImplementedError, 'read_instance needs to be implemented by child providers'
  end

  # this method should check resource[:ensure]
  #  if it is :present this method should create/update the instance using the values
  #  in resource[:xxx] (these are the desired state values)
  #  else if it is :absent this method should delete the instance
  #
  #  if you want to have access to the values before they were changed you can use
  #  cached_instance[:xxx] to compare against (that's why it exists)
  def flush_instance
    raise NotImplementedError, 'flush_instance needs to be implemented by child providers'
  end

  def template_path
    File.expand_path('../../x/templates', __FILE__)
  end

  def render_template(template, variables)
    sandbox = ErbSandbox.new(variables)
    renderer = ERB.new(template)
    renderer.result(sandbox.public_binding)
  end

  def render_template_path(path, variables)
    file = File.new(template_path + path)
    render_template(file.read, variables)
  end

  def hash_to_xml(h, indent: '', path: '')
    res = ''
    h.each do |key_sym, value|
      next if value.nil?
      key = key_sym.to_s
      child_indent = indent + '  '
      full_path = path + key + '.'

      case value
      when Hash
        xml = hash_to_xml(value, indent: child_indent, path: full_path)
        res += if xml.empty?
                 "#{indent}<#{key}>\n#{indent}</#{key}>\n"
               else
                 "#{indent}<#{key}>\n#{xml}\n#{indent}</#{key}>\n"
               end
      when Integer, Float, String, true, false
        res += primitive_to_xml(value, key, indent: indent)
      when Array
        res += array_to_xml(value, key, indent: indent, path: full_path)
      else
        cls = value.class.name
        path_key = path + key
        raise "Unsupported hash_to_xml value type=#{cls} for key=#{path_key} value=#{value}"
      end
    end
    res.rstrip
  end

  def array_to_xml(a, key, indent: '', path: '')
    res = ''
    a.each do |value|
      next if value.nil?
      child_indent = indent + '  '
      full_path = path + key + '.'

      case value
      when Hash
        xml = hash_to_xml(value, indent: child_indent, path: full_path)
        res += "#{indent}<#{key}>\n#{xml}\n#{indent}</#{key}>\n"
      when Integer, Float, String, true, false
        res += primitive_to_xml(value, key, indent: indent)
      when Array
        path_key = path + key
        raise "We currently dont support nested arrays: key=#{path_key} value=#{value}"
      else
        cls = value.class.name
        path_key = path + key
        raise "Unsupported array_to_xml value type=#{cls} for key=#{path_key} value=#{value}"
      end
    end
    res.rstrip
  end

  def primitive_to_xml(value, key, indent: '')
    # replace the following XML special characters
    # "   &quot;
    # '   &apos;
    # <   &lt;
    # >   &gt;
    # &   &amp;
    value_s = CGI.escapeHTML(value.to_s)
    "#{indent}<#{key}>#{value_s}</#{key}>\n"
  end

  def pretty_xml(str)
    doc = REXML::Document.new(str)
    formatter = REXML::Formatters::Pretty.new

    # Compact uses as little whitespace as possible
    formatter.compact = true
    resultstr = ''
    formatter.write(doc, resultstr)
    resultstr
  end
end
