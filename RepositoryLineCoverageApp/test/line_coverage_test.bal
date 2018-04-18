import ballerina/log;
import ballerina/test;

@test:Config
function testGetLineCoverageSummary () {
    log:printInfo("getLineCoverageSummary()");
    int recordCount = 5;
    var result = getLineCoverageSummary(recordCount);
    match result {
        json jsonResult => {
            test:assertEquals(lengthof jsonResult, recordCount, msg = "Record count mismatch in result");
        }
        error err => {
            test:assertFail(msg = "Function returned an error");
        }
    }

}