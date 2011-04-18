TOOLS_DIR = File.expand_path(File.dirname(__FILE__))
ENV['PATH'] = "#{TOOLS_DIR}:#{ENV['PATH']}"

def sh(command, *args)
	puts "# #{command} #{args.join(' ')}"
	quiet_sh(command, *args)
end

def quiet_sh(command, *args)
	if !system(command, *args)
		abort "*** COMMAND FAILED: #{command} #{args.join(' ')}".strip
	end
end

# Check whether the specified command is in $PATH, and return its
# absolute filename. Returns nil if the command is not found.
#
# This function exists because system('which') doesn't always behave
# correctly, for some weird reason.
def find_command(name)
	name = name.to_s
	ENV['PATH'].to_s.split(File::PATH_SEPARATOR).detect do |directory|
		path = File.join(directory, name)
		if File.file?(path) && File.executable?(path)
			return path
		end
	end
	return nil
end

# Returns "pv" if that command is installed, or "cat" if not.
# "pv" is the Pipe Viewer tool, very useful for displaying
# progress bars in pipe operations (apt-get install pv).
def pv_or_cat
	if find_command('pv')
		return 'pv'
	else
		return 'cat'
	end
end

def load_config
	require 'yaml'
	if !File.exist?("#{TOOLS_DIR}/config.yml")
		abort "*** ERROR: you must create a #{TOOLS_DIR}/config.yml. " +
			"Please see #{TOOLS_DIR}/config.yml.example for an example."
	end
	all_config = YAML.load_file("#{TOOLS_DIR}/config.yml")
	$TOOL_CONFIG = all_config[File.basename($0)]
end

def config(name)
	load_config if !$TOOL_CONFIG
	value = $TOOL_CONFIG[name.to_s]
	if !value
		abort "*** ERROR: configuration option #{File.basename($0)}.#{name} not set."
	end
	return value
end
