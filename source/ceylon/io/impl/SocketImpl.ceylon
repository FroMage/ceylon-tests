import ceylon.io.buffer { Buffer }
import ceylon.io.buffer.impl { ByteBufferImpl }
import ceylon.io { Socket }

import java.nio.channels { SocketChannel }

shared class SocketImpl(SocketChannel channel) extends Socket() {
    shared actual void close() {
        channel.close();
    }
    shared actual Integer read(Buffer buffer) {
        if(is ByteBufferImpl buffer){
            return channel.read(buffer.buf);
        }
        throw;
    }
    shared actual Integer write(Buffer buffer) {
        if(is ByteBufferImpl buffer){
            return channel.write(buffer.buf);
        }
        throw;
    }
}