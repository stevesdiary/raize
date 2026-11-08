import { migrate } from 'drizzle-orm/postgres-js/migrator';
import { db, client } from './index.js';

async function runMigrations() {
  console.log('Running database migrations...');
  try {
    await client`ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50) UNIQUE;`;
    await migrate(db, { migrationsFolder: './drizzle' });
    console.log('Migrations applied successfully!');
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigrations();

