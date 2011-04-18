def sh(command, *args)
	puts "# #{command} #{args.join(' ')}"
	if !system(command, *args)
		STDERR.puts "*** ERROR"
		exit 1
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
