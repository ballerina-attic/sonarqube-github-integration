import ballerina/config;
import wso2/github4;
import ballerina/io;
import wso2/sonarqube6;

function main(string... args) {

    json summary = check getLineCoverageSummary(5);
    io:println(summary);
}

function getLineCoverageSummary(int recordCount) returns json|error {

    endpoint github4:Client githubEP {
        clientConfig: {
            auth: {
                scheme: "oauth",
                accessToken: config:getAsString("GITHUB_TOKEN")
            }
        }
    };

    endpoint sonarqube6:Client sonarqubeEP {
        clientConfig: {
            url: config:getAsString("SONARQUBE_ENDPOINT"),
            auth: {
                scheme: "basic",
                username: config:getAsString("SONARQUBE_TOKEN"),
                password: ""
            }
        }
    };

    github4:Organization organization;
    var gitOrganizationResult = githubEP->getOrganization("wso2");
    match gitOrganizationResult {
        github4:Organization org => {
            organization = org;
        }
        github4:GitClientError err => {
            return err;
        }
    }

    github4:RepositoryList repositoryList;
    var gitRepostoryResult = githubEP->getOrganizationRepositoryList(organization, recordCount);
    match gitRepostoryResult {
        github4:RepositoryList repoList => {
            repositoryList = repoList;
        }
        github4:GitClientError err => {
            return err;
        }
    }
    json summaryJson = [];
    foreach i, repo in repositoryList.getAllRepositories() {
        var sonarqubeProjectResult = sonarqubeEP->getProject(repo.name);
        match sonarqubeProjectResult {
            sonarqube6:Project project => {
                string lineCoverage = sonarqubeEP->getLineCoverage(untaint project.key) but { error err => "0.0%" };
                summaryJson[i] = { "name": repo.name, "coverage": lineCoverage };
            }
            error err => {
                summaryJson[i] = { "name": repo.name, "coverage": "Not defined" };
            }
        }
    }

    return summaryJson;
}