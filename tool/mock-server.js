/**
 * Учебный REST API автосалона. Node.js 18, без внешних пакетов.
 * node tool/mock-server.js --port 8081 --origin http://127.0.0.1:5560
 */
const crypto = require('crypto');
const http = require('http');
const { URL } = require('url');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const index = args.indexOf(name);
  return index >= 0 && args[index + 1] ? args[index + 1] : fallback;
}
const port = Number(arg('--port', '8081'));
const originArg = arg('--origin', 'http://127.0.0.1:5560');
const ttlSeconds = Number(arg('--ttl', '900'));
const tokenSecret = 'salon-pr5-secret';

function originsOf(value) {
  const set = new Set([value]);
  try {
    const url = new URL(value);
    const other = url.hostname === 'localhost' ? '127.0.0.1' : url.hostname === '127.0.0.1' ? 'localhost' : null;
    if (other) {
      url.hostname = other;
      set.add(url.origin);
    }
  } catch (_) {}
  return set;
}
const allowedOrigins = originsOf(originArg);

function isAllowedOrigin(origin) {
  if (allowedOrigins.has(origin)) return true;
  try {
    const url = new URL(origin);
    return url.protocol === 'http:' && (url.hostname === 'localhost' || url.hostname === '127.0.0.1');
  } catch (_) {
    return false;
  }
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  return { salt, hash: crypto.scryptSync(password, salt, 32).toString('hex') };
}
function passwordOk(password, user) {
  const hash = crypto.scryptSync(password, user.salt, 32).toString('hex');
  const left = Buffer.from(hash);
  const right = Buffer.from(user.hash);
  return left.length === right.length && crypto.timingSafeEqual(left, right);
}
function account(id, name, email, password, role) {
  return { id, name, email, role, ...hashPassword(password) };
}
const users = [
  account(1, 'Мирзаханян Амазасп', 'admin@salon.local', 'Admin123!', 'admin'),
  account(2, 'Менеджер зала', 'manager@salon.local', 'Manager1!', 'manager'),
  account(3, 'Анна Павлова', 'reader@salon.local', 'Reader12!', 'reader'),
];
const refreshTokens = new Map();
const reservations = [
  { id: 1, userId: 3, carId: 2, model: 'Camry', holder: 'Анна Павлова', until: '2026-12-01', status: 'open' },
  { id: 2, userId: 3, carId: 16, model: 'Granta', holder: 'Анна Павлова', until: '2026-11-28', status: 'open' },
];
const requestLog = [];

const bodies = [
  { id: 1, name: 'Седан', description: 'Легковой трёхобъёмник' },
  { id: 2, name: 'Кроссовер', description: 'Повышенный клиренс' },
  { id: 3, name: 'Хэтчбек', description: 'Короткая корма' },
  { id: 4, name: 'Универсал', description: 'Удлинённый багажник' },
  { id: 5, name: 'Купе', description: 'Двухдверный кузов' },
  { id: 6, name: 'Кабриолет', description: 'Складная крыша' },
  { id: 7, name: 'Минивэн', description: 'Семейный салон' },
  { id: 8, name: 'Пикап', description: 'Открытый грузовой отсек' },
  { id: 9, name: 'Лифтбек', description: 'Пологая пятая дверь' },
  { id: 10, name: 'Фургон', description: 'Грузопассажирский кузов' },
  { id: 11, name: 'Родстер', description: 'Открытый двухместный' },
  { id: 12, name: 'Лимузин', description: 'Удлинённая база' },
];
const options = [
  { id: 1, name: 'Кожаный салон', description: 'Сиденья из кожи' },
  { id: 2, name: 'Навигация', description: 'Маршрут на экране' },
  { id: 3, name: 'Камера заднего вида', description: 'Обзор позади машины' },
  { id: 4, name: 'Подогрев сидений', description: 'Зимний пакет' },
  { id: 5, name: 'Панорамная крыша', description: 'Стеклянный верх' },
  { id: 6, name: 'Круиз-контроль', description: 'Удержание скорости' },
  { id: 7, name: 'Парктроник', description: 'Датчики препятствий' },
  { id: 8, name: 'Климат-контроль', description: 'Раздельный климат' },
  { id: 9, name: 'Светодиодные фары', description: 'LED-оптика' },
  { id: 10, name: 'Бесключевой доступ', description: 'Запуск кнопкой' },
  { id: 11, name: 'Подогрев руля', description: 'Обогрев обода' },
  { id: 12, name: 'Датчик дождя', description: 'Автоматические дворники' },
];
const brands = [
  brand(1, 'Toyota', 'Япония', 1937, [1, 2, 3, 5], [1, 2, 3]),
  brand(2, 'Volkswagen', 'Германия', 1937, [1, 3, 4], [2, 3, 4]),
  brand(3, 'BMW', 'Германия', 1916, [1, 2, 5], [1, 5, 6]),
  brand(4, 'Mercedes-Benz', 'Германия', 1926, [1, 2, 12], [1, 5, 8]),
  brand(5, 'Audi', 'Германия', 1909, [1, 2, 4], [2, 6, 9]),
  brand(6, 'Hyundai', 'Корея', 1967, [1, 2, 3], [2, 3, 7]),
  brand(7, 'Kia', 'Корея', 1944, [1, 2, 3], [2, 4, 7]),
  brand(8, 'Lada', 'Россия', 1966, [1, 3, 4], [3, 7]),
  brand(9, 'Ford', 'США', 1903, [1, 2, 8], [6, 7, 9]),
  brand(10, 'Honda', 'Япония', 1948, [1, 2, 3], [2, 3, 8]),
  brand(11, 'Renault', 'Франция', 1898, [1, 3, 7], [3, 4]),
  brand(12, 'Skoda', 'Чехия', 1895, [1, 4, 9], [2, 6, 8]),
  brand(13, 'Mazda', 'Япония', 1920, [1, 2, 5], [1, 2, 6]),
  brand(14, 'Nissan', 'Япония', 1933, [1, 2, 8], [2, 3, 7]),
  brand(15, 'Porsche', 'Германия', 1931, [5, 11], [1, 5, 10]),
  brand(16, 'Volvo', 'Швеция', 1927, [1, 2, 4], [6, 8, 9]),
  brand(17, 'Chevrolet', 'США', 1911, [1, 2, 8], [6, 7]),
  brand(18, 'Peugeot', 'Франция', 1896, [1, 3, 7], [2, 4, 8]),
  brand(19, 'Tesla', 'США', 2003, [1, 2], [2, 9, 10]),
  brand(20, 'Архивная марка', 'Россия', 1900, [1], [1], '2026-11-01T00:00:00.000Z'),
];
const cars = [
  car(1, 'Supra', 2020, 28000, 1, 5, 340, 4500000, 2, 3, [1]),
  car(2, 'Camry', 2019, 64000, 1, 1, 181, 2450000, 4, 6, [2]),
  car(3, 'Camry Hybrid', 2021, 31000, 1, 1, 218, 3200000, 3, 4, [2, 3]),
  car(4, 'Polo', 2018, 89000, 2, 3, 110, 1200000, 5, 6, [3]),
  car(5, 'Golf', 2016, 112000, 2, 3, 125, 980000, 2, 3, [2]),
  car(6, 'X5', 2024, 12000, 3, 2, 340, 8900000, 1, 2, [1, 6]),
  car(7, '3 Series', 2016, 98000, 3, 1, 184, 2100000, 3, 4, [5]),
  car(8, 'C-Class', 2017, 76000, 4, 1, 184, 2800000, 2, 3, [1]),
  car(9, 'GLE', 2021, 41000, 4, 2, 249, 6200000, 1, 2, [5, 8]),
  car(10, 'A4', 2015, 121000, 5, 1, 190, 1650000, 2, 4, [2]),
  car(11, 'Q5', 2019, 67000, 5, 2, 249, 3400000, 2, 3, [6]),
  car(12, 'Solaris', 2018, 91000, 6, 1, 123, 1100000, 6, 8, [2]),
  car(13, 'Tucson', 2020, 54000, 6, 2, 150, 1900000, 3, 4, [3]),
  car(14, 'Rio', 2017, 103000, 7, 1, 123, 950000, 4, 5, [4]),
  car(15, 'Sportage', 2022, 36000, 7, 2, 150, 2300000, 2, 3, [2]),
  car(16, 'Granta', 2019, 72000, 8, 1, 87, 750000, 7, 9, [3]),
  car(17, 'Vesta', 2023, 18000, 8, 1, 106, 1400000, 5, 6, [7]),
  car(18, 'Focus', 2014, 143000, 9, 1, 125, 700000, 0, 2, [7]),
  car(19, 'Explorer', 2020, 58000, 9, 2, 300, 3200000, 1, 2, [6]),
  car(20, 'Civic', 2016, 99000, 10, 1, 158, 1300000, 2, 3, [2]),
  car(21, 'CR-V', 2019, 61000, 10, 2, 190, 2400000, 2, 3, [3]),
  car(22, 'Logan', 2013, 168000, 11, 1, 82, 550000, 3, 4, [3]),
  car(23, 'Octavia', 2018, 84000, 12, 9, 150, 1600000, 2, 3, [2]),
  car(24, 'CX-5', 2021, 39000, 13, 2, 194, 2700000, 2, 3, [1, 6]),
  car(25, '2 Archive', 2010, 210000, 8, 1, 80, 250000, 0, 1, [3], '2026-11-01T00:00:00.000Z'),
];
const people = [
  ['Анна', 'Павлова', 'anna.pavlova@example.com', '+7 900 100-00-01'],
  ['Иван', 'Петров', 'ivan.petrov@example.com', '+7 900 100-00-02'],
  ['Мария', 'Соколова', 'maria.sokolova@example.com', '+7 900 100-00-03'],
  ['Пётр', 'Иванов', 'petr.ivanov@example.com', '+7 900 100-00-04'],
  ['Ольга', 'Кузнецова', 'olga.kuznetsova@example.com', '+7 900 100-00-05'],
  ['Сергей', 'Смирнов', 'sergey.smirnov@example.com', '+7 900 100-00-06'],
  ['Елена', 'Попова', 'elena.popova@example.com', '+7 900 100-00-07'],
  ['Никита', 'Волков', 'nikita.volkov@example.com', '+7 900 100-00-08'],
  ['Дарья', 'Морозова', 'darya.morozova@example.com', '+7 900 100-00-09'],
  ['Алексей', 'Новиков', 'alexey.novikov@example.com', '+7 900 100-00-10'],
  ['Ирина', 'Лебедева', 'irina.lebedeva@example.com', '+7 900 100-00-11'],
  ['Кирилл', 'Орлов', 'kirill.orlov@example.com', '+7 900 100-00-12'],
  ['Татьяна', 'Белова', 'tatiana.belova@example.com', '+7 900 100-00-13'],
];
const clients = people.map((row, index) => ({
  id: index + 1,
  firstName: row[0],
  lastName: row[1],
  email: row[2],
  phone: row[3],
  license: {
    number: `VU-${100001 + index}`,
    issuedOn: `2022-01-${String(index + 1).padStart(2, '0')}T00:00:00.000Z`,
    expiresOn: `2032-01-${String(index + 1).padStart(2, '0')}T00:00:00.000Z`,
  },
  deletedAt: null,
}));
clients.push({
  id: 14,
  firstName: 'Архив',
  lastName: 'Клиент',
  email: 'archive.client@example.com',
  phone: '+7 900 100-00-14',
  license: { number: 'VU-100014', issuedOn: null, expiresOn: null },
  deletedAt: '2026-11-01T00:00:00.000Z',
});

function brand(id, name, country, foundedYear, bodyTypeIds, optionIds, deletedAt = null) {
  return { id, name, country, foundedYear, bodyTypeIds, optionIds, deletedAt };
}
function car(id, model, year, mileage, brandId, bodyTypeId, horsepower, price, inStock, stockTotal, optionIds, deletedAt = null) {
  return {
    id,
    model,
    vin: `XTA${String(id).padStart(6, '0')}`,
    year,
    mileage,
    brandId,
    bodyTypeId,
    optionIds,
    horsepower,
    price,
    inStock,
    stockTotal,
    deletedAt,
  };
}

function nextId(rows) {
  return rows.reduce((max, row) => Math.max(max, row.id), 0) + 1;
}
function carsOf(brandId) {
  return cars.filter((item) => item.brandId === brandId).length;
}
function carsPhrase(count) {
  const mod10 = count % 10;
  const mod100 = count % 100;
  const word = mod10 === 1 && mod100 !== 11 ? 'автомобиль' : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14) ? 'автомобиля' : 'автомобилей';
  const verb = count === 1 ? 'ссылается' : 'ссылаются';
  return `на неё ${verb} ${count} ${word}`;
}
function vinKey(value) {
  return String(value || '').replace(/[^0-9a-z]/gi, '').toUpperCase();
}
function num(value) {
  if (value == null || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}
function flag(url, name) {
  const value = url.searchParams.get(name);
  return value === '1' || value === 'true';
}

function send(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
  });
  res.end(payload);
}
function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => {
      const raw = Buffer.concat(chunks).toString('utf8');
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(error);
      }
    });
  });
}
function page(rows, url, compare) {
  const params = url.searchParams;
  const pageNo = Math.max(1, Number(params.get('page') || 1));
  const rawSize = Number(params.get('size') || 10);
  // 100 нужен только кэшу справочников. Списки на экране просят 10, 25 или 50.
  const size = [10, 25, 50, 100].includes(rawSize) ? rawSize : 10;
  const sorted = rows.slice().sort(compare);
  const total = sorted.length;
  const start = (pageNo - 1) * size;
  return {
    items: sorted.slice(start, start + size).map(present),
    page: pageNo,
    size,
    total,
    totalPages: Math.max(1, Math.ceil(total / size) || 1),
  };
}
function compareBy(url, fields, fallback) {
  const raw = (url.searchParams.get('sort') || `${fallback},asc`).split(',');
  const field = fields.includes(raw[0]) ? raw[0] : fallback;
  const dir = raw[1] === 'desc' ? -1 : 1;
  return (left, right) => {
    const a = left[field];
    const b = right[field];
    const result = typeof a === 'number' && typeof b === 'number' ? a - b : String(a).toLowerCase().localeCompare(String(b), 'ru');
    return result * dir;
  };
}
function present(row) {
  if (row.vin) {
    return { ...row, brand: { id: row.brandId, name: brands.find((item) => item.id === row.brandId)?.name || '' } };
  }
  if (row.foundedYear) {
    return { ...row, cars: carsOf(row.id) };
  }
  if (row.description && !row.email) {
    const count = row.bodyTypeIds
      ? 0
      : cars.filter((item) => item.bodyTypeId === row.id || item.optionIds.includes(row.id)).length;
    const bodyCount = bodies.some((item) => item.id === row.id && item.name === row.name)
      ? cars.filter((item) => item.bodyTypeId === row.id).length
      : cars.filter((item) => item.optionIds.includes(row.id)).length;
    return { ...row, cars: bodyCount || count };
  }
  return row;
}

function listCars(url) {
  const params = url.searchParams;
  const search = (params.get('search') || '').trim().toLowerCase();
  const brandId = num(params.get('brandId'));
  const bodyTypeId = num(params.get('bodyTypeId'));
  const yearFrom = num(params.get('yearFrom'));
  const yearTo = num(params.get('yearTo'));
  const rows = cars.filter((item) => {
    if (!flag(url, 'includeDeleted') && item.deletedAt) return false;
    if (search && !item.model.toLowerCase().includes(search) && !item.vin.toLowerCase().includes(search)) return false;
    if (brandId != null && item.brandId !== brandId) return false;
    if (bodyTypeId != null && item.bodyTypeId !== bodyTypeId) return false;
    if (yearFrom != null && item.year < yearFrom) return false;
    if (yearTo != null && item.year > yearTo) return false;
    return true;
  });
  return page(rows, url, compareBy(url, ['model', 'year', 'mileage'], 'model'));
}
function listBrands(url) {
  const params = url.searchParams;
  const search = (params.get('search') || '').trim().toLowerCase();
  const country = params.get('country');
  const rows = brands.filter((item) => {
    if (!flag(url, 'includeDeleted') && item.deletedAt) return false;
    if (search && !item.name.toLowerCase().includes(search) && !item.country.toLowerCase().includes(search)) return false;
    if (country && item.country !== country) return false;
    return true;
  });
  return page(rows, url, compareBy(url, ['name', 'country', 'foundedYear'], 'name'));
}
function listNamed(url, rows, kind) {
  const search = (url.searchParams.get('search') || '').trim().toLowerCase();
  const filtered = rows.filter((item) => {
    if (!flag(url, 'includeDeleted') && item.deletedAt) return false;
    if (search && !item.name.toLowerCase().includes(search) && !item.description.toLowerCase().includes(search)) return false;
    return true;
  });
  const withCount = filtered.map((item) => ({
    ...item,
    cars: kind === 'body'
      ? cars.filter((car) => car.bodyTypeId === item.id).length
      : cars.filter((car) => car.optionIds.includes(item.id)).length,
  }));
  return page(withCount, url, compareBy(url, ['name', 'description', 'cars'], 'name'));
}
function listClients(url) {
  const search = (url.searchParams.get('search') || '').trim().toLowerCase();
  const rows = clients.filter((item) => {
    if (!flag(url, 'includeDeleted') && item.deletedAt) return false;
    if (search && !item.lastName.toLowerCase().includes(search) && !item.email.toLowerCase().includes(search)) return false;
    return true;
  }).map((item) => ({ ...item, licenseNumber: item.license.number }));
  return page(rows, url, compareBy(url, ['lastName', 'email', 'licenseNumber'], 'lastName'));
}

function validateCar(body, exceptId) {
  const errors = {};
  if (!String(body.model || '').trim()) errors.model = 'Заполните поле «Модель»';
  const vin = String(body.vin || '').trim();
  if (!/^[A-Za-z0-9]{6,17}$/.test(vin)) errors.vin = 'Укажите VIN из латинских букв и цифр';
  else if (cars.some((item) => item.id !== exceptId && vinKey(item.vin) === vinKey(vin))) {
    errors.vin = 'Такой VIN уже записан в каталоге';
  }
  const year = num(body.year);
  if (year == null || year < 1950 || year > 2026) errors.year = 'Год выпуска должен быть от 1950 до 2026';
  const mileage = num(body.mileage);
  if (mileage == null || mileage < 0) errors.mileage = 'Укажите пробег';
  const brandRow = brands.find((item) => item.id === num(body.brandId) && !item.deletedAt);
  if (!brandRow) errors.brandId = 'Выберите марку';
  const bodyId = num(body.bodyTypeId);
  if (brandRow && !brandRow.bodyTypeIds.includes(bodyId)) errors.bodyTypeId = 'Эта марка такой кузов не предлагает';
  const optionIds = Array.isArray(body.optionIds) ? body.optionIds.map(Number) : [];
  if (!optionIds.length) errors.optionIds = 'Выберите хотя бы одну опцию';
  else if (brandRow && optionIds.some((id) => !brandRow.optionIds.includes(id))) {
    errors.optionIds = 'Есть опция, которую марка не предлагает';
  }
  const stock = num(body.stockTotal);
  const free = num(body.inStock);
  if (stock == null || stock < 1) errors.stockTotal = 'Укажите число машин на складе';
  if (free == null || free < 0 || (stock != null && free > stock)) errors.inStock = 'Свободных машин не может быть больше, чем на складе';
  return errors;
}
function carFrom(body, id, deletedAt) {
  return {
    id,
    model: String(body.model).trim(),
    vin: String(body.vin).trim().toUpperCase(),
    year: num(body.year),
    mileage: num(body.mileage),
    brandId: num(body.brandId),
    bodyTypeId: num(body.bodyTypeId),
    optionIds: body.optionIds.map(Number),
    horsepower: num(body.horsepower),
    price: num(body.price),
    inStock: num(body.inStock),
    stockTotal: num(body.stockTotal),
    deletedAt,
  };
}
function validateClient(body, exceptId) {
  const errors = {};
  const email = String(body.email || '').trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) errors.email = 'Почта должна быть вида имя@домен.зона';
  else if (clients.some((item) => item.id !== exceptId && item.email.toLowerCase() === email)) {
    errors.email = 'Такая почта уже записана у другого клиента';
  }
  return errors;
}

function allowsRole(role, action) {
  const table = {
    reader: ['viewCatalog', 'extendOwn'],
    manager: ['viewCatalog', 'manageDesk', 'manageClients', 'editCatalog'],
    admin: ['viewCatalog', 'editCatalog', 'hardDelete', 'restoreRecords', 'manageUsers', 'viewStats'],
  };
  return (table[role] || []).includes(action);
}
function signToken(payload) {
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = crypto.createHmac('sha256', tokenSecret).update(body).digest('base64url');
  return `${body}.${sig}`;
}
function readToken(token) {
  const parts = String(token).split('.');
  if (parts.length !== 2) return null;
  const [body, sig] = parts;
  const expected = crypto.createHmac('sha256', tokenSecret).update(body).digest('base64url');
  const left = Buffer.from(sig);
  const right = Buffer.from(expected);
  if (left.length !== right.length || !crypto.timingSafeEqual(left, right)) return null;
  try {
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (!payload.exp || Date.now() > payload.exp) return null;
    return payload;
  } catch (_) {
    return null;
  }
}
function publicUser(user) {
  return { id: user.id, name: user.name, email: user.email, role: user.role };
}
function issue(user) {
  const accessToken = signToken({
    sub: user.id,
    role: user.role,
    exp: Date.now() + ttlSeconds * 1000,
    typ: 'access',
  });
  const refreshToken = crypto.randomBytes(24).toString('hex');
  refreshTokens.set(refreshToken, { userId: user.id, exp: Date.now() + 7 * 24 * 60 * 60 * 1000 });
  return { accessToken, refreshToken, user: publicUser(user) };
}
function userOf(req) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const payload = readToken(token);
  if (!payload) return null;
  const user = users.find((item) => item.id === payload.sub);
  if (!user) return null;
  return { ...user, role: payload.role };
}
function guard(req, res, action) {
  const user = userOf(req);
  if (!user) {
    send(res, 401, { message: 'Требуется вход в систему.' });
    return null;
  }
  if (action && !allowsRole(user.role, action)) {
    send(res, 403, { message: 'Недостаточно прав для этого действия.' });
    return null;
  }
  return user;
}
function passwordProblem(password) {
  const value = String(password || '');
  if (value.length < 8) return 'Пароль должен быть не короче 8 символов';
  if (!/\d/.test(value)) return 'Добавьте хотя бы одну цифру';
  if (!/[^A-Za-zА-Яа-яЁё0-9]/.test(value)) return 'Добавьте специальный символ';
  return null;
}
function parseDays(value) {
  const days = Number(value);
  if (!Number.isInteger(days) || days < 1 || days > 365) return null;
  return days;
}
function shiftDate(until, days) {
  const today = new Date();
  const todayKey = today.getFullYear() * 10000 + (today.getMonth() + 1) * 100 + today.getDate();
  let year = today.getFullYear();
  let month = today.getMonth() + 1;
  let day = today.getDate();
  if (typeof until === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(until)) {
    year = Number(until.slice(0, 4));
    month = Number(until.slice(5, 7));
    day = Number(until.slice(8, 10));
  }
  const key = year * 10000 + month * 100 + day;
  const start = key < todayKey ? new Date(today.getFullYear(), today.getMonth(), today.getDate()) : new Date(year, month - 1, day);
  start.setDate(start.getDate() + days);
  return `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}-${String(start.getDate()).padStart(2, '0')}`;
}
function nextReservationId() {
  return reservations.reduce((max, item) => Math.max(max, item.id), 0) + 1;
}
async function bookReservation(req, res, id) {
  const user = userOf(req);
  if (!user) {
    send(res, 401, { message: 'Требуется вход в систему.' });
    return 401;
  }
  const reader = allowsRole(user.role, 'extendOwn');
  const manager = allowsRole(user.role, 'manageDesk');
  const body = await readBody(req);
  const car = cars.find((item) => item.id === id && !item.deletedAt);
  if (!car) {
    send(res, 404, { message: 'Запись не найдена.' });
    return 404;
  }
  if (!reader && !manager) {
    if (car.inStock <= 0) {
      send(res, 409, { message: `Нельзя зарезервировать «${car.model}»: свободных автомобилей нет.` });
      return 409;
    }
    car.inStock -= 1;
    send(res, 200, present(car));
    return 200;
  }
  const days = parseDays(body.days) || (body.days == null ? 7 : null);
  if (!days) {
    send(res, 422, { message: 'Ошибка валидации', errors: { days: 'Укажите число дней от 1 до 365' } });
    return 422;
  }
  let holder = user.name;
  let ownerId = user.id;
  let clientId = null;
  if (manager) {
    const client = clients.find((item) => item.id === Number(body.clientId) && !item.deletedAt);
    if (!client) {
      send(res, 422, { message: 'Ошибка валидации', errors: { clientId: 'Выберите клиента' } });
      return 422;
    }
    holder = `${client.firstName} ${client.lastName}`.trim();
    ownerId = null;
    clientId = client.id;
  }
  const existing = reservations.find((item) => {
    if (item.status !== 'open' || item.carId !== car.id) return false;
    return clientId != null ? item.clientId === clientId : item.userId === ownerId;
  });
  if (existing) {
    existing.until = shiftDate(existing.until, days);
    send(res, 200, { ...present(car), reservation: existing });
    return 200;
  }
  if (car.inStock <= 0) {
    send(res, 409, { message: `Нельзя зарезервировать «${car.model}»: свободных автомобилей нет.` });
    return 409;
  }
  car.inStock -= 1;
  const row = {
    id: nextReservationId(),
    userId: ownerId,
    clientId,
    carId: car.id,
    model: car.model,
    holder,
    until: shiftDate(null, days),
    status: 'open',
  };
  reservations.push(row);
  send(res, 201, { ...present(car), reservation: row });
  return 201;
}
function hide(rows, id) {
  const row = rows.find((item) => item.id === id);
  if (!row) return false;
  row.deletedAt = new Date().toISOString();
  return true;
}
function bulk(rows, ids) {
  let deleted = 0;
  for (const id of new Set(ids.map(Number))) {
    const row = rows.find((item) => item.id === id && !item.deletedAt);
    if (!row) continue;
    row.deletedAt = new Date().toISOString();
    deleted += 1;
  }
  return deleted;
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${port}`);
  const origin = req.headers.origin;
  if (origin && isAllowedOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Private-Network', 'true');
  }
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const fail = Number(url.searchParams.get('__fail') || 0);
  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) {
    await new Promise((resolve) => setTimeout(resolve, Math.min(delay, 60000)));
  }
  if (fail >= 400) {
    send(res, fail, { message: fail >= 500 ? 'Ошибка на сервере. Попробуйте позже.' : 'Запрос отклонён.' });
    requestLog.push({ method: req.method, path: url.pathname + url.search, status: fail });
    return;
  }

  try {
    const status = await route(req, res, url);
    requestLog.push({ method: req.method, path: url.pathname + url.search, status });
    if (requestLog.length > 40) requestLog.shift();
  } catch (error) {
    send(res, 500, { message: 'Ошибка на сервере. Попробуйте позже.' });
    requestLog.push({ method: req.method, path: url.pathname, status: 500 });
  }
});

async function route(req, res, url) {
  const path = url.pathname.replace(/\/+$/, '') || '/';
  if (req.method === 'GET' && path === '/api/__health') {
    send(res, 200, { ok: true });
    return 200;
  }
  if (req.method === 'GET' && path === '/api/__requests') {
    send(res, 200, requestLog.slice(-15));
    return 200;
  }
  if (req.method === 'POST' && path === '/api/auth/register') {
    const body = await readBody(req);
    const email = String(body.email || '').trim().toLowerCase();
    const problem = passwordProblem(body.password);
    const errors = {};
    if (!String(body.name || '').trim()) errors.name = 'Введите имя';
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) errors.email = 'Укажите почту';
    else if (users.some((item) => item.email === email)) errors.email = 'Такая почта уже зарегистрирована';
    if (problem) errors.password = problem;
    if (Object.keys(errors).length) {
      send(res, 422, { message: 'Ошибка валидации', errors });
      return 422;
    }
    const user = account(users.reduce((max, item) => Math.max(max, item.id), 0) + 1, String(body.name).trim(), email, body.password, 'reader');
    users.push(user);
    send(res, 201, issue(user));
    return 201;
  }
  if (req.method === 'POST' && path === '/api/auth/login') {
    const body = await readBody(req);
    const user = users.find((item) => item.email === String(body.email || '').trim().toLowerCase());
    if (!user || !passwordOk(String(body.password || ''), user)) {
      send(res, 401, { message: 'Неверная почта или пароль.' });
      return 401;
    }
    send(res, 200, issue(user));
    return 200;
  }
  if (req.method === 'POST' && path === '/api/auth/refresh') {
    const body = await readBody(req);
    const saved = refreshTokens.get(body.refreshToken);
    refreshTokens.delete(body.refreshToken);
    if (!saved || saved.exp < Date.now()) {
      send(res, 401, { message: 'Сессия истекла. Войдите снова.' });
      return 401;
    }
    const user = users.find((item) => item.id === saved.userId);
    if (!user) {
      send(res, 401, { message: 'Сессия истекла. Войдите снова.' });
      return 401;
    }
    send(res, 200, issue(user));
    return 200;
  }
  if (req.method === 'POST' && path === '/api/auth/logout') {
    const body = await readBody(req);
    refreshTokens.delete(body.refreshToken);
    send(res, 200, { ok: true });
    return 200;
  }
  if (req.method === 'GET' && path === '/api/auth/me') {
    const user = guard(req, res, null);
    if (!user) return res.statusCode;
    send(res, 200, publicUser(users.find((item) => item.id === user.id) || user));
    return 200;
  }
  if (req.method === 'GET' && path === '/api/my-reservations') {
    const user = guard(req, res, 'extendOwn');
    if (!user) return res.statusCode;
    send(res, 200, { items: reservations.filter((item) => item.userId === user.id && item.status === 'open') });
    return 200;
  }
  const myExtend = path.match(/^\/api\/my-reservations\/(\d+)\/extend$/);
  if (myExtend && req.method === 'POST') {
    const user = guard(req, res, 'extendOwn');
    if (!user) return res.statusCode;
    const body = await readBody(req);
    const days = parseDays(body.days);
    if (!days) {
      send(res, 422, { message: 'Ошибка валидации', errors: { days: 'Укажите число дней от 1 до 365' } });
      return 422;
    }
    const row = reservations.find((item) => item.id === Number(myExtend[1]) && item.userId === user.id && item.status === 'open');
    if (!row) {
      send(res, 404, { message: 'Бронь не найдена.' });
      return 404;
    }
    row.until = shiftDate(row.until, days);
    send(res, 200, row);
    return 200;
  }
  if (req.method === 'GET' && path === '/api/desk/reservations') {
    if (!guard(req, res, 'manageDesk')) return res.statusCode;
    send(res, 200, { items: reservations });
    return 200;
  }
  if (req.method === 'POST' && path === '/api/desk/reservations') {
    const user = guard(req, res, 'manageDesk');
    if (!user) return res.statusCode;
    const body = await readBody(req);
    const car = cars.find((item) => item.id === Number(body.carId));
    const row = {
      id: reservations.reduce((max, item) => Math.max(max, item.id), 0) + 1,
      userId: user.id,
      carId: car ? car.id : 0,
      model: car ? car.model : 'Автомобиль',
      holder: user.name,
      until: '2026-12-20',
      status: 'open',
    };
    reservations.push(row);
    send(res, 201, row);
    return 201;
  }
  const deskExtend = path.match(/^\/api\/desk\/reservations\/(\d+)\/extend$/);
  if (deskExtend && req.method === 'POST') {
    if (!guard(req, res, 'manageDesk')) return res.statusCode;
    const body = await readBody(req);
    const days = parseDays(body.days);
    if (!days) {
      send(res, 422, { message: 'Ошибка валидации', errors: { days: 'Укажите число дней от 1 до 365' } });
      return 422;
    }
    const row = reservations.find((item) => item.id === Number(deskExtend[1]) && item.status === 'open');
    if (!row) {
      send(res, 404, { message: 'Бронь не найдена.' });
      return 404;
    }
    row.until = shiftDate(row.until, days);
    send(res, 200, row);
    return 200;
  }
  const closeMatch = path.match(/^\/api\/desk\/reservations\/(\d+)\/close$/);
  if (closeMatch && req.method === 'POST') {
    if (!guard(req, res, 'manageDesk')) return res.statusCode;
    const row = reservations.find((item) => item.id === Number(closeMatch[1]));
    if (!row) {
      send(res, 404, { message: 'Бронь не найдена.' });
      return 404;
    }
    row.status = 'closed';
    send(res, 200, row);
    return 200;
  }
  if (req.method === 'GET' && path === '/api/users') {
    if (!guard(req, res, 'manageUsers')) return res.statusCode;
    send(res, 200, { items: users.map(publicUser) });
    return 200;
  }
  if (req.method === 'GET' && path === '/api/stats') {
    if (!guard(req, res, 'viewStats')) return res.statusCode;
    send(res, 200, {
      cars: cars.filter((item) => !item.deletedAt).length,
      brands: brands.filter((item) => !item.deletedAt).length,
      clients: clients.filter((item) => !item.deletedAt).length,
      users: users.length,
      reservations: reservations.filter((item) => item.status === 'open').length,
    });
    return 200;
  }

  const match = path.match(/^\/api\/(cars|brands|body-types|options|clients)(?:\/([^/]+))?(?:\/(restore|reserve))?$/);
  if (!match) {
    send(res, 404, { message: 'Запись не найдена.' });
    return 404;
  }
  const [, collection, rawId, action] = match;
  const table = { cars, brands, 'body-types': bodies, options, clients }[collection];
  const id = rawId && rawId !== 'bulk-delete' ? Number(rawId) : null;
  const write = req.method !== 'GET';

  if (collection === 'cars' && rawId === 'bulk-delete' && req.method === 'POST') {
    if (!guard(req, res, 'editCatalog')) return res.statusCode;
    const body = await readBody(req);
    const deleted = bulk(cars, Array.isArray(body.ids) ? body.ids : []);
    send(res, 200, { deleted });
    return 200;
  }
  if (rawId === 'bulk-delete' && req.method === 'POST') {
    if (!guard(req, res, collection === 'clients' ? 'manageClients' : 'editCatalog')) return res.statusCode;
    const body = await readBody(req);
    const ids = Array.isArray(body.ids) ? body.ids.map(Number) : [];
    if (collection === 'brands') {
      const free = ids.filter((item) => carsOf(item) === 0);
      send(res, 200, { deleted: bulk(brands, free) });
      return 200;
    }
    send(res, 200, { deleted: bulk(table, ids) });
    return 200;
  }

  if (req.method === 'POST' && action === 'reserve') {
    return bookReservation(req, res, id);
  }

  const hardNow = req.method === 'DELETE' && flag(url, 'hard');
  const needed = collection === 'clients'
    ? 'manageClients'
    : action === 'restore'
      ? 'restoreRecords'
      : hardNow
        ? 'hardDelete'
        : req.method === 'GET'
          ? 'viewCatalog'
          : 'editCatalog';
  if (!guard(req, res, needed)) {
    return res.statusCode;
  }

  if (req.method === 'GET' && id == null) {
    const payload = collection === 'cars' ? listCars(url)
      : collection === 'brands' ? listBrands(url)
      : collection === 'clients' ? listClients(url)
      : listNamed(url, table, collection === 'body-types' ? 'body' : 'option');
    send(res, 200, payload);
    return 200;
  }
  if (req.method === 'GET' && id != null) {
    const row = table.find((item) => item.id === id);
    if (!row) {
      send(res, 404, { message: 'Запись не найдена.' });
      return 404;
    }
    send(res, 200, present(row));
    return 200;
  }
  if (req.method === 'POST' && action === 'restore') {
    const row = table.find((item) => item.id === id);
    if (!row) {
      send(res, 404, { message: 'Запись не найдена.' });
      return 404;
    }
    row.deletedAt = null;
    send(res, 200, present(row));
    return 200;
  }
  if (req.method === 'POST' && id == null) {
    const body = await readBody(req);
    if (collection === 'cars') {
      const errors = validateCar(body);
      if (Object.keys(errors).length) {
        send(res, 422, { message: 'Ошибка валидации', errors });
        return 422;
      }
      const row = carFrom(body, nextId(cars), null);
      cars.push(row);
      send(res, 201, present(row));
      return 201;
    }
    if (collection === 'clients') {
      const errors = validateClient(body);
      if (Object.keys(errors).length) {
        send(res, 422, { message: 'Ошибка валидации', errors });
        return 422;
      }
      const row = {
        id: nextId(clients),
        firstName: String(body.firstName || '').trim(),
        lastName: String(body.lastName || '').trim(),
        email: String(body.email || '').trim(),
        phone: String(body.phone || '').trim(),
        license: body.license || { number: '', issuedOn: null, expiresOn: null },
        deletedAt: null,
      };
      clients.push(row);
      send(res, 201, row);
      return 201;
    }
    const row = { ...body, id: nextId(table), deletedAt: null };
    table.push(row);
    send(res, 201, present(row));
    return 201;
  }
  if (req.method === 'PUT' && id != null) {
    const body = await readBody(req);
    const index = table.findIndex((item) => item.id === id);
    if (index === -1) {
      send(res, 404, { message: 'Запись не найдена.' });
      return 404;
    }
    if (collection === 'cars') {
      const errors = validateCar(body, id);
      if (Object.keys(errors).length) {
        send(res, 422, { message: 'Ошибка валидации', errors });
        return 422;
      }
      cars[index] = carFrom(body, id, cars[index].deletedAt);
      send(res, 200, present(cars[index]));
      return 200;
    }
    if (collection === 'clients') {
      const errors = validateClient(body, id);
      if (Object.keys(errors).length) {
        send(res, 422, { message: 'Ошибка валидации', errors });
        return 422;
      }
      clients[index] = { ...clients[index], ...body, id, license: body.license || clients[index].license };
      send(res, 200, clients[index]);
      return 200;
    }
    table[index] = { ...table[index], ...body, id };
    send(res, 200, present(table[index]));
    return 200;
  }
  if (req.method === 'DELETE' && id != null) {
    const hard = flag(url, 'hard');
    if (hard && !guard(req, res, 'hardDelete')) return res.statusCode;
    if (collection === 'brands' && carsOf(id) > 0) {
      const name = brands.find((item) => item.id === id)?.name || '';
      send(res, 409, { message: `Нельзя удалить марку «${name}»: ${carsPhrase(carsOf(id))}.` });
      return 409;
    }
    if (hard) {
      const index = table.findIndex((item) => item.id === id);
      if (index === -1) {
        send(res, 404, { message: 'Запись не найдена.' });
        return 404;
      }
      table.splice(index, 1);
      send(res, 200, { deleted: true });
      return 200;
    }
    if (!hide(table, id)) {
      send(res, 404, { message: 'Запись не найдена.' });
      return 404;
    }
    send(res, 200, { deleted: true });
    return 200;
  }
  send(res, 404, { message: 'Запись не найдена.' });
  return 404;
}

server.listen(port, () => {
  console.log(`salon api http://127.0.0.1:${port}/api/__health`);
  console.log(`cors origin ${[...allowedOrigins].join(', ')}`);
});
