require "safe_yaml"

task :convert_front_matter , [:src] do |t, args|
  YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m
  if !args.src || args.src == ""
    p 'illegal src'
    next
  end
  Dir.glob(args.src + '/**/*').each do |path|
    if File.file?(path)
      p 'found ' + path
      whole_content = File.read(path)
      if whole_content =~ YAML_FRONT_MATTER_REGEXP
        p 'converting'
        front_matter = Regexp.last_match(1)
        content = Regexp.last_match.post_match
        parsed = SafeYAML.load(front_matter)
        if parsed['title'] && !parsed['slug']
          parsed['slug'] = parsed['title']
        end
        File.open(path, 'w') do |f|
          YAML.dump(parsed, f)
          f.puts '---'
          f.puts content
        end
      end
    end
  end
end

task :cp , [:src, :dest] do |t, args|
  FileUtils.mkdir_p args.dest
  real_dest = File.absolute_path(args.dest) 
  cd args.src do
    FileUtils.cp_r(Dir.glob('.'), real_dest, { :verbose => true, :remove_destination => true });
  end
end
