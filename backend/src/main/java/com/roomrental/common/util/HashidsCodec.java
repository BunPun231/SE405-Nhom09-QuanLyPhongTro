package com.roomrental.common.util;

import org.hashids.Hashids;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class HashidsCodec {

    private final Hashids hashids;

    public HashidsCodec(@Value("${app.hashids.salt:room-rental-secret}") String salt,
                        @Value("${app.hashids.min-length:8}") int minLength) {
        this.hashids = new Hashids(salt, minLength);
    }

    public String encode(Long id) {
        if (id == null) return null;
        return hashids.encode(id);
    }

    public Long decode(String hash) {
        if (hash == null) return null;
        long[] vals = hashids.decode(hash);
        if (vals == null || vals.length == 0) return null;
        return vals[0];
    }
}
