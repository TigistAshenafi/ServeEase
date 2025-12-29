import bcrypt from 'bcrypt';

const plainPassword = 'admin@123';
const saltRounds = 10;

const hash = await bcrypt.hash(plainPassword, saltRounds);

console.log('Bcrypt hash:', hash);
