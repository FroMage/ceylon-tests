import ceylon.io.buffer { Buffer, newByteBuffer }

shared interface Charset {
    shared formal Decoder newDecoder();
    shared formal String name;
    
    shared String decode(Buffer buffer){
        value decoder = newDecoder();
        decoder.decode(buffer);
        return decoder.done();
    }
}

shared interface Decoder {
    shared formal Charset charset;
    shared formal void decode(Buffer buffer);
    shared formal String done();
}

shared Charset[] charsets = { ascii, iso_8859_1, utf8 };

abstract class AbstractDecoder() satisfies Decoder{
    shared StringBuilder builder = StringBuilder();

    
    default shared actual String done() {
        value ret = builder.string;
        builder.reset();
        return ret;
    }
} 

class ASCIIDecoder(charset) extends AbstractDecoder() {
    shared actual Charset charset;

    shared actual void decode(Buffer buffer) {
        for(Integer byte in buffer){
            if(byte < 0 || byte > 127){
                // FIXME: type
                throw Exception("Invalid ASCII byte value: " byte "");
            }
            builder.appendCharacter(byte.character);
        }
    }
}

shared object ascii satisfies Charset {
    shared actual String name = "ASCII";
    shared actual Decoder newDecoder(){
        return ASCIIDecoder(this);
    }
}


class ISO_8859_1Decoder(charset) extends AbstractDecoder()  {
    shared actual Charset charset;
    
    shared actual void decode(Buffer buffer) {
        for(Integer byte in buffer){
            if(byte < 0 || byte > 255){
                // FIXME: type
                throw Exception("Invalid ISO_8859-1 byte value: " byte "");
            }
            builder.appendCharacter(byte.character);
        }
    }
}

shared object iso_8859_1 satisfies Charset {
    shared actual String name = "ISO_8859-1";
    shared actual Decoder newDecoder(){
        return ISO_8859_1Decoder(this);
    }
}

class UTF8Decoder(charset) extends AbstractDecoder()  {
    shared actual Charset charset;
    
    variable Integer needsMoreBytes := 0;
    Buffer bytes = newByteBuffer(3);
    
    shared actual String done() {
        if(needsMoreBytes > 0){
            // type
            throw Exception("Invalid UTF-8 sequence: missing " needsMoreBytes " bytes");
        }
        return super.done();
    }
    
    shared actual void decode(Buffer buffer) {
        for(Integer byte in buffer){
            if(byte < 0 || byte > 255){
                // FIXME: type
                throw Exception("Invalid UTF-8 byte value: " byte "");
            }
            // are we looking at the first byte?
            if(needsMoreBytes == 0){
                // 0b0000 0000 <= byte < 0b1000 0000
                if(byte < 128){
                    // one byte
                    builder.appendCharacter(byte.character);
                    continue;
                }
                // invalid range: 0b1000 0000 <= byte < 0b1100 0000
                if(byte < 192){
                    // FIXME: type
                    throw Exception("Invalid UTF-8 byte value: " byte "");
                }
                // invalid range: byte >= 0b1111 1000
                if(byte >= 248){
                    throw Exception("Invalid UTF-8 first byte value: " byte "");
                }
                // keep this byte in any case
                bytes.put(byte);
                // 0b1100 0000 <= byte < 0b1110 0000
                if(byte < 224){
                    needsMoreBytes := 1;
                    continue;
                }
                // 0b1110 0000 <= byte < 0b1111 0000
                if(byte < 240){
                    needsMoreBytes := 2;
                    continue;
                }
                // 0b1111 0000 <= byte < 0b1111 1000
                if(byte < 248){
                    needsMoreBytes := 3;
                    continue;
                }
            }
            // if we got this far, we must have a second byte at least
            if(byte < 128 || byte >= 192){
                // FIXME: type
                throw Exception("Invalid UTF-8 second byte value: " byte "");
            }
            if(--needsMoreBytes > 0){
                // not enough bytes
                bytes.put(byte);
                continue;
            }
            // we have enough bytes! they are all in the bytes buffer except the last one
            // they have all been checked already
            bytes.flip();
            Integer char;
            if(bytes.available == 1){
                // byte & 0b1100 0000
                Integer part1 = bytes.get() - 192;
                // byte2 & 0b1000 0000
                Integer part2 = byte - 128;
                // part << 6 + part2 
                char = part1 * 64 + part2;
            }else if(bytes.available == 2){
                // byte & 0b1110 0000
                Integer part1 = bytes.get() - 224;
                // byte2 & 0b1000 0000
                Integer part2 = bytes.get() - 128;
                // byte3 & 0b1000 0000
                Integer part3 = byte - 128;
                // part << 12 + part2 << 6 + part3
                char = part1 * 4096 + part2 * 64 + part3;
            }else{
                // byte & 0b1111 0000
                Integer part1 = bytes.get() - 240;
                // byte2 & 0b1000 0000
                Integer part2 = bytes.get() - 128;
                // byte3 & 0b1000 0000
                Integer part3 = bytes.get() - 128;
                // byte4 & 0b1000 0000
                Integer part4 = byte - 128;
                // part << 18 + part2 << 12 + part3 << 6 + part4
                char = part1 * 262144 + part2 * 4096 + part3 * 64 + part4;
            }
            builder.appendCharacter(char.character);
            // needsMoreBytes is already 0
            // bytes needs to be reset
            bytes.clear();
        }
    }
}

shared object utf8 satisfies Charset {
    shared actual String name = "UTF-8";
    shared actual Decoder newDecoder(){
        return UTF8Decoder(this);
    }
}
