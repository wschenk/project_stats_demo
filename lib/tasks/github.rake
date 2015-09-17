require 'fileutils'

file "data/projects.json" do
  Rake::Task["environment"].invoke
  FileUtils.mkdir_p "data"

  gc = User.first.github_client

  data = gc.org_repos( 'HappyFunCorp', {:type => 'private'} ).collect do |x|
    { name: x[:name],
      full_name: x[:full_name],
      url: x[:url] }
  end

  File.open( "data/projects.json", "w" ) do |out|
    out.puts JSON.unparse( data )
  end
end

def for_each_elem( name, file )
  task name => file do
    JSON.parse( File.read( file ) ).each do |record|
      yield record
    end
  end
end

for_each_elem "load_gemfiles", "data/projects.json" do |repo|
  outfile = "data/gemfiles/#{repo['name']}.Gemfile.lock"
  FileUtils.mkdir_p "data/gemfiles"

  file outfile do
    Rake::Task["environment"].invoke

    gc = User.first.github_client

    begin
      content = gc.contents repo['full_name'], path: 'Gemfile.lock'

      File.open outfile, "w" do |out|
        out.puts Base64.decode64 content.content
      end
    rescue Octokit::NotFound
      puts "No Gemfile.lock found for #{repo['full_name']}"
    end
  end

  Rake::Task[outfile].invoke
end

for_each_elem "filter_gemfiles", "data/projects.json" do |repo|
  sourcefile = "data/gemfiles/#{repo['name']}.Gemfile.lock"
  outfile = "data/filtered/#{repo['name']}.gems"
  FileUtils.mkdir_p "data/filtered"

  if File.exists?( sourcefile )
    file outfile do
      system( "awk '/^    [^ ]/ { print $1, $2 }' #{sourcefile} > #{outfile}" )
    end
    Rake::Task[outfile].invoke
  end
end

file "data/versioned.list" do
  system( "cat data/filtered/* | sort | uniq -c | sort -rn > data/versioned.list" )
end

file "data/gems.list" do
  system( "awk '{print $1}' data/filtered/* | sort | uniq -c | sort -rn > data/gems.list")
end
