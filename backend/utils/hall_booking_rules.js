function hasTimeConflict(bookings, hallName, bookingDate, startTime, endTime) {
  const start = toMinutes(startTime);
  const end = toMinutes(endTime);

  if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start) {
    return true;
  }

  return bookings.some((booking) => {
    if (booking.hall_name !== hallName || booking.booking_date !== bookingDate) {
      return false;
    }

    const existingStart = toMinutes(booking.start_time);
    const existingEnd = toMinutes(booking.end_time);

    if (!Number.isFinite(existingStart) || !Number.isFinite(existingEnd)) {
      return false;
    }

    return start < existingEnd && end > existingStart;
  });
}

function toMinutes(timeValue) {
  if (!timeValue || typeof timeValue !== 'string') {
    return Number.NaN;
  }

  const match = timeValue.match(/^([0-9]{1,2}):([0-9]{2})$/);
  if (!match) {
    return Number.NaN;
  }

  const hour = Number(match[1]);
  const minute = Number(match[2]);

  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return Number.NaN;
  }

  return hour * 60 + minute;
}

module.exports = { hasTimeConflict };
