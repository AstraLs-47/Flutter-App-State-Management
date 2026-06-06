const request = require('supertest');
const app = require('../src/server');
const db = require('../src/config/db');

jest.mock('../src/config/db', () => {
  return {
    query: jest.fn(),
    on: jest.fn(),
  };
});

jest.mock('../src/middleware/auth', () => {
  return {
    auth: (req, res, next) => {
      req.user = { id: 'admin-1', role: 'admin' };
      next();
    },
    authorize: (...roles) => (req, res, next) => next(),
  };
});

describe('Exercises Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET /api/exercises - success', async () => {
    db.query
      .mockResolvedValueOnce({
        rows: [
          { id: '1', name: 'Pushup', description: 'Chest exercise', image_url: 'pushup.png', category_name: 'Chest' }
        ]
      })
      .mockResolvedValueOnce({
        rows: [
          { total: '1' }
        ]
      });

    const res = await request(app).get('/api/exercises');

    expect(res.statusCode).toBe(200);
    expect(res.body.length).toBe(1);
    expect(res.body[0].title).toBe('Pushup');
  });

  test('POST /api/exercises - success', async () => {
    db.query.mockResolvedValueOnce({
      rows: [
        { id: '1', name: 'Squat', description: 'Leg exercise', image_url: 'squat.png', category_name: 'Legs' }
      ]
    });

    const res = await request(app)
      .post('/api/exercises')
      .send({
        title: 'Squat',
        description: 'Leg exercise',
        category: 'Legs',
        image: 'squat.png'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.title).toBe('Squat');
  });
});
