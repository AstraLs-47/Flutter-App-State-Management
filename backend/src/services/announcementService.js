const Announcement = require('../models/Announcement');

class AnnouncementService {
  async list(page = 1, limit = 20) {
    const offset = (page - 1) * limit;
    const announcements = await Announcement.findActive(limit, offset);
    const total = await Announcement.count();

    return {
      announcements: announcements.map(a => this.formatAnnouncement(a)),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) }
    };
  }

  async getById(id) {
    const announcement = await Announcement.findById(id);
    if (!announcement) {
      const error = new Error('Announcement not found');
      error.statusCode = 404;
      throw error;
    }
    return this.formatAnnouncement(announcement);
  }

  async create(data) {
    const announcement = await Announcement.create(data);
    return this.formatAnnouncement(announcement);
  }

  async update(id, data) {
    const existing = await Announcement.findById(id);
    if (!existing) {
      const error = new Error('Announcement not found');
      error.statusCode = 404;
      throw error;
    }
    const announcement = await Announcement.update(id, data);
    return this.formatAnnouncement(announcement);
  }

  async delete(id) {
    const existing = await Announcement.findById(id);
    if (!existing) {
      const error = new Error('Announcement not found');
      error.statusCode = 404;
      throw error;
    }
    await Announcement.delete(id);
    return { message: 'Announcement deleted successfully' };
  }

  formatAnnouncement(announcement) {
    return {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      priority: announcement.priority,
      isActive: announcement.is_active,
      publishedAt: announcement.published_at,
      expiresAt: announcement.expires_at,
      createdAt: announcement.created_at,
      updatedAt: announcement.updated_at
    };
  }
}

module.exports = new AnnouncementService();