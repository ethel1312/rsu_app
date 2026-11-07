import { createServer } from 'node:http';
import handler from './api/index.mjs';
createServer(handler).listen(Number(process.env.PORT || 8080), '127.0.0.1', () => console.log('API local en http://127.0.0.1:8080/api'));
