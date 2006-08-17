$stdout.sync = true

desc "Rebuild search index for all models"
task :model_indexer => [:environment] do

  classes = []
  Dir.glob(File.join(RAILS_ROOT,"app","models","*.rb")).each do |rbfile|
    bname = File.basename(rbfile,'.rb')
    klass = bname.camelize.constantize
    classes.push(klass)
  end
  classes.each do |c|
    c.index_all if c.respond_to?(:index_all)
  end
end