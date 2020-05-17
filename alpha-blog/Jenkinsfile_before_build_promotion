node {
    try {
        stage ('Checkout Scm') {
            checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'github', url: 'https://github.com/kavaka123/alpha-blog.git']]])
        }
    
        stage('SonarQube coverage for unit/integration tests') {
            def scannerHome = tool 'sonar_scanner';
            withSonarQubeEnv() {
	       sh "bundle install --path vendor/bundle" 
               sh "bundle exec rake test"
               junit keepLongStdio: true, testResults: '**/test/reports/*.xml'
               sh "${scannerHome}/bin/sonar-scanner"
            }
        }
        
        stage('Archive tar file and upload to artifactory') {
            sh "touch ${JOB_NAME}${BUILD_ID}.tar.gz"
	    sh "tar --exclude ./.bundle --exclude ./vendor --exclude ./tmp --exclude ./.git --exclude ./log --exclude ./db/*.sqlite3 --exclude *.tar.gz -cvzf ${JOB_NAME}${BUILD_ID}.tar.gz ."
           archiveArtifacts artifacts: '*.tar.gz', onlyIfSuccessful: true

           def server = Artifactory.server 'local-artifactory-server'
           server.credentialsId = 'jenkins'
	   def buildInfo = Artifactory.newBuildInfo()
	   def uploadSpec = """{
	     "files": [
		{
			"pattern": "./*.tar.gz",
			"target": "alpha-blog-local/"
		}
	     ]
           }"""

           server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: true
           server.publishBuildInfo buildInfo
        }
    } finally {
        stage ('Cleanup workspace') {
            echo "Cleaning up workspace in jenkins home dir"
            cleanWs()
        }
    }
    
}
