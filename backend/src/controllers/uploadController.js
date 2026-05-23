class UploadController {
  uploadImage(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No image file uploaded' });
      }

      const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
      res.status(201).json({ imageUrl });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UploadController();
