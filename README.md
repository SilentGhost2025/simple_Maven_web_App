# 🚀 Automated CI/CD Pipeline on AWS

> A fully automated DevOps pipeline that takes Java source code from GitHub, builds it with Maven, runs SonarQube code quality analysis, stores the artifact in Nexus, and deploys it to a Tomcat server inside a Docker container — all triggered automatically on every Git push.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Tools & Technologies](#-tools--technologies)
- [AWS Infrastructure](#-aws-infrastructure)
- [Pipeline Stages](#-pipeline-stages)
- [Project Structure](#-project-structure)
- [Configuration Files](#-configuration-files)
- [Jenkins Setup](#-jenkins-setup)
- [SonarQube Integration](#-sonarqube-integration)
- [Nexus Integration](#-nexus-integration)
- [Docker Deployment](#-docker-deployment)
- [Accessing Private Servers](#-accessing-private-servers)
- [Security Practices](#-security-practices)
- [Screenshots](#-screenshots)

---

## 📌 Project Overview

This project implements a production-grade CI/CD pipeline for a Java Spring MVC web application hosted on AWS. The pipeline is fully automated — a single `git push` triggers the entire workflow from build to deployment with no manual intervention.

**What happens on every push:**

```
Developer pushes code to GitHub
        ↓
Jenkins detects push via webhook
        ↓
Maven compiles and packages → Landmark.war
        ↓
SonarQube scans for bugs, vulnerabilities & code smells
        ↓
Artifact uploaded to Nexus repository
        ↓
Docker builds image (Tomcat 10 + JDK 21) → Container deployed
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC (10.0.0.0/16)                │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────────────┐ │
│  │   PUBLIC SUBNET      │  │      PRIVATE SUBNET          │ │
│  │   (10.0.1.0/24)      │  │      (10.0.2.0/24)           │ │
│  │                      │  │                              │ │
│  │  ┌────────────────┐  │  │  ┌─────────────────────┐    │ │
│  │  │ Jenkins Server │  │  │  │   SonarQube Server  │    │ │
│  │  │ (CI/CD)        │◄─┼──┼──│   Port: 9000        │    │ │
│  │  │ Port: 8080     │  │  │  └─────────────────────┘    │ │
│  │  └────────┬───────┘  │  │                              │ │
│  │           │          │  │  ┌─────────────────────┐    │ │
│  │  ┌────────────────┐  │  │  │    Nexus Server     │    │ │
│  │  │  Bastion Host  │  │  │  │   Port: 8081        │    │ │
│  │  │ (SSH Gateway)  │  │  │  └─────────────────────┘    │ │
│  │  └────────────────┘  │  │                              │ │
│  └──────────────────────┘  │  ┌─────────────────────┐    │ │
│                             │  │    App Server       │    │ │
│         GitHub              │  │  Docker + Tomcat    │    │ │
│         Webhooks ──────────►│  │   Port: 8080        │    │ │
│                             │  └─────────────────────┘    │ │
│                             └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tools & Technologies

| Tool | Version | Purpose |
|------|---------|---------|
| **Java** | JDK 21 (Amazon Corretto) | Application runtime |
| **Maven** | 3.x | Build & dependency management |
| **Spring MVC** | 5.1.2 | Web framework |
| **Jenkins** | Latest LTS | CI/CD orchestration |
| **SonarQube** | Latest | Code quality analysis |
| **Nexus OSS** | 3.x | Artifact repository |
| **Docker** | Latest | Containerisation |
| **Tomcat** | 10 (JDK 21) | Application server |
| **AWS EC2** | - | Virtual servers |
| **AWS VPC** | - | Network isolation |
| **Git/GitHub** | - | Source control |

---

## ☁️ AWS Infrastructure

### EC2 Instances

| Server | Purpose | Instance Type | Subnet | Public IP |
|--------|---------|--------------|--------|-----------|
| Jenkins | CI/CD Orchestration | t3.medium | Public | ✅ Yes |
| SonarQube | Code Quality Analysis | t3.medium | Private | ❌ No |
| Nexus | Artifact Repository | t3.medium | Private | ❌ No |
| App Server | Docker + Tomcat | t3.medium | Private | ❌ No |
| Bastion Host | SSH Jump Server | t3.micro | Public | ✅ Yes |

### Security Group Rules

**Jenkins**
| Port | Protocol | Source |
|------|----------|--------|
| 8080 | TCP | Your IP only |
| 22 | TCP | Bastion SG ID |
| 443 | TCP | 0.0.0.0/0 (GitHub webhooks) |

**SonarQube**
| Port | Protocol | Source |
|------|----------|--------|
| 9000 | TCP | Jenkins SG ID |
| 22 | TCP | Bastion SG ID |

**Nexus**
| Port | Protocol | Source |
|------|----------|--------|
| 8081 | TCP | Jenkins SG ID |
| 22 | TCP | Bastion SG ID |

**App Server**
| Port | Protocol | Source |
|------|----------|--------|
| 8080 | TCP | Your IP only |
| 22 | TCP | Jenkins SG ID + Bastion SG ID |

> ⚠️ **Security note:** All inter-server rules use **Security Group IDs** as the source — never open IP ranges. This ensures only specific servers can communicate with each other.

---

## 🔄 Pipeline Stages

The full pipeline is defined in the [`Jenkinsfile`](./Jenkinsfile) at the root of this repository.

### Stage 1 — Clone from GitHub
Jenkins clones the repository from the master branch when triggered by a GitHub webhook push event.

### Stage 2 — Build with Maven
```bash
mvn clean package
```
Compiles the Java source code and packages it into `target/Landmark.war`.

### Stage 3 — SonarQube Code Quality Analysis
```bash
mvn sonar:sonar
```
Scans the codebase for bugs, vulnerabilities, security hotspots, and code smells. The SonarQube token is injected at runtime via `withSonarQubeEnv()` — never hardcoded.

### Stage 4 — Upload Artifact to Nexus
```bash
mvn deploy -s "$MAVEN_SETTINGS" -DskipTests
```
Uploads `Landmark.war` to the Nexus snapshot or release repository. Nexus credentials are injected at runtime via `configFileProvider()`.

### Stage 5 — Build Docker Image & Deploy to Tomcat
Jenkins SSHs into the App Server, copies the `.war` and `Dockerfile`, builds a Docker image, and runs it as a container on port 8080.

---

## 📁 Project Structure

```
simple_Maven_web_App/
├── src/
│   └── main/
│       ├── java/
│       │   └── com/mt/
│       │       └── (Spring MVC controllers & config)
│       └── webapp/
│           └── WEB-INF/
│               └── (JSP views & Spring config)
├── Dockerfile          ← Docker image definition
├── Jenkinsfile         ← Full CI/CD pipeline definition
├── pom.xml             ← Maven build & project config
└── README.md
```

---

## ⚙️ Configuration Files

### `pom.xml` — Key Sections

**SonarQube host (private IP, no credentials):**
```xml
<properties>
    <jdk.version>21</jdk.version>
    <sonar.host.url>http://<sonarqube-private-ip>:9000</sonar.host.url>
    <!-- Credentials handled by Jenkins at runtime — never stored here -->
</properties>
```

**Nexus distribution management:**
```xml
<distributionManagement>
    <repository>
        <id>nexus</id>
        <name>Landmark Technologies Releases</name>
        <url>http://<nexus-private-ip>:8081/repository/DevRepo/</url>
    </repository>
    <snapshotRepository>
        <id>nexus</id>
        <name>Landmark Technologies Snapshots</name>
        <url>http://<nexus-private-ip>:8081/repository/DevRepo-snapshot/</url>
    </snapshotRepository>
</distributionManagement>
```

**Build output name:**
```xml
<build>
    <finalName>Landmark</finalName>
    <!-- Produces: target/Landmark.war -->
</build>
```

---

### `Dockerfile`

```dockerfile
FROM tomcat:10-jdk21

# Remove default Tomcat webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy war to root context (accessible at /)
COPY Landmark.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
```

---

### `Jenkinsfile`

```groovy
pipeline {
    agent any

    environment {
        GIT_REPO   = 'https://github.com/SilentGhost2025/simple_Maven_web_App.git'
        BRANCH     = 'master'
        APP_SERVER = '<app-server-private-ip>'
        USER       = 'ec2-user'
    }

    tools {
        maven 'Maven'
    }

    stages {
        stage('Clone from GitHub') {
            steps {
                git branch: "${BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('Sonarqube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                configFileProvider([configFile(fileId: 'maven-settings',
                                               variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn deploy -s "$MAVEN_SETTINGS" -DskipTests'
                }
            }
        }

        stage('Build Docker & Deploy') {
            steps {
                sshagent(['app-server-ssh']) {
                    sh """
                        scp -o StrictHostKeyChecking=no \
                            target/Landmark.war \
                            ${USER}@${APP_SERVER}:/home/${USER}/

                        scp -o StrictHostKeyChecking=no \
                            Dockerfile \
                            ${USER}@${APP_SERVER}:/home/${USER}/

                        ssh -o StrictHostKeyChecking=no ${USER}@${APP_SERVER} '
                            cd /home/${USER}
                            docker stop tomcat-app || true
                            docker rm tomcat-app || true
                            docker rmi tomcat-app:latest || true
                            docker build -t tomcat-app:latest .
                            docker run -d \
                                --name tomcat-app \
                                -p 8080:8080 \
                                --restart unless-stopped \
                                tomcat-app:latest
                            docker ps | grep tomcat-app
                        '
                    """
                }
            }
        }
    }

    post {
        success { echo '✅ Pipeline finished — app deployed successfully!' }
        failure { echo '❌ Pipeline failed — check the console output.' }
    }
}
```

---

## 🔧 Jenkins Setup

### Required Plugins
| Plugin | Purpose |
|--------|---------|
| SonarQube Scanner | Enables `withSonarQubeEnv()` |
| Config File Provider | Manages `settings.xml` securely |
| Maven Integration | Runs Maven build stages |
| SSH Agent | Injects `.pem` key for remote deployment |
| GitHub Integration | Handles webhook triggers |

### Credentials to Configure
| ID | Kind | Used For |
|----|------|---------|
| `sonar-token` | Secret Text | SonarQube authentication |
| `nexus-credentials` | Username/Password | Nexus artifact upload |
| `app-server-ssh` | SSH Private Key | SSH/SCP to App Server |

### SonarQube Server Config
```
Manage Jenkins → Configure System → SonarQube Servers
    Name:       Sonarqube
    Server URL: http://<sonarqube-private-ip>:9000
    Token:      sonar-token (from credentials store)
```

### Maven settings.xml (via Config File Provider)
```xml
<settings>
    <servers>
        <server>
            <id>nexus</id>
            <username>${NEXUS_USER}</username>
            <password>${NEXUS_PASS}</password>
        </server>
    </servers>
</settings>
```
> Bind `ServerId: nexus` to `nexus-credentials` in the Managed Files config page.

---

## 📊 SonarQube Integration

SonarQube runs on a private EC2 instance. Access it locally via SSH tunnel:

```bash
ssh -i "NewKEY.pem" \
    -L 9000:<sonarqube-private-ip>:9000 \
    ubuntu@<bastion-public-ip> \
    -N
```

Then open: `http://localhost:9000`

- Generate a token: **My Account → Security → Generate Token**
- Store it in Jenkins as credential ID: `sonar-token`
- The `withSonarQubeEnv('Sonarqube')` wrapper injects the token automatically at runtime

---

## 📦 Nexus Integration

Nexus runs on a private EC2 instance. Access it locally via SSH tunnel:

```bash
ssh -i "NewKEY.pem" \
    -L 8081:<nexus-private-ip>:8081 \
    ubuntu@<bastion-public-ip> \
    -N
```

Then open: `http://localhost:8081`

**Repositories configured:**
| Repo Name | Type | Used For |
|-----------|------|---------|
| `DevRepo` | Maven Hosted (Release) | Release artifacts |
| `DevRepo-snapshot` | Maven Hosted (Snapshot) | Snapshot artifacts |

---

## 🐳 Docker Deployment

The App Server runs Docker and Tomcat inside a container. Standalone Tomcat is disabled to free port 8080:

```bash
sudo systemctl stop tomcat
sudo systemctl disable tomcat
```

Each pipeline run:
1. Stops and removes the old container
2. Removes the old image
3. Builds a fresh image from the new `.war`
4. Starts a new container with `--restart unless-stopped`

**Verify the running container:**
```bash
docker ps | grep tomcat-app
docker logs tomcat-app
```

---

## 🔐 Accessing Private Servers

All private servers are accessed via SSH tunnelling through the Bastion Host. No private server has a public IP.

**SSH Jump (for installation/configuration):**
```bash
ssh -i "NewKEY.pem" -J ubuntu@<bastion-public-ip> ec2-user@<private-ip>
```

**Port forwarding (for web UI access):**
```bash
# SonarQube
ssh -i "NewKEY.pem" -L 9000:<sonarqube-ip>:9000 ubuntu@<bastion-ip> -N

# Nexus
ssh -i "NewKEY.pem" -L 8081:<nexus-ip>:8081 ubuntu@<bastion-ip> -N

# App (deployed application)
ssh -i "NewKEY.pem" -L 8080:<app-server-ip>:8080 ubuntu@<bastion-ip> -N
```

> 💡 The `-N` flag means no output — a blinking cursor means the tunnel is active. Leave the terminal open while using the web UI.

---

## 🔒 Security Practices

| Practice | Implementation |
|----------|---------------|
| No credentials in code | All secrets in Jenkins Credentials Store only |
| SonarQube token | Injected at runtime via `withSonarQubeEnv()` |
| Nexus credentials | Injected at runtime via `configFileProvider()` |
| SSH private key | Injected at runtime via `sshagent()` |
| Private subnet isolation | SonarQube, Nexus, App Server have no public IP |
| Security group chaining | SG IDs used as source, not open CIDR ranges |
| SSH access control | Bastion restricted to port 22 from your IP only |
| No root processes | Nexus and SonarQube run as dedicated non-root users |

> ✅ **Golden rule:** Credentials only ever exist in the Jenkins Credentials Store. They are injected at runtime and never touch the codebase, `pom.xml`, `Dockerfile`, or version control at any point.


## 👤 Author

**SilentGhost2025**
- GitHub: [@SilentGhost2025](https://github.com/SilentGhost2025)
- LinkedIn: linkedin.com/in/salvation-samuel-1a62052a1

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">Built with ❤️ by Landmark Technologies DevOps Team</p>
