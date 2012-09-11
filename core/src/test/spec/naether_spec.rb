require  File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'src/main/ruby/naether'
require 'src/main/ruby/naether/java'

describe Naether do
  
  context "Class" do
    
    it "should have bootstrap dependencies" do
      Naether.bootstrap_dependencies( 'jar_dependencies.yml' ).should include "org.sonatype.aether:aether-util:jar:1.13"
    end
    
    it "should have JAR_PATH constant in naether jar" do
      version = IO.read("VERSION").strip
      Naether::JAR_PATH.should match /naether-#{version}.jar/
    end
    
  end
  
  context "Instance" do
    
    before(:each) do
      @test_dir = 'target/test-rb'
      unless File.exists?( @test_dir )
        Dir.mkdir @test_dir
      end
      
      @naether = Naether.create_from_paths("target/lib", 'target')
      @naether.should_not be_nil
      @naether.local_repo_path = 'target/test-repo'
    end
    
    it "should have set local repo path" do
      @naether.local_repo_path.should eql( 'target/test-repo' )
    end
    
    it "should add a remote repository" do
      @naether.add_remote_repository("http://test.net:7011")
      @naether.remote_repositories[0].getId().should eql( "central" )
      @naether.remote_repositories[1].getId().should eql( "test.net-7011" )
    end
    
    it "should only add a unique remote repository" do
      @naether.add_remote_repository("http://test.net:7011")
      @naether.add_remote_repository("http://test.net:7011")
      
      @naether.remote_repository_urls.should eql(["http://repo1.maven.org/maven2/", "http://test.net:7011"])
    end
    
    it "should add a dependency from notation" do
      @naether.dependencies = "junit:junit:jar:4.8.2" 
      @naether.dependencies_notation.should eql ["junit:junit:jar:4.8.2"]
    end
    
    it "should get paths for dependencies" do
      @naether.dependencies = "junit:junit:jar:4.8.2" 
      @naether.resolve_dependencies
      @naether.dependencies_path.should eql({"junit:junit:jar:4.8.2" => File.expand_path("target/test-repo/junit/junit/4.8.2/junit-4.8.2.jar")})
    end
    
    it "should get local paths for notations" do
      paths = @naether.to_local_paths( ["junit:junit:jar:4.8.2"] )
      paths.first.should match /test-repo\/junit\/junit\/4.8.2\/junit-4.8.2.jar/
    end
    
    it "should set build artifacts" do
      @naether.build_artifacts = { "build_artifact:test:0.1" => 'target/test-repo/junit/junit/4.8.2/junit-4.8.2.jar' }
      @naether.dependencies = [ "ch.qos.logback:logback-classic:jar:0.9.29", "junit:junit:jar:4.8.2" ]
      @naether.resolve_dependencies().should eql [
        "ch.qos.logback:logback-classic:jar:0.9.29",
        "ch.qos.logback:logback-core:jar:0.9.29",
        "org.slf4j:slf4j-api:jar:1.6.1",
        "junit:junit:jar:4.8.2"]
    end
    
    context "setting mixed list of dependencies" do
      it "should handle a list of dependencies" do
         @naether.dependencies = [ "junit:junit:jar:4.8.2", "ch.qos.logback:logback-classic:jar:0.9.29" ]  
         @naether.dependencies_notation.should eql ["junit:junit:jar:4.8.2", "ch.qos.logback:logback-classic:jar:0.9.29"]
      end
      
      it "should handle poms in a list of dependencies" do
         @naether.dependencies = [  "pom.xml", "does.not:exist:jar:0.1" ]  
         @naether.dependencies_notation.should eql [
            "ch.qos.logback:logback-classic:jar:0.9.29",
            "org.slf4j:slf4j-api:jar:1.6.2",
            "org.slf4j:jcl-over-slf4j:jar:1.6.2",
            "org.slf4j:log4j-over-slf4j:jar:1.6.2",
            "org.codehaus.plexus:plexus-utils:jar:3.0",
            "org.apache.maven:maven-model-v3:jar:2.0",
            "org.codehaus.plexus:plexus-container-default:jar:1.5.5",
            "org.sonatype.aether:aether-api:jar:1.13",
            "org.sonatype.aether:aether-util:jar:1.13",
            "org.sonatype.aether:aether-impl:jar:1.13",
            "org.sonatype.aether:aether-connector-file:jar:1.13",
            "org.sonatype.aether:aether-connector-asynchttpclient:jar:1.13",
            "org.sonatype.aether:aether-connector-wagon:jar:1.13",
            "org.apache.maven:maven-aether-provider:jar:3.0.3",
            "org.apache.maven.wagon:wagon-ssh:jar:1.0",
            "org.apache.maven.wagon:wagon-http-lightweight:jar:1.0",
            "org.apache.maven.wagon:wagon-file:jar:1.0",
            "does.not:exist:jar:0.1" ]
      end
      
      it "should handle scopes" do
        @naether.dependencies = [ {"src/test/resources/valid_pom.xml" => ["test"]}, {"junit:junit:jar:4.8.2" => "test"}, "ch.qos.logback:logback-classic:jar:0.9.29" ]  
        @naether.dependencies_notation.should eql ["junit:junit:jar:4.8.2", "com.google.code.greaze:greaze-client:jar:test-jar:0.5.1", "junit:junit:jar:4.8.2", "ch.qos.logback:logback-classic:jar:0.9.29"]
        @naether.resolve_dependencies().should eql ["junit:junit:jar:4.8.2", "com.google.code.greaze:greaze-client:jar:test-jar:0.5.1", "com.google.code.gson:gson:jar:1.7.1", "com.google.code.greaze:greaze-definition:jar:0.5.1", "ch.qos.logback:logback-classic:jar:0.9.29", "ch.qos.logback:logback-core:jar:0.9.29", "org.slf4j:slf4j-api:jar:1.6.1"]
      end
    end
    
    it "should resolve dependencies" do
      @naether.dependencies = "ch.qos.logback:logback-classic:jar:0.9.29" 
      @naether.resolve_dependencies().should eql ["ch.qos.logback:logback-classic:jar:0.9.29", "ch.qos.logback:logback-core:jar:0.9.29", "org.slf4j:slf4j-api:jar:1.6.1"]
    end
    

    it "should resolve pom dependencies with properties" do
      @naether.dependencies  = 'src/test/resources/pom_with_broken_dep.xml' 
      @naether.resolve_dependencies(false, { 'project.basedir' => File.expand_path( 'src/test/resources' ) } ).should eql( 
        ["pom:with-system-path:jar:2", "ch.qos.logback:logback-classic:jar:0.9.29", 
         "ch.qos.logback:logback-core:jar:0.9.29", "org.slf4j:slf4j-api:jar:1.6.1", 
          "google:gdata-spreadsheet:jar:3.0"] )
    end

    it "should download artifacts" do
      if File.exists?("target/test-repo/junit/junit/4.9/junit-4.9.jar")
        FileUtils.rm_rf( "target/test-repo/junit/junit/4.9" );
      end
      
      if File.exists?("target/test-repo/junit/junit/4.10/junit-4.10.jar")
        FileUtils.rm_rf( "target/test-repo/junit/junit/4.10" );
      end
      
      paths = @naether.download_artifacts( ["junit:junit:4.10", "junit:junit:4.9"])
        
      File.exists?("target/test-repo/junit/junit/4.9/junit-4.9.jar").should be_true
      File.exists?("target/test-repo/junit/junit/4.10/junit-4.10.jar").should be_true
    end
    
    it "should deploy artifact" do
      if File.exists?( 'target/test-repo/test/test/22.3/test-22.3.jar' )
        File.delete( 'target/test-repo/test/test/22.3/test-22.3.jar' )
      end
      jar = "target/test-repo/junit/junit/4.8.2/junit-4.8.2.jar"
      
      @naether.deploy_artifact( "test:test:jar:22.3", jar, "file:target/test-repo" )
      
      File.exists?( 'target/test-repo/test/test/22.3/test-22.3.jar' ).should be_true
    end
   
    it "should change logging level" do
      @naether.set_log_level( 'debug' )
      Naether::Java.java_class("com.tobedevoured.naether.util.LogUtil").getLogLevel("com.tobedevoured").toString().should eql( "DEBUG" )
      
      @naether.set_log_level( 'info' )
      Naether::Java.java_class("com.tobedevoured.naether.util.LogUtil").getLogLevel("com.tobedevoured").toString().should eql( "INFO" )
          
    end
  end
end