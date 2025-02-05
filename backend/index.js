const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const IMAGE_DIR = "/Users/skylerdevlaming/FaceRecognition/backend/uploads/"

const app = express();
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/'); // Save files in the 'uploads' directory
    },
    filename: function (req, file, cb) {
        const ext = path.extname(file.originalname); // Get file extension
        const safeFilename = path.basename(file.originalname, ext).replace(/\s+/g, '_'); // Remove spaces
        cb(null, safeFilename + ext); // Preserve extension
    }
});

const upload = multer({ storage: storage });

app.put('/upload', upload.single('photo'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }
    res.json({ message: 'File uploaded successfully', filename: req.file.filename });
});

app.get('/download/:filename', (req, res) => {
    const filename = req.params.filename;
    const filePath = path.join(IMAGE_DIR, filename);

    console.log(`Looking for file: ${filePath}`);

    fs.access(filePath, fs.constants.F_OK, (err) => {
        if (err) {
            console.error(`File not found: ${filePath}`);
            return res.status(404).json({ error: "File not found" });
        }

        res.sendFile(filePath);
    });
});

app.listen(3000, () => console.log('Server running on port 3000'));