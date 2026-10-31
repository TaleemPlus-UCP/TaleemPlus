const prisma = require('../config/db');

const getNotifications = async (req, res, next) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: {
        academyId: req.academyId,
        recipientId: req.user.id
      },
      orderBy: { createdAt: 'desc' }
    });

    const formatted = notifications.map((n) => ({
      id: n.id,
      academy_id: n.academyId,
      recipient_id: n.recipientId,
      title: n.title,
      message: n.message,
      type: n.type,
      is_read: n.isRead,
      created_at: n.createdAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const markNotificationRead = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updated = await prisma.notification.updateMany({
      where: { id, recipientId: req.user.id },
      data: { isRead: true }
    });

    res.json({ success: true, message: 'Notification marked as read.', data: updated });
  } catch (err) {
    next(err);
  }
};

const getAnnouncements = async (req, res, next) => {
  try {
    const announcements = await prisma.announcement.findMany({
      where: { academyId: req.academyId },
      include: { createdBy: { select: { fullName: true } } },
      orderBy: { createdAt: 'desc' }
    });

    const formatted = announcements.map((a) => ({
      id: a.id,
      academy_id: a.academyId,
      title: a.title,
      message: a.message,
      target_roles: a.targetRoles,
      created_by_uid: a.createdById,
      created_by_name: a.createdBy.fullName,
      created_at: a.createdAt,
      updated_at: a.updatedAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const createAnnouncement = async (req, res, next) => {
  try {
    const { title, message, targetRoles } = req.body;

    if (!title || !message) {
      return res.status(400).json({ success: false, message: 'Title and message are required.' });
    }

    const announcement = await prisma.announcement.create({
      data: {
        academyId: req.academyId,
        title,
        message,
        targetRoles: targetRoles || ['all'],
        createdById: req.user.id
      }
    });

    res.status(201).json({ success: true, message: 'Announcement created successfully.', data: announcement });
  } catch (err) {
    next(err);
  }
};

module.exports = { getNotifications, markNotificationRead, getAnnouncements, createAnnouncement };
