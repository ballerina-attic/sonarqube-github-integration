// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/config;
import ballerina/http;
import ballerina/io;
import wso2/github4;
import wso2/sonarqube6;

public function main(string... args) {

    var summary = getLineCoverageSummary(5);
    io:println(summary);
}

function getLineCoverageSummary(int recordCount) returns json|error {

    github4:Client githubEP = new({
        clientConfig: {
            auth: {
                scheme: http:OAUTH2,
                accessToken: config:getAsString("GITHUB_TOKEN")
            }
        }
    });

    sonarqube6:Client sonarqubeEP = new ({
        clientConfig: {
            url: config:getAsString("SONARQUBE_ENDPOINT"),
            auth: {
                scheme: http:BASIC_AUTH,
                username: config:getAsString("SONARQUBE_TOKEN"),
                password: ""
            }
        }
    });

    github4:Organization organization = new;
    var gitOrganizationResult = githubEP->getOrganization("wso2");
    if (gitOrganizationResult is error) {
        return gitOrganizationResult;
    } else {
        organization = gitOrganizationResult;
    }

    github4:RepositoryList repositoryList = new;
    var gitRepostoryResult = githubEP->getOrganizationRepositoryList(organization, recordCount);
    if (gitRepostoryResult is error) {
        return gitRepostoryResult;
    } else {
        repositoryList = gitRepostoryResult;
    }
    json summaryJson = [];
    int i = 0;
    foreach github4:Repository repo in repositoryList.getAllRepositories() {
        var sonarqubeProjectResult = sonarqubeEP->getProject(repo.name);
        if (sonarqubeProjectResult is error) {
            summaryJson[i] = { "name": repo.name, "coverage": "Not defined" };
        } else {
            var lineCoverageResult = sonarqubeEP->getLineCoverage(untaint sonarqubeProjectResult.key);
            if (lineCoverageResult is error) {
                summaryJson[i] = { "name": repo.name, "coverage": "0.0%" };
            } else {
                summaryJson[i] = { "name": repo.name, "coverage": lineCoverageResult };
            }
        }
        i += 1;
    }
    return summaryJson;
}
