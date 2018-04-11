# Repository line coverage with sonarqube and github connectors

SonarQube is an open source platform developed by SonarSource for continuous inspection of code quality to perform 
automatic reviews with static analysis of code to detect bugs, code smells and security vulnerabilities.
Similarly GitHub brings together the world's largest community of developers to discover, share, 
and build better software. From open source projects to private team repositories, 
GitHub is an all-in-one platform for collaborative development.

> This guide will walk you through the process of obtaining the test line coverage of each repository in a 
github organization.

The following sections are covered in this guide
- [What you'll build](#what-you-build)
- [Prerequisites](#pre-req)
- [Developing the service](#developing-service)
- [Testing](#testing)
- [Deployment](#deploying-the-scenario)
 
## What you'll build

Let's consider a sample scenario to understand how you can use ballerina connectors. The following scenario specifies 
how sonarqube and ballerina github connectors can be used to get a summary of the test line converage of all 
repositories in a specific organization. In GitHub, there are numerous organizations, which have a collection of 
repositories relevant to various projects, and sonaqube contains the details regarding those projects; such as 
test line coverage, code duplications and bugs. The test line coverage of a repository is a significant metric that 
project leads require in order to get an overall understanding of the test coverage in the project.

In this example, we use the ballerina github connector to get a list of repositories under a specified organiztion in 
github, and then pass that list to the ballerina sonarqube connector to get the test line coverage of each repository.
 
## Prerequisites

- Ballerina distribution
- Sonaqube
- A text editor or an IDE such as Intellij IDEA or Eclipse

**Optional requirements**
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), 
[VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), 
[Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)


## Developing the program

### Before you begin
##### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure that you wish. 
Although the language allows you to have any package structure, use the following package structure 
for this project to follow this guide.

```
line-coverage-with-sonarqube-github
├── RepositoryLineCoverageApp
│   ├── RepositoryLineCoverage.bal
│   └── test
│       └── test.bal
├── README.md
├── Ballerina.toml
└── ballerina.conf

```

Package `RepositoryLineCoverageApp` contains the main ballerina program that will use the ballerina 
sonarqube and github connectors to fetch a list of repositories from a github organization and then fetch the 
test line coverage of each of those repositories.


### Implementation

In this section, this guide will walk you through the steps in implementing the above mentioned ballerina program.

The sonarqube and github connectors communicate with their respective APIs in order to obtain the data. 
Since these APIs are protected with authorization tokens, we need to configure both the sonarqube and github connectors 
by providing the respective access tokens.

> In this guide the access tokens are obtained from a configuration file. So provide the sonarqube and github 
access tokens in the 'ballerina.conf' file under the key names SONARQUBE_TOKEN and GITHUB_TOKEN
#### Create a main function
First, lets write the main function inside the 'RepositoryLineCoverage.bal' file. If you are using an IDE, then this will be automatically generated for you. Then let's define a function `getLineCoverageSummary()` to get the test line coverage details.
```ballerina
public function main(string[] args) {
}

function getLineCoverageSummary (int recordCount) returns json|error{
}
```

The implementation of the line coverage function will be as follows;

#### Configure and initialize GitHub client

```ballerina
endpoint github4:Client githubEP {
      accessToken:config:getAsString("GITHUB_TOKEN") ?: "",
        clientEndpointConfiguration: {}
    };
```
Here the github access token is read from the configuration file and the GitHub client is initialized.

#### Configure and initialize Sonarqube client

```ballerina
    endpoint sonarqube6:SonarQubeClient sonarqubeEP {
        token:config:getAsString("SONARQUBE_TOKEN") ?: "",
        uri:"https://wso2.org/sonar"
    };
```
Similarly, the Sonarqube token is read from the configuration file and the Sonarqube client is initialized.

#### Get a github organization

Next, we need to get a specific github organization, in order to get all of its repositories.

```ballerina
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
```
#### Get the list of repositories

```ballerina
    github4:RepositoryList repositoryList;
    var gitRepostoryResult = githubEP -> getOrganizationRepositoryList(organization, 100);
    match gitRepostoryResult {
        github4:RepositoryList repoList => {
            repositoryList = repoList;
        }
        github4:GitConnectorError err => {
            io:println(err);
        }
    }
```

#### Get line coverage of each repository from sonarqube

```ballerina
    foreach repo in repositoryList.getAllRepositories() {
        io:println("Fetching project: " + repo.name);
        var sonarqubeProjectResult = sonarqubeEP -> getProject(repo.name);
        match sonarqubeProjectResult {
            sonarqube6:Project project => {
                string lineCoverage = sonarqubeEP -> getLineCoverage(project.key) but {error err => "0.0%"};
                io:print("Line coverage : ");io:println(lineCoverage);
            }
            error err => {
                io:print("Error : ");io:println(err);
            }
        }
    }
```

Please refer to the [repository_line_coverage.bal](https://github.com/ballerina-guides) for the complete implementation.

## Testing

### Try it out

After the above steps are completed, use the following command to execute the application.

   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run RepositoryLineCoverageApp/
   ```

### Sample output
```bash
...
{"name":"carbon-metrics", "coverage":"85.1%"}
...

```

### Writing unit tests

In Ballerina, the unit test cases should be in the same package and the naming convention should be as follows.
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g., testGetLineCoverageSummary()

This guide contains the unit test case for the `getLineCoverageSummary()` function from 
the `repository_line_coverage.bal`. 

To run the unit test, go to the sample root directory and run the following command.
   ```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina test RepositoryLineCoverageApp/
   ```
   
Refer to the [line_coverage_test.bal](http://github.com) for the implementation of the test file.

## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods listed below. 

### <a name="deploying-on-locally"></a> Deploying locally
You can deploy the services that you developed above in your local environment. You can create the 
Ballerina executable archives (.balx) first and run them in your local environment as follows.

Building 
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina build RepositoryLineCoverageApp/
   ```
   
After build is successful, there will be a `.balx` file inside the target directory. That executable can be 
executed as follows.

Running
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run <Exec_Archive_File_Name>

   ```