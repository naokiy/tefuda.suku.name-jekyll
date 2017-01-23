require "safe_yaml"
require "rake-jekyll"

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

Rake::Jekyll::GitDeployTask.new(:deploy) do |t|
  # master branch for machine
  t.deploy_branch = 'master'

  # Skip commit and push when building a pull request or env. variable
  # SKIP_COMMIT represents truthy.
  t.skip_commit = -> {
    ENV['TRAVIS_PULL_REQUEST'] != 'false' ||
    %w[yes y true 1].include?(ENV['SKIP_COMMIT'].to_s.downcase) ||
    !ENV['TRAVIS_BRANCH'].to_s.include?("develop")
  }
end
