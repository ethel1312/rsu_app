export const jsonArray = (value) => Array.isArray(value) ? value : JSON.parse(value || '[]');
export function limaNow(now = new Date()) {
  const parts = Object.fromEntries(new Intl.DateTimeFormat('sv-SE', {
    timeZone: 'America/Lima', year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23',
  }).formatToParts(now).map(({ type, value }) => [type, value]));
  return { date: `${parts.year}-${parts.month}-${parts.day}`, time: `${parts.hour}:${parts.minute}:${parts.second}` };
}

export function runsOn(schedule, date) {
  const day = new Date(`${date}T12:00:00Z`).getUTCDay() || 7;
  return schedule.status !== 'Finalizada' && date >= schedule.start_date && date <= schedule.end_date &&
    !jsonArray(schedule.excluded_dates).includes(date) && jsonArray(schedule.days_of_week).map(Number).includes(day);
}

export function serviceDate(schedule, today) {
  let date = schedule.start_date > today ? schedule.start_date : today;
  // Como máximo 7 días más las exclusiones: evita recorrer intervalos históricos completos.
  const limit = 7 + jsonArray(schedule.excluded_dates).length;
  for (let index = 0; index <= limit && date <= schedule.end_date; index++) {
    if (runsOn(schedule, date)) return date;
    const next = new Date(`${date}T12:00:00Z`);
    next.setUTCDate(next.getUTCDate() + 1);
    date = next.toISOString().slice(0, 10);
  }
  return null;
}

export function publicSchedule(schedule, date, plate = '') {
  return {
    id: schedule.id, service_date: date, zone: schedule.zone_name,
    vehicle: schedule.vehicle_label, plate,
    shift: `${schedule.shift_name} (${schedule.shift_start_time.slice(0, 5)} - ${schedule.shift_end_time.slice(0, 5)})`,
    days: jsonArray(schedule.days_of_week).map(day => ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][Number(day)]).join(', '),
  };
}
