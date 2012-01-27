TOOLS_DIR = File.expand_path(File.dirname(__FILE__))
ENV['PATH'] = "#{TOOLS_DIR}:#{ENV['PATH']}"
if ENV['TOOL_LEVEL']
	TOOL_LEVEL = ENV['TOOL_LEVEL'].to_i
else
	TOOL_LEVEL = 0
end
ENV['TOOL_LEVEL'] = (TOOL_LEVEL + 1).to_s

def print_activity(message)
	if TOOL_LEVEL == 0
		if STDOUT.tty?
			puts "\e[1m# #{message}\e[22m"
		else
			puts "# #{message}"
		end
	else
		puts "#{'  ' * TOOL_LEVEL}-> #{message}"
	end
end

def sh(command, *args)
	print_activity "#{command} #{args.join(' ')}"
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
	tool_name = File.basename($0)
	filenames = [
		"#{TOOLS_DIR}/config/#{tool_name}.yml",
		"#{TOOLS_DIR}/config/config.yml",
		"#{TOOLS_DIR}/config.yml",
		"/etc/phusion-server-tools/#{tool_name}.yml",
		"/etc/phusion-server-tools/config.yml",
		"/etc/phusion-server-tools.yml"
	]
	config_filename = nil
	filenames.each do |filename|
		if File.exist?(filename)
			config_filename = filename
			break
		end
	end
	if !config_filename
		STDERR.puts "*** ERROR: you must create a config file at one of the following locations:\n"
		filenames.each do |filename|
			STDERR.puts " * #{filename}"
		end
		STDERR.puts "Please see #{TOOLS_DIR}/config.yml.example for an example."
		exit 1
	end
	all_config = YAML.load_file(config_filename)
	$TOOL_CONFIG = (all_config && all_config[tool_name]) || {}
end

def config(name)
	load_config if !$TOOL_CONFIG
	value = $TOOL_CONFIG[name.to_s]
	if !value
		abort "*** ERROR: configuration option #{File.basename($0)}.#{name} not set."
	end
	return value
end

def optional_config(name, default = nil)
	load_config if !$TOOL_CONFIG
	name = name.to_s
	if $TOOL_CONFIG.has_key?(name)
		return $TOOL_CONFIG[name]
	else
		return default
	end
end

def hostname
	return `hostname`.strip
end

def email(from, to, subject, body)
	to = to.join(", ") if to.is_a?(Array)
	IO.popen("sendmail -t", "w") do |f|
		f.puts "To: #{to}"
		f.puts "From: #{from}" if from
		f.puts "Subject: #{subject}"
		f.puts
		f.puts body
	end
end
