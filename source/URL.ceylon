
import java.util{ List, ArrayList }

Iterable<String> split(String val, String separators){
    object iterable satisfies Iterable<String>{
        Iterable<String> iterableWithTokens = val.split(separators);
        shared actual Boolean empty = iterableWithTokens.empty;
        shared actual Iterator<String> iterator {
            object iterator satisfies Iterator<String> {
                Iterator<String> withTokens = iterableWithTokens.iterator;
                variable Boolean lastWasToken := true;
                variable Boolean first := true;
                shared actual String|Finished next() {
                    String|Finished next = withTokens.next();
                    switch(next)
                    case (is Finished) {
                        if(first){
                            return exhausted;
                        }
                        first := false;
                        if(lastWasToken){
                            lastWasToken := false;
                            return "";
                        }
                    }
                    case (is String) {
                        first := false;
                        if(next == separators){
                            if(!lastWasToken){
                                lastWasToken := true;
                                // eat up the separator, last token was not a separator 
                                return this.next();
                            }else{
                                // last token was a separator, return an empty token
                                return "";
                            }
                        }
                        lastWasToken := false;
                    }
                    return next;
                }
            }
            return iterator;
        }
    }
    return iterable;
}

shared class Parameter(String initialName, String? initialValue = null) {
    shared variable String name := initialName;
    shared variable String? val := initialValue;
    
    shared actual String string {
        if(exists String val = val){
            return name + "=" + val;
        }else{
            return name;
        }
    }
}

shared class URL(String? url = null){
    shared variable String? scheme := null;
    shared variable String? user := null;
    shared variable String? password := null;
    shared variable String? host := null;
    shared variable String? port := null;
    shared variable Boolean absolutePath := false;
    shared variable String? fragment := null;

    Parameter parseParameter(String part){
        Integer? sep = part.firstCharacterOccurrence(`=`);
        if(exists sep){
            return Parameter(part[0..sep-1], part[sep+1...]);
        }else{
            return Parameter(part);
        }
    }

    shared class PathSegment(String initialName) {
        shared variable String name := initialName;
        shared List<Parameter> parameters = ArrayList<Parameter>();

        shared actual String string {
            if(parameters.empty){
                return name;
            }else{
                StringBuilder b = StringBuilder();
                for(Integer i in 0..parameters.size()-1){
                    if(i > 0){
                        b.appendCharacter(`;`);
                    }
                    b.append(parameters.get(i).string);
                }
                return b.string;
            }
        }
    }

    shared object path {
        shared List<PathSegment> segmentList = ArrayList<PathSegment>();
   
        shared void add(String segment, Parameter... parameters) {
            PathSegment part = PathSegment(segment);
            for(Parameter p in parameters){
                part.parameters.add(p);
            }
            segmentList.add(part);
            if(host exists && segmentList.size() == 1){
                absolutePath := true;
            }
        }
        
        shared void addRawSegment(String part){
            Integer? sep = part.firstCharacterOccurrence(`;`);
            String name;
            if(exists sep){
                name = part[0..sep-1];
            }else{
                name = part;
            }
            PathSegment path = PathSegment(name);
            if(exists sep){
                for(String param in split(part[sep+1...], ";")){
                    path.parameters.add(Parameter(param));
                }
            }
            segmentList.add(path);
        }
        
        shared PathSegment get(Integer i){
            return segmentList.get(i);
        }

        shared PathSegment remove(Integer i){
            return segmentList.remove(i);
        }
                
        shared void clear(){
            segmentList.clear();
        }

        shared actual String string {
            if(segmentList.empty){
                return "";
            }
            StringBuilder b = StringBuilder();
            if(absolutePath){
                b.appendCharacter(`/`);
            }
            for(Integer i in 0..segmentList.size()-1){
                if(i > 0){
                    b.appendCharacter(`/`);
                }
                b.append(segmentList.get(i).string);
            }
            return b.string;
        }
    }

    shared object query {
        shared List<Parameter> queryParameters = ArrayList<Parameter>();
        
        shared void addRaw(String part){
            add(Parameter(part));
        }

        shared void add(Parameter param){
            queryParameters.add(param);
        }

        shared actual String string {
            if(queryParameters.empty){
                return "";
            }
            StringBuilder b = StringBuilder();
            for(Integer i in 0..queryParameters.size()-1){
                if(i > 0){
                    b.appendCharacter(`&`);
                }
                b.append(queryParameters.get(i).string);
            }
            return b.string;
        }
    }
    
    String parseScheme(String url){
        Integer? sep = url.firstOccurrence(":");
        if(exists sep){
            if(sep > 0){
                scheme := url[0..sep-1];
                return url[sep+1...];
            }
        }
        // no scheme, it must be relative
        return url;
    }

    void parseUserInfo(String userInfo) {
        Integer? sep = userInfo.firstCharacterOccurrence(`:`);
        if(exists sep){
            user := userInfo[0..sep-1];
            password := userInfo[sep+1...];
        }else{
            user := userInfo;
            password := null;
        }
    }

    void parseHostAndPort(String hostAndPort) {
        Integer? sep = hostAndPort.lastCharacterOccurrence(`:`);
        if(exists sep){
            host := hostAndPort[0..sep-1];
            port := hostAndPort[sep+1...];
        }else{
            host := hostAndPort;
            port := null;
        }
    }
    
    String parseAuthority(String url){
        if(!url.startsWith("//")){
            return url;
        }
        // eat the to slashes
        String part = url[2...];
        Integer? sep = part.firstCharacterOccurrence(`/`) 
            else part.firstCharacterOccurrence(`?`)
            else part.firstCharacterOccurrence(`#`);
        String authority;
        String remains;
        if(exists sep){
            authority = part[0..sep-1];
            remains = part[sep...];
        }else{
            // no path part
            authority = part;
            remains = "";
        }
        Integer? userInfoSep = authority.firstCharacterOccurrence(`@`);
        String hostAndPort;
        if(exists userInfoSep){
            parseUserInfo(authority[0..userInfoSep-1]);
            hostAndPort = authority[userInfoSep+1...]; 
        }else{
            hostAndPort = authority;
        }
        parseHostAndPort(hostAndPort);
        return remains;
    }

    String parsePath(String url){
        Integer? sep = url.firstCharacterOccurrence(`?`) else url.firstCharacterOccurrence(`#`);
        String pathPart;
        String remains;
        if(exists sep){
            pathPart = url[0..sep-1];
            remains = url[sep...];
        }else{
            // no query/fragment part
            pathPart = url;
            remains = "";
        }
        absolutePath := false;
        variable Boolean first := true;
        for(String part in split(pathPart, "/")){
            if(first && part.empty){
                absolutePath := true;
                first := false;
                continue;
            }
            first := false;
            path.addRawSegment(part);
        }
        
        return remains;
    }

    void parseQueryPart(String queryPart) {
        for(String part in split(queryPart, "&")){
            query.addRaw(part);
        }
    }

    String parseQuery(String url){
        Character? c = url[0];
        if(exists c){
            if(c == `?`){
                // we have a query part
                Integer end = url.firstCharacterOccurrence(`#`) else url.size;
                parseQueryPart(url[1..end-1]);
                return url[end...];
            }
        }
        // no query/fragment part
        return url;
    }

    String parseFragment(String url){
        Character? c = url[0];
        if(exists c){
            if(c == `#`){
                // we have a fragment part
                fragment := url[1...];
                return "";
            }
        }
        // no query/fragment part
        return url;
    }
    
    void parseURL(String url) {
        variable String remains := parseScheme(url);
        remains := parseAuthority(remains);
        remains := parsePath(remains);
        remains := parseQuery(remains);
        remains := parseFragment(remains);
    }

    if(exists url){
        parseURL(url);
    }

    shared String authority {
        if(exists String host = host){
            StringBuilder b = StringBuilder();
            if(exists String user = user){
                b.append(user);
                if(exists String password = password){
                    b.appendCharacter(`:`);
                    b.append(password);
                }
                b.appendCharacter(`@`);
            }
            b.append(host);
            if(exists String port = port){
                b.appendCharacter(`:`);
                b.append(port);
            }
            return b.string;
        }
        return "";
    }

    shared Boolean relative {
        return !exists scheme;
    }

    shared actual String string {
        return "URL[relative: " relative
            " scheme: '" scheme ? ""
            "' authority: '" authority
            "' path: '" path
            "' query: '" query
            "' fragment: '" fragment ? ""
            "'";
    }
}

shared void testURL(){
    //for(String s in split("", "/")){
    //    print("Token: " s "");
    //}
    //print("SEP");
    //for(String s in split("/", "/")){
    //    print("Token: " s "");
    //}
    //print("SEP");
    //for(String s in split("a/b", "/")){
    //    print("Token: " s "");
    //}
    print(URL("http://user:pass@www.foo.com:port/path/to;param1;param2=foo/file.html?foo=bar&foo=gee&bar#anchor").string);
    print(URL("http://host").string);
    print(URL("http://host/").string);
    print(URL("http://host?foo").string);
    print(URL("http://host#foo").string);
    print(URL("http://user@host").string);
    print(URL("http://host:port").string);
    print(URL("file:///no/host").string);
    print(URL("file:///").string);
    print(URL("mailto:stef@epardaud.fr").string);
    print(URL("//host/file").string);
    print(URL("/path/somewhere").string);
    print(URL("someFile").string);
    print(URL("?query").string);
    print(URL("#anchor").string);
    URL u = URL();
    print(u.string);
    u.scheme := "http";
    print(u.string);
    u.host := "192.168.1.1";
    u.port := "9000";
    u.user := "stef";
    print(u.string);
    u.path.add("a");
    u.path.add("b", Parameter("c"), Parameter("d", "e"));
    print(u.string);
    u.query.add(Parameter("q"));
    u.query.add(Parameter("r","s"));
    print(u.string);
    print(urlEncoder.escape("stéf/?"));
}
