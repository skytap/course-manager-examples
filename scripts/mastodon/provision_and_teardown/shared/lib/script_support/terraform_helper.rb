require 'ruby_terraform'
require 'lab_control'
require 'securerandom'
require 'stringio'

RubyTerraform.configure do |config|
  config.binary = "#{ ENV['SCRIPT_UTILS_DIR'] }/terraform"
end   

class TerraformHelper
  def initialize(dir:, env: {}, opts: {}, output_attribute: nil)
    @output_attribute = output_attribute

    @config_opts = {}
    
    if @output_attribute
      @output_stream = StringIO.new
      @config_opts[:stdout] = @output_stream
      @config_opts[:stderr] = @output_stream
    end

    @invocation_uuid = SecureRandom.uuid
    @invocation_dir = "/script_data/#{ @invocation_uuid }"
    @dir = dir
    @lab_control = LabControl.get
    @invocation_options = {
      environment: {
        TF_CLI_CONFIG_FILE: '/script/lib/terraform.tfrc',
        TF_IN_AUTOMATION: true,
        TF_DATA_DIR: @invocation_dir
      }.merge(env)
    }
    
    default_opts = {
      chdir: @dir,
      no_color: true
    }

    @opts = default_opts.merge(opts)

    FileUtils.mkdir_p(@invocation_dir)
  end

  def apply(write_output: false)
    RubyTerraform::Commands::Init.new(**@config_opts).execute(@opts, @invocation_options)
    RubyTerraform::Commands::Apply.new(**@config_opts).execute({**@opts, auto_approve: true}, @invocation_options)
    write_output_to_metadata if write_output
    finalize
  end

  def destroy()
    RubyTerraform::Commands::Init.new(**@config_opts).execute(@opts, @invocation_options)
    RubyTerraform::Commands::Destroy.new(**@config_opts).execute({**@opts, auto_approve: true}, @invocation_options)
    finalize
  end

  private

  def write_output_to_metadata()
    @lab_control.update_control_data({ "metadata" =>
      JSON.parse(
        RubyTerraform.output({
          **@opts,
          json: true
        }, @invocation_options)
      ).each_with_object({}) do |(k, v), metadata| 
        metadata[k] = v['value']
      end
    })
  end

  def finalize
    if @output_attribute
      updated_metadata = {}
      updated_metadata[@output_attribute] = @output_stream.string if @output_attribute
      @lab_control.update_control_data({ "metadata" => updated_metadata })
    end

    FileUtils.remove_entry_secure(@invocation_dir)
  end
end