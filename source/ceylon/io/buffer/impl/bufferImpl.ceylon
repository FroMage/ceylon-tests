import java.nio { JavaByteBuffer = ByteBuffer { allocateJavaByteBuffer = allocate }}
import ceylon.io.buffer { Buffer }

Boolean needsWorkarounds = true;

shared class ByteBufferImpl(capacity) extends Buffer(){
    shared JavaByteBuffer buf = allocateJavaByteBuffer(capacity);
    
    shared actual Integer capacity;
    shared actual Integer limit {
        return buf.limit();
    }
    shared actual Integer position {
        return buf.position();
    }
    shared actual Integer get() {
        return signedByteToUnsigned(buf.get());
    }
    shared actual void put(Integer byte) {
        buf.put(unsignedByteToSigned(byte));
    }
    shared actual void reset() {
        buf.reset();
    }
    shared actual void clear() {
        buf.clear();
    }
    shared actual void flip() {
        buf.flip();
    }
    Integer signedByteToUnsigned(Integer b) { 
        if(needsWorkarounds && b < 0){
            return b + 256;
        }
        return b;
    }
    
    Integer unsignedByteToSigned(Integer b) { 
        if(needsWorkarounds && b > 127){
            return b - 256;
        }
        return b;
    }
}

