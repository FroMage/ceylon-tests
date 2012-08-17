import ceylon.io.buffer { Buffer, newByteBuffer }
import ceylon.io { SocketAddress, SocketConnector }
import ceylon.io.charset { Decoder, utf8 }

String toString(Buffer arr) {
    StringBuilder builder = StringBuilder();
    for(Integer byte in arr){
        builder.appendCharacter(byte.character);
    }
    return builder.string;
}

void copyTo(String string, Buffer buffer){
    for(Character char in string.characters){
        buffer.put(char.integer);
    }
    buffer.flip();
}

void testGrrr(){
    value connector = SocketConnector(SocketAddress("th.wikipedia.org", 80));
    value socket = connector.connect();
    Buffer buffer = newByteBuffer(1024);
    Decoder decoder = utf8.newDecoder();
    // http://th.wikipedia.org/wiki/%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B9%80%E0%B8%82%E0%B9%89%E0%B8%B2%E0%B8%A3%E0%B8%AB%E0%B8%B1%E0%B8%AA%E0%B8%82%E0%B8%99%E0%B8%AA%E0%B9%88%E0%B8%87%E0%B9%80%E0%B8%9B%E0%B9%87%E0%B8%99%E0%B8%8A%E0%B8%B4%E0%B9%89%E0%B8%99%E0%B8%AA%E0%B9%88%E0%B8%A7%E0%B8%99
    // /wiki/Chunked_transfer_encoding
    value url = "/wiki/%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B9%80%E0%B8%82%E0%B9%89%E0%B8%B2%E0%B8%A3%E0%B8%AB%E0%B8%B1%E0%B8%AA%E0%B8%82%E0%B8%99%E0%B8%AA%E0%B9%88%E0%B8%87%E0%B9%80%E0%B8%9B%E0%B9%87%E0%B8%99%E0%B8%8A%E0%B8%B4%E0%B9%89%E0%B8%99%E0%B8%AA%E0%B9%88%E0%B8%A7%E0%B8%99";
    copyTo("GET " url " HTTP/1.1
Host: th.wikipedia.org
User-Agent:Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11

", buffer);
    
    print("Writing request");
    // write the request
    while(buffer.hasAvailable
        && socket.write(buffer) >= 0){
        print("Available: " buffer.available "");
    }
    buffer.clear();
    
    print("Reading response");
    // read the response
    while(socket.read(buffer) >= 0){
        buffer.flip();
        decoder.decode(buffer);
        buffer.clear();
    }
    print(decoder.done());
    socket.close();
}