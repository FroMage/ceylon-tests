import ceylon.io.buffer { Buffer }

import java.nio.channels { SocketChannel { openSocket = open } }
import java.net { InetSocketAddress }
import ceylon.io.impl { SocketImpl }

shared abstract class FileDescriptor() {
    shared formal Integer read(Buffer buffer);
    shared formal Integer write(Buffer buffer);
    shared formal void close();
}

shared class SocketAddress(address, port) {
    shared String address;
    shared Integer port;
}

shared class SocketConnector(SocketAddress addr){
    shared Socket connect(){
        value channel = openSocket(InetSocketAddress(addr.address, addr.port));
        return SocketImpl(channel);
    }
}


shared abstract class Socket() extends FileDescriptor(){
    
}
