require "safe_yaml"
require "rake-jekyll"
require "json"
require "net/http"
require "uri"

def load_all_mtgjson(dest)
  cd dest do
    sh "rm -rf *"
    sh "wget -q https://mtgjson.com/json/SetCodes.json -O SetCodes.json"
    File.open("SetCodes.json") do |set_codes_json|
      set_codes = JSON.load(set_codes_json)
      set_codes.each do |set_code|
        sleep (1)
        sh "wget -q https://mtgjson.com/json/" + set_code + "-x.json -O " + set_code + "-x.json"
      end
    end
    sleep (1)
    sh "mkdir -p tmp"
    sh "wget -q https://mtgjson.com/json/AllCards-x.json.zip -O tmp/AllCards-x.json.zip"
    sh "unzip tmp/AllCards-x.json.zip"
    sleep (1)
    sh "wget -q https://mtgjson.com/json/version-full.json -O version-full.json"
    sh "rm -rf tmp"
  end
end

task :load_all_mtgjson, [:dest] do |t, args|
  version_json_path = args.dest + '/version-full.json'
  if !File.exist?(version_json_path)
    load_all_mtgjson(args.dest)
    next 
  end
  old_version_json = nil
  File.open(version_json_path) do |old_version_json_file|
    old_version_json = JSON.load(old_version_json_file)
  end
  uri = URI.parse('https://mtgjson.com/json/version-full.json')
  json_get = Net::HTTP.get(uri)
  new_version_json = JSON.parse(json_get)
  p 'old'
  p old_version_json
  p 'new'
  p new_version_json
  if (old_version_json['version'] != new_version_json['version'])
    load_all_mtgjson(args.dest)
  end
end

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
  
  t.remote_url = 'git@github.com:naokiy/tefuda.suku.name.git'
  t.committer = 'naokiy<to_contact@naokiy.net>'

  # Skip commit and push when building a pull request or env. variable
  # SKIP_COMMIT represents truthy.
  t.skip_commit = -> {
    ENV['TRAVIS_PULL_REQUEST'] != 'false' ||
    %w[yes y true 1].include?(ENV['SKIP_COMMIT'].to_s.downcase) ||
    !ENV['TRAVIS_BRANCH'].to_s.include?("develop")
  }
end
