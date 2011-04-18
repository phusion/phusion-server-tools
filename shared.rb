TOOLS_DIR = File.expand_path(File.dirname(__FILE__))
ENV['PATH'] = "#{TOOLS_DIR}:#{ENV['PATH']}"
if ENV['TOOL_LEVEL']
	TOOL_LEVEL = ENV['TOOL_LEVEL'].to_i
else
	TOOL_LEVEL = 0
end

def print_activity(message)
	if TOOL_LEVEL == 0
		puts "# #{message}"
	else
		puts "#{TOOL_LEVEL * '  '}-> #{message}"
	end
end

def sh(command, *args)
	print_activity "# #{command} #{args.join(' ')}"
	quiet_sh(command, *args)
end

def quiet_sh(command, *args)
	ENV['TOOL_LEVEL'] = (TOOL_LEVEL + 1).to_s
	if !system(command, *args)
		abort "*** COMMAND FAILED: #{command} #{args.join(' ')}".strip
	end
ensure
	ENV['TOOL_LEVEL'] = TOOL_LEVEL.to_s
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
	filename = "#{TOOLS_DIR}/config.yml"
	if !File.exist?(filename)
		filename = "/etc/phusion-server-tools.yml"
		if !File.exist?(filename)
			abort "*** ERROR: you must create #{TOOLS_DIR}/config.yml or " +
				"/etc/phusion-server-tools.yml. " +
				"Please see #{TOOLS_DIR}/config.yml.example for an example."
		end
	end
	all_config = YAML.load_file(filename)
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
