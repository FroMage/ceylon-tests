import ceylon.io.buffer { newByteBuffer, ByteBuffer, CharacterBuffer, newCharacterBufferWithData }

shared interface Charset {
    shared formal Decoder newDecoder();
    shared formal String name;
    
    shared formal Encoder newEncoder();
    
    shared formal Integer minimumBytesPerCharacter;
    shared default Integer maximumBytesPerCharacter {
        return minimumBytesPerCharacter;
    }
    shared default Integer averageBytesPerCharacter {
        return (maximumBytesPerCharacter - minimumBytesPerCharacter) / 2 + minimumBytesPerCharacter;
    }
    
    shared ByteBuffer encode(String string){
        value output = newByteBuffer(string.size * averageBytesPerCharacter);
        value input = newCharacterBufferWithData(string);
        value encoder = newEncoder();
        while(input.hasAvailable){
            // grow the output buffer if our estimate turned out wrong
            if(!output.hasAvailable){
                output.resize(string.size * maximumBytesPerCharacter);
            }
            encoder.encode(input, output);
        }
        // flip and return
        output.flip();
        return output;
    }
    
    shared String decode(ByteBuffer buffer){
        value decoder = newDecoder();
        decoder.decode(buffer);
        return decoder.done();
    }
}

shared interface Encoder {
    shared formal Charset charset;
    shared formal void encode(CharacterBuffer input, ByteBuffer output);
}

shared interface Decoder {
    shared formal Charset charset;
    shared formal void decode(ByteBuffer buffer);
    shared formal String? consumeAvailable();
    shared formal String done();
}

shared Charset[] charsets = { ascii, iso_8859_1, utf8, utf16 };

abstract class AbstractDecoder() satisfies Decoder{
    shared StringBuilder builder = StringBuilder();

    shared actual String? consumeAvailable() {
        // consume all we have without checking for missing things
        if(builder.size > 0){
            value ret = builder.string;
            builder.reset();
            return ret;
        }else{
            return null;
        }
    }
    
    default shared actual String done() {
        value ret = builder.string;
        builder.reset();
        return ret;
    }
}

class ASCIIDecoder(charset) extends AbstractDecoder() {
    shared actual Charset charset;

    shared actual void decode(ByteBuffer buffer) {
        for(Integer byte in buffer){
            if(byte < 0 || byte > 127){
                // FIXME: type
                throw Exception("Invalid ASCII byte value: " byte "");
            }
            builder.appendCharacter(byte.character);
        }
    }
}

class ASCIIEncoder(charset) satisfies Encoder {
    shared actual Charset charset;
    
    shared actual void encode(CharacterBuffer input, ByteBuffer output) {
        // give up if there's no input or no room for output
        while(input.hasAvailable && output.hasAvailable){
            value char = input.get().integer;
            if(char > 127){
                // FIXME: type
                throw Exception("Invalid ASCII byte value: " char "");
            }
            output.put(char);
        }
    }

}

shared object ascii satisfies Charset {
    shared actual String name = "ASCII";
    shared actual Integer minimumBytesPerCharacter = 1;
    shared actual Integer maximumBytesPerCharacter = 1;
    shared actual Integer averageBytesPerCharacter = 1;

    shared actual Decoder newDecoder(){
        return ASCIIDecoder(this);
    }
    shared actual Encoder newEncoder() {
        return ASCIIEncoder(this);
    }
}


class ISO_8859_1Decoder(charset) extends AbstractDecoder()  {
    shared actual Charset charset;
    
    shared actual void decode(ByteBuffer buffer) {
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
    shared actual Integer minimumBytesPerCharacter = 1;
    shared actual Integer maximumBytesPerCharacter = 1;
    shared actual Integer averageBytesPerCharacter = 1;

    shared actual Decoder newDecoder(){
        return ISO_8859_1Decoder(this);
    }
    shared actual Encoder newEncoder() {
        // FIXME
        return bottom;
    }
}

class UTF8Decoder(charset) extends AbstractDecoder()  {
    shared actual Charset charset;
    
    variable Integer needsMoreBytes := 0;
    ByteBuffer bytes = newByteBuffer(3);
    variable Boolean byteOrderMarkSeen := false;
    
    shared actual String done() {
        if(needsMoreBytes > 0){
            // type
            throw Exception("Invalid UTF-8 sequence: missing " needsMoreBytes " bytes");
        }
        return super.done();
    }
    
    shared actual void decode(ByteBuffer buffer) {
        for(Integer byte in buffer){
            if(byte < 0 || byte > 255){
                // FIXME: type
                throw Exception("Invalid UTF-8 byte value: " byte "");
            }
            // are we looking at the first byte?
            if(needsMoreBytes == 0){
                // 0b0000 0000 <= byte < 0b1000 0000
                if(byte < hex('80')){
                    // one byte
                    builder.appendCharacter(byte.character);
                    continue;
                }
                // invalid range
                if(byte < bin('11000000')){
                    // FIXME: type
                    throw Exception("Invalid UTF-8 byte value: " byte "");
                }
                // invalid range
                if(byte >= bin('11111000')){
                    throw Exception("Invalid UTF-8 first byte value: " byte "");
                }
                // keep this byte in any case
                bytes.put(byte);
                if(byte < bin('11100000')){
                    needsMoreBytes := 1;
                    continue;
                }
                if(byte < bin('11110000')){
                    needsMoreBytes := 2;
                    continue;
                }
                // 0b1111 0000 <= byte < 0b1111 1000
                if(byte < bin('11111000')){
                    needsMoreBytes := 3;
                    continue;
                }
            }
            // if we got this far, we must have a second byte at least
            if(byte < bin('10000000') || byte >= bin('11000000')){
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
                Integer part1 = bytes.get().and(bin('00011111'));
                Integer part2 = byte.and(bin('00111111'));
                char = part1.leftLogicalShift(6)
                    .or(part2);
            }else if(bytes.available == 2){
                Integer part1 = bytes.get().and(bin('00001111'));
                Integer part2 = bytes.get().and(bin('00111111'));
                Integer part3 = byte.and(bin('00111111'));
                char = part1.leftLogicalShift(12)
                    .or(part2.leftLogicalShift(6))
                    .or(part3);
            }else{
                Integer part1 = bytes.get().and(bin('00000111'));
                Integer part2 = bytes.get().and(bin('00111111'));
                Integer part3 = bytes.get().and(bin('00111111'));
                Integer part4 = byte.and(bin('00111111'));
                char = part1.leftLogicalShift(18)
                    .or(part2.leftLogicalShift(12))
                    .or(part3.leftLogicalShift(6))
                    .or(part4);
            }
            // 0xFEFF is the Byte Order Mark in UTF8
            if(char == hex('FEFF') && builder.size == 0 && !byteOrderMarkSeen){
                byteOrderMarkSeen := true;
            }else{
                builder.appendCharacter(char.character);
            }
            // needsMoreBytes is already 0
            // bytes needs to be reset
            bytes.clear();
        }
    }
}

shared object utf8 satisfies Charset {
    shared actual String name = "UTF-8";
    shared actual Integer minimumBytesPerCharacter = 1;
    shared actual Integer maximumBytesPerCharacter = 4;
    shared actual Integer averageBytesPerCharacter = 2;

    shared actual Decoder newDecoder(){
        return UTF8Decoder(this);
    }
    shared actual Encoder newEncoder() {
        // FIXME
        return bottom;
    }
}

class UTF16Decoder(charset) extends AbstractDecoder()  {
    shared actual Charset charset;
    
    variable Boolean needsMoreBytes := false;
    variable Integer firstByte := 0;

    variable Boolean needsLowSurrogate := false;
    variable Integer highSurrogate := 0;
    
    variable Boolean bigEndian := true;

    variable Boolean byteOrderMarkSeen := false;
    
    shared actual String done() {
        if(needsMoreBytes){
            // FIXME: type
            throw Exception("Invalid UTF-16 sequence: missing a byte");
        }
        if(needsLowSurrogate){
            // FIXME: type
            throw Exception("Invalid UTF-16 sequence: missing low surrogate");
        }
        return super.done();
    }
    
    Integer assembleBytes(Integer a, Integer b) { 
        if(bigEndian){
            return a.leftLogicalShift(8).or(b);
        }else{
            return a.or(b.leftLogicalShift(8));
        }
    }
    
    shared actual void decode(ByteBuffer buffer) {
        for(Integer byte in buffer){
            if(byte < 0 || byte > 255){
                // FIXME: type
                throw Exception("Invalid UTF-16 byte value: " byte "");
            }
            // are we looking at the first byte of a 16-bit word?
            if(!needsMoreBytes){
                // keep this byte in any case
                firstByte := byte;
                needsMoreBytes := true;
                continue;
            }
            // are we looking at the second byte?
            if(needsMoreBytes){
                Integer char;
                
                // assemble the two bytes
                Integer word = assembleBytes(firstByte, byte);
                needsMoreBytes := false;
                
                // are we looking at the first 16-bit word?
                if(!needsLowSurrogate){
                    // Single 16bit value
                    if(word < hex('D800') || word > hex('DFFF')){
                        // we got the char
                        char = word;
                    }else if(word > hex('DBFF')){
                        // FIXME: type
                        throw Exception("Invalid UTF-16 high surrogate value: " word "");
                    }else{
                        // we're waiting for the second half;
                        highSurrogate := word;
                        needsLowSurrogate := true;
                        continue;
                    }
                }else{
                    // we have the second 16-bit word, check it
                    if(word < hex('DC00') || word > hex('DFFF')){
                        // FIXME: type
                        throw Exception("Invalid UTF-16 low surrogate value: " word "");
                    }
                    // now assemble them
                    Integer part1 = highSurrogate.and(bin('1111111111')).leftLogicalShift(10);
                    Integer part2 = word.and(bin('1111111111'));
                    char = part1.or(part2) + (hex('10000'));
                    
                    needsLowSurrogate := false; 
                }

                // 0xFEFF is the Byte Order Mark in UTF8
                if(char == hex('FEFF') && builder.size == 0 && !byteOrderMarkSeen){
                    byteOrderMarkSeen := true;
                }else if(char == hex('FFFE') && builder.size == 0 && !byteOrderMarkSeen){
                    byteOrderMarkSeen := true;
                    bigEndian := false;
                }else{
                    builder.appendCharacter(char.character);
                }
            }
        }
    }
}

shared object utf16 satisfies Charset {
    shared actual String name = "UTF-16";
    
    shared actual Integer minimumBytesPerCharacter = 2;
    shared actual Integer maximumBytesPerCharacter = 4;
    shared actual Integer averageBytesPerCharacter = 2;

    shared actual Decoder newDecoder(){
        return UTF16Decoder(this);
    }
    shared actual Encoder newEncoder() {
        // FIXME
        return bottom;
    }
}
