import * as dotenv from 'dotenv';

dotenv.config();

export const env = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT || '3000', 10),
  HOST: process.env.HOST || '0.0.0.0',
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
  DATABASE_URL: process.env.DATABASE_URL || 'postgresql://postgres:dev_wRShFUkaxicemLWVTrt1@localhost:5432/raize_fitness',
  REDIS_URL: process.env.REDIS_URL || 'redis://localhost:6379',
  JWT_SECRET: process.env.JWT_SECRET || 'super_secret_jwt_passphrase_for_fitness_platform_2026_min_32_chars!',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '15m',
  REFRESH_TOKEN_EXPIRES_IN: process.env.REFRESH_TOKEN_EXPIRES_IN || '30d',
  ENCRYPTION_KEY: process.env.ENCRYPTION_KEY || '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  PAYSTACK_SECRET_KEY: process.env.PAYSTACK_SECRET_KEY || 'sk_test_mock_paystack_secret_key',
  PAYSTACK_PUBLIC_KEY: process.env.PAYSTACK_PUBLIC_KEY || 'pk_test_mock_paystack_public_key',
  REVENUECAT_API_KEY: process.env.REVENUECAT_API_KEY || 'mock_revenuecat_api_key',
  SENDBYTE_API_KEY: process.env.SENDBYTE_API_KEY || 'sk_test_mock_sendbyte_api_key',
  SENDBYTE_FROM_EMAIL: process.env.SENDBYTE_FROM_EMAIL || 'Raize Fitness <noreply@raize.fit>',
  R2_ACCOUNT_ID: process.env.R2_ACCOUNT_ID || 'mock_account_id',
  R2_ACCESS_KEY_ID: process.env.R2_ACCESS_KEY_ID || 'mock_access_key',
  R2_SECRET_ACCESS_KEY: process.env.R2_SECRET_ACCESS_KEY || 'mock_secret_key',
  R2_BUCKET_NAME: process.env.R2_BUCKET_NAME || 'raize-media',
  R2_PUBLIC_URL: process.env.R2_PUBLIC_URL || 'https://media.raize.fit',
};
