task :default => [:test, :gem]

task :test => ['lib/lined.rb', 'spec/spec_helper.rb', 'spec/lined/lined_spec.rb'] do
  sh "rspec"
end

task :gem => ['lib/lined.rb', 'lined.gemspec'] do
  sh "gem build lined.gemspec"
end
