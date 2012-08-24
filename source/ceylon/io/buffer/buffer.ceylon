import ceylon.io.buffer.impl { ByteBufferImpl }

shared abstract class Buffer<T>() satisfies Iterable<T> {
    shared formal Integer position;
    shared formal Integer capacity;
    shared formal Integer limit;

    shared formal void resize(Integer newSize);

    shared default Boolean writable = true;
    
    shared Boolean hasAvailable {
        return available > 0;
    }
    
    shared Integer available {
        return limit - position;
    }
    
    shared formal T get();
    shared formal void put(T element);
    shared formal void clear();
    shared formal void flip();
    
    shared actual Iterator<T> iterator {
        object it satisfies Iterator<T> {
            shared actual T|Finished next() {
                if(hasAvailable){
                    return get();
                }
                return exhausted;
            }
        }
        return it;
    } 
}

shared abstract class ByteBuffer() extends Buffer<Integer>(){
}

shared class CharacterBuffer(String str) extends Buffer<Character>(){
    shared actual Integer capacity = str.size;
    shared variable actual Integer limit := str.size;
    shared variable actual Integer position := 0;

    shared actual Boolean writable = false;

    shared actual void clear() {
        position := 0;
        limit := capacity;
    }

    shared actual void flip() {
        limit := position;
        position := 0;
    }

    shared actual Character get() {
        if(is Character c = str[position++]){
            return c;
        }
        // FIXME: type
        throw Exception("Buffer depleted");
    }

    shared actual void put(Character element) {
        // FIXME: type
        throw Exception("Buffer is read-only");
    }
    
    shared actual void resize(Integer integer) {
        // FIXME: type
        throw Exception("Buffer is read-only");
    }
}

shared CharacterBuffer newCharacterBufferWithData(String data){
    return CharacterBuffer(data);
}

shared ByteBuffer newByteBuffer(Integer capacity){
    return ByteBufferImpl(capacity);
}

shared ByteBuffer newByteBufferWithData(Integer... bytes){
    value seq = bytes.sequence;
    value buf = newByteBuffer(seq.size);
    for(Integer byte in seq){
        buf.put(byte);
    }
    buf.flip();
    return buf;
}
