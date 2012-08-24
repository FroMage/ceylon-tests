variable Integer assertions := 0;
variable Integer successes := 0;

void assertEquals(Void expected, Void val){
    assertions++;
    if(exists expected){
        if(exists val){
            if(expected != val){
                throw Exception("Assertion failed. Expecting " expected " but got " val "");
            }
        }else{
            throw Exception("Assertion failed. Expecting " expected " but got null");
        }
    }else{
        if(exists val){
            throw Exception("Assertion failed. Expecting null but got " val "");
        }
    }
    successes++;
}

void printTestResults(){
    if(assertions == successes){
        print("Ran " assertions " assertions with SUCCESS");
    }else{
        print("" (assertions-successes) " tests FAILED out of " assertions "");
    }
}