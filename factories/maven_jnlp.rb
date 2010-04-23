
Factory.define :maven_jnlp_maven_jnlp_server, :class => MavenJnlp::MavenJnlpServer do |f|
  server, family, version = Admin::Project.default_jnlp_info
  f.host server[:host]
  f.path server[:path]
  f.name server[:name]
end

Factory.define :maven_jnlp_maven_jnlp_family, :class => MavenJnlp::MavenJnlpFamily do |f|
  server, family, version = Admin::Project.default_jnlp_info
  
  f.name family
  f.snapshot_version version
  f.url 'http://jnlp.concord.org/dev/org/concord/maven-jnlp/all-otrunk-snapshot/'
  f.association :maven_jnlp_server, :factory => :maven_jnlp_maven_jnlp_server
end

Factory.define :maven_jnlp_versioned_jnlp_url, :class => MavenJnlp::VersionedJnlpUrl do |f|
  f.path  '/dev/org/concord/maven-jnlp/all-otrunk-snapshot/all-otrunk-snapshot-0.1.0-20091013.161730.jnlp'
  f.url  'http://jnlp.concord.org/dev/org/concord/maven-jnlp/all-otrunk-snapshot/all-otrunk-snapshot-0.1.0-20091013.161730.jnlp'
  f.date_str  '20091013.161730'
  f.version_str  '0.1.0-20091013.161730'
  f.association :maven_jnlp_family, :factory => :maven_jnlp_maven_jnlp_family
end

Factory.define :maven_jnlp_versioned_jnlp, :class => MavenJnlp::VersionedJnlp do |f|
  f.name  'all-otrunk-snapshot-0.1.0-20091013.161730.jnlp'
  f.main_class  'net.sf.sail.emf.launch.EMFLauncher3'
  f.argument  'dummy'
  f.offline_allowed  1
  f.spec  '1.0+'
  f.j2se_version  '1.5+'
  f.max_heap_size  '128'
  f.initial_heap_size  '32'
  f.codebase  'http://jnlp.concord.org/dev'
  f.href  'http://jnlp.concord.org/dev/org/concord/maven-jnlp/all-otrunk-snapshot/all-otrunk-snapshot-0.1.0-20091013.161730.jnlp'
  f.title  'All OTrunk snapshot'
  f.vendor  'Concord Consortium'
  f.homepage  'index.html'
  f.description  'Preview Basic Pas'
  f.association :versioned_jnlp_url, :factory => :maven_jnlp_versioned_jnlp_url
end

Factory.define :maven_jnlp_jar, :class => MavenJnlp::Jar do |f|
end

Factory.define :maven_jnlp_native_library, :class => MavenJnlp::NativeLibrary do |f|
end

Factory.define :maven_jnlp_icon, :class => MavenJnlp::Icon do |f|
end

Factory.define :maven_jnlp_property, :class => MavenJnlp::Property do |f|
end

