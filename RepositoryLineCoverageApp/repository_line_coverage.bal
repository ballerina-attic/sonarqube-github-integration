import ballerina/config;
import wso2/github4;
import ballerina/io;
import wso2/sonarqube6;

public function main(string[] args) {

    json summary = getLineCoverageSummary(5) but {error => null};
    io:println(summary);
}

function getLineCoverageSummary (int recordCount) returns json|error{

    endpoint github4:Client githubEP {
        accessToken:config:getAsString("GITHUB_TOKEN") ?: "",
        clientEndpointConfiguration: {}
    };

    endpoint sonarqube6:SonarQubeClient sonarqubeEP {
        token:config:getAsString("SONARQUBE_TOKEN") ?: "",
        uri:"https://wso2.org/sonar"
    };

    github4:Organization organization;
    var gitOrganizationResult = githubEP -> getOrganization("wso2");
    match gitOrganizationResult {
        github4:Organization org => {
            organization = org;
        }
        github4:GitConnectorError err => {
            io:println(err);
        }
    }

    github4:RepositoryList repositoryList;
    var gitRepostoryResult = githubEP -> getOrganizationRepositoryList(organization, recordCount);
    match gitRepostoryResult {
        github4:RepositoryList repoList => {
            repositoryList = repoList;
        }
        github4:GitConnectorError err => {
            io:println(err);
        }
    }
    json summaryJson = [];
    foreach i, repo in repositoryList.getAllRepositories() {
        var sonarqubeProjectResult = sonarqubeEP -> getProject(repo.name);
        match sonarqubeProjectResult {
            sonarqube6:Project project => {
                string lineCoverage = sonarqubeEP -> getLineCoverage(project.key) but {error err => "0.0%"};
                summaryJson[i] = {"name": repo.name, "coverage":lineCoverage};
            }
            error err => {
                summaryJson[i] = {"name": repo.name, "coverage": "Not defined"};
            }
        }
    }

    return summaryJson;
}