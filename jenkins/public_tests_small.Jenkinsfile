@Library('utils@main') _

node {

    def MAKE_ISSUE = 1;
    properties([
            copyArtifactPermission('${JOB_NAME},'+env.BRANCH_NAME),
    ]);

    stage('Checkout'){
        checkout scm;
    }

    def commitHash = "none";
    stage('Build and Push Docker Image') {
        if (isDependencyInstallerChanged(env.BRANCH_NAME)) {
            commitHash = sh(script: 'git rev-parse HEAD', returnStdout: true);
            commitHash = commitHash.replaceAll(/[^a-zA-Z0-9-]/, '');
            DOCKER_IMAGE_TAG = pushCIImage(env.BRANCH_NAME, commitHash);
        }
    }

    try {

        properties([
                copyArtifactPermission('${JOB_NAME},'+env.BRANCH_NAME),
        ]);

        docker.image("openroad/flow-ubuntu22.04-dev:${DOCKER_IMAGE_TAG}").inside('--user=root --privileged -v /var/run/docker.sock:/var/run/docker.sock') {
            stage('Local Build') {
                sh "git config --system --add safe.directory '*'";
                localBuild();
            }
        }

        stage('Tests') {
            Map tasks = [failFast: false];

            def test_slugs = getTestSlugs("small");
            Map matrix_axes = [
                TEST_SLUG: test_slugs
            ];
            def axes = matrix_axes.TEST_SLUG;
            for (axisValue in axes) {
                def currentSlug = axisValue;
                tasks["${currentSlug}"] = {
                    node {
                        docker.image("openroad/flow-ubuntu22.04-dev:${DOCKER_IMAGE_TAG}").inside('--user=root --privileged -v /var/run/docker.sock:/var/run/docker.sock') {
                            sh "git config --system --add safe.directory '*'";
                            checkout scm;
                            runTests(currentSlug);
                        }
                    }
                }
            }
            parallel(tasks);

        }

        docker.image("openroad/flow-ubuntu22.04-dev:${DOCKER_IMAGE_TAG}").inside('--user=root --privileged -v /var/run/docker.sock:/var/run/docker.sock') {
            sh "git config --system --add safe.directory '*'";

            stage('Report Short Summary') {
                generateReportShortSummary();
            }
            stage("Report HTML Table") {
                generateReportHtmlTable();
            }
            stage('Upload Metadata') {
                uploadMetadata(env.BRANCH_NAME, commitHash);
            }
        }

    } finally {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            try {
                copyArtifacts filter: "flow/reports/report-summary.log", projectName: "${JOB_NAME}", selector: specific("${BUILD_NUMBER}");
                def COMMIT_AUTHOR_EMAIL = sh(script: "git --no-pager show -s --format='%ae'", returnStdout: true).trim();
                sendEmail(env.BRANCH_NAME, COMMIT_AUTHOR_EMAIL, '${FILE, path="flow/reports/report-summary.log"}');
            } catch (Exception e) {
                echo "Exception occurred: ${e.toString()}";
            }
        }
    }

}
