void assertEquals(Void expected, Void val){
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
}


