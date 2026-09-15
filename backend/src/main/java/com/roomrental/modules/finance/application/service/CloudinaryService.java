package com.roomrental.modules.finance.application.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.Map;

@Service
public class CloudinaryService {

    private final Cloudinary cloudinary;

    public CloudinaryService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    public String uploadImage(byte[] imageBytes, String folder) throws IOException {
        Map params = ObjectUtils.asMap(
                "folder", folder,
                "resource_type", "image"
        );
        Map result = cloudinary.uploader().upload(imageBytes, params);
        return (String) result.get("secure_url");
    }
}
