function key(studentId, subject = '') {
  return `${studentId}\u0000${subject}`;
}

function buildFeeFeatures(students, challans, attendance, now = new Date()) {
  const challansByStudent = new Map();
  const attendanceByStudent = new Map();
  for (const row of challans) {
    if (!challansByStudent.has(row.studentId)) challansByStudent.set(row.studentId, []);
    challansByStudent.get(row.studentId).push(row);
  }
  for (const row of attendance) {
    if (!attendanceByStudent.has(row.studentId)) attendanceByStudent.set(row.studentId, []);
    attendanceByStudent.get(row.studentId).push(row);
  }
  const rows = new Map();
  for (const studentId of students) {
    const history = challansByStudent.get(studentId) || [];
    const paid = history.filter((item) => item.status === 'PAID' && item.paidAt && new Date(item.paidAt) < now);
    const delays = paid.map((item) => Math.max(0, (new Date(item.paidAt) - new Date(item.dueDate)) / 86400000));
    const attended = attendanceByStudent.get(studentId) || [];
    const presentCount = attended.filter((item) => ['PRESENT', 'LATE'].includes(item.status)).length;
    rows.set(studentId, {
      attendance_pct: attended.length ? 100 * presentCount / attended.length : null,
      late_count: delays.filter((days) => days > 0).length,
      delay_avg: delays.length ? delays.reduce((sum, value) => sum + value, 0) / delays.length : 0,
      consistency: paid.length ? delays.filter((days) => days === 0).length / paid.length : null,
      outstanding: history.filter((item) => item.status !== 'PAID' || !item.paidAt || new Date(item.paidAt) >= now)
        .reduce((sum, item) => sum + Number(item.totalAmount), 0),
    });
  }
  return rows;
}

function buildPerformanceFeatures(marks, attendance) {
  const groups = new Map();
  const attendanceByStudent = new Map();
  for (const row of attendance) {
    if (!attendanceByStudent.has(row.studentId)) attendanceByStudent.set(row.studentId, []);
    attendanceByStudent.get(row.studentId).push(row);
  }
  for (const mark of marks) {
    const groupKey = key(mark.studentId, mark.subject);
    if (!groups.has(groupKey)) groups.set(groupKey, { studentId: mark.studentId, subject: mark.subject, values: [] });
    groups.get(groupKey).values.push(Number(mark.percentage));
  }
  return [...groups.values()].map((group) => {
    const attended = attendanceByStudent.get(group.studentId) || [];
    const presentCount = attended.filter((item) => ['PRESENT', 'LATE'].includes(item.status)).length;
    return {
      studentId: group.studentId,
      subject: group.subject,
      features: {
        prior_avg: group.values.reduce((sum, value) => sum + value, 0) / group.values.length,
        prior_count: group.values.length,
        attendance_pct: attended.length ? 100 * presentCount / attended.length : null,
      },
    };
  });
}

module.exports = { buildFeeFeatures, buildPerformanceFeatures };
