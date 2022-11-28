pipeline {
  agent any;
  environment {
    MAKE_ISSUE = 1;
  }
  options {
    copyArtifactPermission('${JOB_NAME},'+env.BRANCH_NAME);
  }
  stages {

    stage('Local Build') {
      agent any;
      steps {
        sh "./build_openroad.sh --local";
        stash name: "install", includes: "tools/install/**";
      }
    }

    stage('Tests') {
      matrix {
        axes {
          axis {
            name 'TEST_SLUG';
            values "docker build",
                  "aes asap7",
                  "ethmac asap7",
                  "gcd asap7",
                  "ibex asap7",
                  "jpeg asap7",
                  "sha3 asap7",
                  "uart asap7",
                  "aes nangate45",
                  "black_parrot nangate45",
                  "bp_be_top nangate45",
                  "bp_fe_top nangate45",
                  "bp_multi_top nangate45",
                  "dynamic_node nangate45",
                  "gcd nangate45",
                  "ibex nangate45",
                  "jpeg nangate45",
                  "swerv nangate45",
                  "swerv_wrapper nangate45",
                  "tinyRocket nangate45",
                  "aes sky130hd",
                  "chameleon sky130hd",
                  "gcd sky130hd",
                  "ibex sky130hd",
                  "jpeg sky130hd",
                  "microwatt sky130hd",
                  "riscv32i sky130hd",
                  "aes sky130hs",
                  "gcd sky130hs",
                  "ibex sky130hs",
                  "jpeg sky130hs",
                  "riscv32i sky130hs",
                  "aes gf180";
          }
        }

        stages {
          stage('Test') {
            options {
              timeout(time: 6, unit: "HOURS");
            }
            agent any;
            steps {
              unstash "install";
              script {
                stage("${TEST_SLUG}") {
                  if ("${TEST_SLUG}" == 'docker build'){
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                      sh "./build_openroad.sh";
                    }
                  } else {
                    try {
                        sh 'nice flow/test/test_helper.sh ${TEST_SLUG}';
                        currentBuild.result = 'SUCCESS';
                    } catch (err) {
                        sh "mkdir -p flow/results/failures";
                        env.NAME=sh(script: "echo ${TEST_SLUG} | tr '-' ' '", returnStdout: true);
                        sh "cp flow/*tar.gz flow/results/failures/final-report-${env.NAME}-base-${env.BUILD_ID}.tar.gz";
                        currentBuild.result = 'FAILURE';
                        error("${err}");
                    }
                  }
                }
              }
            }
            post {
              always {
                archiveArtifacts artifacts: "flow/*tar.gz", allowEmptyArchive: true;
                archiveArtifacts artifacts: "flow/logs/**/*, flow/reports/**/*", allowEmptyArchive: true;
                archiveArtifacts artifacts: "flow/results/failures/**/*", allowEmptyArchive: true;
              }
            }
          }
        }
      }
    }

    stage("Report Short Summary") {
      steps {
        copyArtifacts filter: "flow/logs/**/*",
                      projectName: '${JOB_NAME}',
                      selector: specific('${BUILD_NUMBER}');
        copyArtifacts filter: "flow/reports/**/*",
                      projectName: '${JOB_NAME}',
                      selector: specific('${BUILD_NUMBER}');
        sh "flow/util/genReport.py -sv";
      }
      post {
        always {
          archiveArtifacts artifacts: "flow/reports/report-summary.log";
        }
      }
    }

    stage("Report Summary") {
      steps {
        sh "flow/util/genReport.py -svv";
      }
    }

    stage("Report Full") {
      steps {
        sh "flow/util/genReport.py -vvvv";
      }
      post {
        always {
          archiveArtifacts artifacts: "flow/reports/**/report*.log";
        }
      }
    }

    stage("Report HTML Table") {
      steps {
        sh "flow/util/genReportTable.py";
        publishHTML([
            allowMissing: true,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportName: "Report",
            reportDir: "flow/reports",
            reportFiles: "report-table.html,report-gallery*.html",
            reportTitles: "Flow Report"
        ]);
      }
    }

  }

  post {
    failure {
      copyArtifacts filter: "flow/reports/report-summary.log",
                    projectName: '${JOB_NAME}',
                    selector: specific('${BUILD_NUMBER}');
      script {
        try {
          COMMIT_AUTHOR_EMAIL = sh (returnStdout: true, script: "git --no-pager show -s --format='%ae'").trim();
          if ( env.BRANCH_NAME == "master" ) {
            echo("Main development branch: report to stakeholders and commit author.");
            EMAIL_TO="$COMMIT_AUTHOR_EMAIL, \$DEFAULT_RECIPIENTS";
          } else {
            echo("Feature development branch: report only to commit author.");
            EMAIL_TO="$COMMIT_AUTHOR_EMAIL";
          }
        } catch (Exception e) {
          echo "Exception occurred: " + e.toString();
          EMAIL_TO="\$DEFAULT_RECIPIENTS";
        }
        emailext (
            to: "$EMAIL_TO",
            replyTo: "$EMAIL_TO",
            subject: '$DEFAULT_SUBJECT',
            body: '''
$DEFAULT_CONTENT
${FILE,path="flow/reports/report-summary.log"}
            ''',
            )
      }
    }
  }

}
