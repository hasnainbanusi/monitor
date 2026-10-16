pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
    }

    stages {
        stage('Validate Configuration') {
            steps {
                sh '''
                    set -eu
                    docker compose config -q
                    echo "Docker Compose configuration is valid."
                '''
            }
        }

        stage('Check Monitoring Services') {
            steps {
                sh '''
                    set -eu

                    curl --fail --silent --show-error \
                        http://localhost:9090/-/ready

                    curl --fail --silent --show-error \
                        http://localhost:3000/api/health

                    curl --fail --silent --show-error \
                        http://localhost:9100/metrics -o /dev/null

                    echo "All monitoring service checks passed."
                '''
            }
        }

        stage('Verify Prometheus Targets') {
            steps {
                sh '''
                    set -eu

                    curl --fail --silent --show-error \
                        http://localhost:9090/api/v1/targets \
                        -o targets.json

                    python3 -c '
import json
with open("targets.json") as f:
    data = json.load(f)
targets = data["data"]["activeTargets"]
print("Active Prometheus targets:", len(targets))
for target in targets:
    print(target["labels"].get("job"), target["health"])
if not targets:
    raise SystemExit("ERROR: No active Prometheus targets found")
'
                '''
            }
        }
    }

    post {
        success {
            script {
                if (env.EMAIL_RECIPIENT?.trim()) {
                    emailext(
                        to: env.EMAIL_RECIPIENT,
                        subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """Monitoring dashboard pipeline succeeded.

Job: ${env.JOB_NAME}
Build: #${env.BUILD_NUMBER}
Status: ${currentBuild.currentResult}
Build URL: ${env.BUILD_URL}
"""
                    )
                } else {
                    echo 'EMAIL_RECIPIENT is not configured; success email skipped.'
                }
            }
        }

        failure {
            script {
                if (env.EMAIL_RECIPIENT?.trim()) {
                    emailext(
                        to: env.EMAIL_RECIPIENT,
                        subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """Monitoring dashboard pipeline failed.

Job: ${env.JOB_NAME}
Build: #${env.BUILD_NUMBER}
Status: ${currentBuild.currentResult}
Build URL: ${env.BUILD_URL}
Check the Jenkins console output for details.
"""
                    )
                } else {
                    echo 'EMAIL_RECIPIENT is not configured; failure email skipped.'
                }
            }
        }
    }
}
