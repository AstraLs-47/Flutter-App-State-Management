const announcementService = require('../services/announcementService');

class AnnouncementController {
  async list(req, res, next) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const result = await announcementService.list(parseInt(page), parseInt(limit));
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const announcement = await announcementService.getById(parseInt(req.params.id));
      res.json(announcement);
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const { title, description, content, priority, date, expiresAt } = req.body;
      const bodyContent = content || description;
      if (!title || !bodyContent) {
        return res.status(400).json({ error: 'Title and description are required' });
      }
      const announcement = await announcementService.create({ 
        title, 
        content: bodyContent, 
        priority, 
        date, 
        expiresAt,
        created_by: req.user.id 
      });
      res.status(201).json(announcement);
    } catch (error) {
      next(error);
    }
  }

  async update(req, res, next) {
    try {
      const { title, description, content, priority, isActive, expiresAt, date } = req.body;
      const bodyContent = content || description;
      const announcement = await announcementService.update(parseInt(req.params.id), {
        title, 
        content: bodyContent, 
        priority, 
        isActive, 
        expiresAt, 
        date
      });
      res.json(announcement);
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      const result = await announcementService.delete(parseInt(req.params.id));
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AnnouncementController();