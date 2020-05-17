node {
    try {
        stage ('Checkout Scm') {
            checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'github', url: 'https://github.com/kavaka123/alpha-blog.git']]])
        }
    
        stage('Unit/Integration test and generating Junit test results') {
            sh "export PATH=$PATH:/Users/akaki/.rvm/bin && source \$(rvm 2.5.1 do rvm env --path) && bundle install && rake test"
            // sh "rails test"
            junit keepLongStdio: true, testResults: '**/test/reports/*.xml'
        }
        
        stage('Build a tar file and archive') {
           sh "tar --exclude ./.bundle --exclude ./tmp --exclude ./.git --exclude ./log --exclude ./db/*.sqlite3 --exclude *.tar.gz -cvzf ${JOB_NAME}${BUILD_ID}.tar.gz ."
           archiveArtifacts artifacts: '*.tar.gz', onlyIfSuccessful: true
        }
    } finally {
        stage ('Cleanup workspace') {
            echo "Cleaning up workspace in jenkins home dir"
            cleanWs()
        }
    }
    
}
